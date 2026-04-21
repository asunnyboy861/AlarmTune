import Foundation
import AVFoundation
import UIKit

class AudioService: ObservableObject {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    @Published var isPlaying: Bool = false
    @Published var currentVolume: Float = 0.0

    private init() {
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

        guard configureAudioSession() else {
            endBackgroundTask()
            return
        }

        guard let soundURL = urlForSound(soundName) else {
            print("Sound file not found: \(soundName)")
            endBackgroundTask()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            let prepared = audioPlayer?.prepareToPlay() ?? false
            if !prepared {
                print("Failed to prepare audio player")
            }

            if fadeIn {
                audioPlayer?.volume = 0
                let started = audioPlayer?.play() ?? false
                if started {
                    startFadeIn(targetVolume: volume, duration: fadeInDuration)
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
        stopAlarm()
        beginBackgroundTask()

        guard configureAudioSession() else {
            endBackgroundTask()
            return
        }

        guard let soundURL = urlForSound(soundName) else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = 0
            audioPlayer?.volume = volume
            audioPlayer?.play()

            DispatchQueue.main.async {
                self.isPlaying = true
                self.currentVolume = volume
            }
        } catch {
            print("Preview playback failed: \(error.localizedDescription)")
            endBackgroundTask()
        }
    }

    private func startFadeIn(targetVolume: Float, duration: Double) {
        let steps = 30
        let interval = duration / Double(steps)
        let volumeStep = targetVolume / Float(steps)
        var currentStep = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let player = self?.audioPlayer else {
                timer.invalidate()
                return
            }

            currentStep += 1
            let newVolume = min(targetVolume, volumeStep * Float(currentStep))
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
}
