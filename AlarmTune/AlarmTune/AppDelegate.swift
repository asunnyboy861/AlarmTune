import SwiftUI
import UIKit
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureAudioSession()
        AlarmScheduler.shared.registerNotificationCategories()
        AlarmScheduler.shared.requestAuthorization { granted in
            if !granted {
                print("Notification permission not granted")
            }
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AudioService.shared.configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("Initial audio session configuration failed: \(error.localizedDescription)")
        }
    }
}
