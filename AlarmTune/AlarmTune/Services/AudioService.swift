import Foundation
import AVFoundation
import UIKit
import MediaPlayer

class AudioService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?
    private var musicPlayer: MPMusicPlayerController?
    private var fadeTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var isPreviewMode: Bool = false

    @Published var isPlaying: Bool = false
    @Published var currentVolume: Float = 0.0

    private override init() {
        super.init()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
    }

    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    audioPlayer?.play()
                    DispatchQueue.main.async {
                        self.isPlaying = true
                    }
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleMediaServicesReset(_ notification: Notification) {
        configureAudioSession()
        if isPlaying {
            audioPlayer?.play()
        }
    }

    @discardableResult
    func configureAudioSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            return true
        } catch {
            print("Audio session configuration failed: \(error.localizedDescription)")
            return false
        }
    }

    private func beginBackgroundTask() {
        endBackgroundTask()
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "AlarmPlayback") { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    func playAlarm(soundName: String, volume: Float, fadeIn: Bool = false, fadeInDuration: Double = 5.0) {
        stopAlarm()
        beginBackgroundTask()

        let source = AppConstants.Sound.source(for: soundName)

        // 根据来源选择系统音量策略：
        // - AVAudioPlayer（内置/导入）：系统音量提升到 1.0，由 audioPlayer.volume 独立控制
        // - MPMusicPlayerController（Apple Music）：iOS 不支持 player.volume，直接将系统音量设为闹钟音量
        if source == .appleMusic {
            VolumeManager.shared.boostSystemVolume(to: volume)
        } else {
            VolumeManager.shared.boostSystemVolume(forAlarmVolume: volume)
        }

        guard configureAudioSession() else {
            VolumeManager.shared.restoreSystemVolume()
            endBackgroundTask()
            return
        }

        switch source {
        case .builtIn, .imported:
            playLocalSound(name: soundName, volume: volume, fadeIn: fadeIn, fadeInDuration: fadeInDuration)
        case .appleMusic:
            playAppleMusicSound(identifier: soundName, volume: volume, fadeIn: fadeIn, fadeInDuration: fadeInDuration)
        }
    }

    /// 播放本地文件（内置 + 导入），复用现有 AVAudioPlayer 逻辑
    private func playLocalSound(name: String, volume: Float, fadeIn: Bool, fadeInDuration: Double) {
        guard let soundURL = urlForSound(name) else {
            print("Sound file not found: \(name)")
            VolumeManager.shared.restoreSystemVolume()
            endBackgroundTask()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.delegate = self
            isPreviewMode = false
            let prepared = audioPlayer?.prepareToPlay() ?? false
            if !prepared {
                print("Failed to prepare audio player")
            }

            if fadeIn {
                // F2-4 修复：Fade-In 起始音量不低于安全下限，避免前几秒完全无声
                let safeStartVolume = max(AppConstants.Volume.fadeInMinStartVolume, volume * 0.1)
                audioPlayer?.volume = safeStartVolume
                let started = audioPlayer?.play() ?? false
                if started {
                    startFadeIn(targetVolume: volume, duration: fadeInDuration, startVolume: safeStartVolume)
                }
            } else {
                audioPlayer?.volume = volume
                let started = audioPlayer?.play() ?? false
                if !started {
                    print("Audio player failed to start playback")
                }
            }

            DispatchQueue.main.async {
                self.isPlaying = true
                self.currentVolume = volume
            }
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
            VolumeManager.shared.restoreSystemVolume()
            endBackgroundTask()
        }
    }

    /// 播放 Apple Music 歌曲（通过 persistentID 从音乐库查询）
    /// 注意：iOS 不支持设置 MPMusicPlayerController.volume，音量已通过 VolumeManager.boostSystemVolume(to:) 设置
    /// fade-in 对 Apple Music 暂不支持（受系统音量 API 限制）
    private func playAppleMusicSound(identifier: String, volume: Float, fadeIn: Bool, fadeInDuration: Double) {
        guard identifier.hasPrefix("appleMusic:"),
              let persistentIDStr = identifier.split(separator: ":").last,
              let persistentID = UInt64(persistentIDStr) else {
            print("Invalid Apple Music identifier: \(identifier), fallback to default")
            playLocalSound(name: AppConstants.Sound.defaultSound, volume: volume, fadeIn: fadeIn, fadeInDuration: fadeInDuration)
            return
        }

        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: NSNumber(value: persistentID),
            forProperty: MPMediaItemPropertyPersistentID
        ))
        guard let items = query.items, !items.isEmpty else {
            print("Apple Music song not found in library, fallback to default")
            playLocalSound(name: AppConstants.Sound.defaultSound, volume: volume, fadeIn: fadeIn, fadeInDuration: fadeInDuration)
            return
        }

        let collection = MPMediaItemCollection(items: items)
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.setQueue(with: collection)
        musicPlayer = player
        isPreviewMode = false

        // iOS 限制：MPMusicPlayerController.volume 不可用，音量由系统音量控制
        // 系统音量已在 playAlarm 中通过 VolumeManager.boostSystemVolume(to: volume) 设置
        // fade-in 对 Apple Music 暂不支持
        player.play()

        DispatchQueue.main.async {
            self.isPlaying = true
            self.currentVolume = volume
        }
    }

    func stopAlarm() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        musicPlayer?.stop()
        musicPlayer = nil

        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentVolume = 0
        }

        deactivateAudioSession()
        endBackgroundTask()

        // F2-2 修复：闹钟停止后恢复原始系统音量
        // 注意：必须在 deactivateAudioSession 和 endBackgroundTask 之后调用，
        // 确保音频会话已释放再恢复音量
        VolumeManager.shared.restoreSystemVolume()
    }

    func fadeOutAndStop(duration: Double = 2.0) {
        guard let player = audioPlayer, player.isPlaying else {
            stopAlarm()
            return
        }

        fadeTimer?.invalidate()

        let steps = 20
        let interval = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)
        var currentStep = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            currentStep += 1
            let newVolume = max(0, player.volume - volumeStep)
            player.volume = newVolume

            if currentStep >= steps || newVolume <= 0 {
                timer.invalidate()
                self?.stopAlarm()
            }
        }
    }

    func previewSound(soundName: String, volume: Float) {
        // Only stop if currently in preview mode — never interrupt an active alarm
        if isPreviewMode {
            audioPlayer?.stop()
            audioPlayer = nil
            musicPlayer?.stop()
            musicPlayer = nil
            fadeTimer?.invalidate()
            fadeTimer = nil
            isPreviewMode = false
        } else if isPlaying {
            // An alarm is playing — don't interrupt it, skip preview
            return
        }

        guard configureAudioSession() else { return }

        let source = AppConstants.Sound.source(for: soundName)
        switch source {
        case .builtIn, .imported:
            previewLocalSound(name: soundName, volume: volume)
        case .appleMusic:
            previewAppleMusicSound(identifier: soundName, volume: volume)
        }
    }

    private func previewLocalSound(name: String, volume: Float) {
        guard let soundURL = urlForSound(name) else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = 0
            audioPlayer?.volume = volume
            audioPlayer?.delegate = self
            isPreviewMode = true
            audioPlayer?.play()

            DispatchQueue.main.async {
                self.isPlaying = true
                self.currentVolume = volume
            }
        } catch {
            print("Preview playback failed: \(error.localizedDescription)")
        }
    }

    private func previewAppleMusicSound(identifier: String, volume: Float) {
        guard identifier.hasPrefix("appleMusic:"),
              let persistentIDStr = identifier.split(separator: ":").last,
              let persistentID = UInt64(persistentIDStr) else { return }

        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: NSNumber(value: persistentID),
            forProperty: MPMediaItemPropertyPersistentID
        ))
        guard let items = query.items, !items.isEmpty else { return }

        let collection = MPMediaItemCollection(items: items)
        let player = MPMusicPlayerController.applicationQueuePlayer
        player.setQueue(with: collection)
        musicPlayer = player
        isPreviewMode = true
        // iOS 限制：MPMusicPlayerController.volume 不可用，预览使用当前系统音量
        player.play()

        DispatchQueue.main.async {
            self.isPlaying = true
            self.currentVolume = volume
        }
    }

    private func startFadeIn(targetVolume: Float, duration: Double, startVolume: Float = 0) {
        let steps = 30
        let interval = duration / Double(steps)
        let volumeRange = targetVolume - startVolume
        let volumeStep = volumeRange / Float(steps)
        var currentStep = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let player = self?.audioPlayer else {
                timer.invalidate()
                return
            }

            currentStep += 1
            let newVolume = min(targetVolume, startVolume + volumeStep * Float(currentStep))
            player.volume = newVolume

            DispatchQueue.main.async {
                self?.currentVolume = newVolume
            }

            if currentStep >= steps {
                timer.invalidate()
                player.volume = targetVolume
                DispatchQueue.main.async {
                    self?.currentVolume = targetVolume
                }
            }
        }
    }

    /// 查找铃声文件
    /// - 内置铃声：Bundle/Sounds/{SanitizedName}.{ext}
    /// - 导入铃声：Documents/ImportedSounds/{SanitizedName}.{ext}
    /// - 注意：soundName 可能带前缀（"imported:xxx"），需先剥离前缀再查找
    func urlForSound(_ name: String) -> URL? {
        // 剥离来源前缀（M5/M4 新增的 "imported:" 前缀）
        let lookupName: String
        if name.hasPrefix("imported:") {
            lookupName = String(name.dropFirst("imported:".count))
        } else if name.hasPrefix("appleMusic:") {
            // Apple Music 铃声不通过文件查找，由 playAppleMusicSound 单独处理
            return nil
        } else {
            lookupName = name
        }

        let sanitizedName = lookupName.replacingOccurrences(of: " ", with: "")
        let extensions = ["caf", "mp3", "aiff", "wav", "m4a"]
        let directories: [String?] = ["Sounds", nil]

        for dir in directories {
            for candidate in [sanitizedName, lookupName] {
                for ext in extensions {
                    if let url = Bundle.main.url(forResource: candidate, withExtension: ext, subdirectory: dir) {
                        return url
                    }
                }
            }
        }

        if let importedDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let customSoundsDir = importedDir.appendingPathComponent("ImportedSounds", isDirectory: true)
            for ext in extensions {
                let url = customSoundsDir.appendingPathComponent("\(sanitizedName).\(ext)")
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
        }

        return nil
    }

    private func deactivateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session deactivation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard isPreviewMode else { return }
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentVolume = 0
        }
        isPreviewMode = false
        audioPlayer = nil
        deactivateAudioSession()
    }
}
