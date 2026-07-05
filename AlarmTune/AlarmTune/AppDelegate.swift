import SwiftUI
import UIKit
import AVFoundation
import os.log

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
        // M3 修改：仅在有闹钟即将响铃或正在响铃时保持音频会话
        // 无闹钟响铃时，释放音频会话避免影响用户音乐播放
        if !AudioService.shared.isPlaying {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            AppLogger.app.error("Initial audio session configuration failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
