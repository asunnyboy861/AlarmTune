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
        // 通知权限推迟到用户创建第一个闹钟时再请求，提高授权率

        // V1：应用启动时预生成内置视频缩略图，用户打开选择器时立即可见
        Task { @MainActor in
            VideoBackgroundService.shared.generateThumbnails()
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
