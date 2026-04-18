import Foundation
import AVFoundation
import UIKit

class AudioService: ObservableObject {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?

    @Published var isPlaying: Bool = false
    @Published var currentVolume: Float = 0.0

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error.localizedDescription)")
        }
    }

    func playAlarm(soundName: String, volume: Float, fadeIn: Bool = false, fadeInDuration: Double = 5.0) {
        stopAlarm()
        configureAudioSession()

        guard let soundURL = urlForSound(soundName) else {
            print("Sound file not found: \(soundName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()

            if fadeIn {
                audioPlayer?.volume = 0
                audioPlayer?.play()
                startFadeIn(targetVolume: volume, duration: fadeInDuration)
            } else {
                audioPlayer?.volume = volume
                audioPlayer?.play()
            }

            DispatchQueue.main.async {
                self.isPlaying = true
                self.currentVolume = volume
            }
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
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
        configureAudioSession()

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
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Sounds") {
            return bundleURL
        }
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds") {
            return bundleURL
        }
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: "caf") {
            return bundleURL
        }
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: "mp3") {
            return bundleURL
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
