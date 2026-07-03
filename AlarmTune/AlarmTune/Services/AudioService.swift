import Foundation
import AVFoundation
import UIKit

class AudioService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?
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

        // F2-2 修复：闹钟播放前提升系统音量到 1.0，让 AVAudioPlayer.volume 真正独立控制
        VolumeManager.shared.boostSystemVolume(forAlarmVolume: volume)

        guard configureAudioSession() else {
            VolumeManager.shared.restoreSystemVolume()
            endBackgroundTask()
            return
        }

        guard let soundURL = urlForSound(soundName) else {
            print("Sound file not found: \(soundName)")
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

    func stopAlarm() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil

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
            fadeTimer?.invalidate()
            fadeTimer = nil
            isPreviewMode = false
        } else if isPlaying {
            // An alarm is playing — don't interrupt it, skip preview
            return
        }

        guard configureAudioSession() else { return }

        guard let soundURL = urlForSound(soundName) else { return }

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

    private func urlForSound(_ name: String) -> URL? {
        let sanitizedName = name.replacingOccurrences(of: " ", with: "")
        let extensions = ["caf", "mp3", "aiff", "wav", "m4a"]
        let directories: [String?] = ["Sounds", nil]
        
        for dir in directories {
            for candidate in [sanitizedName, name] {
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
