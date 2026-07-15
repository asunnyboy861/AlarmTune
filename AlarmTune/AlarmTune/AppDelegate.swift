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

        // R7: iOS 26+ 启动 AlarmKit 闹钟状态监听
        if #available(iOS 26.0, *) {
            _ = AlarmKitAdapter.shared
            // checkAndHandleAlertingAlarms 由 AlarmViewModel.init() 调用
            // 原因：AlarmViewModel 在 SwiftUI View 首次渲染时创建，
            // 必须等 setupNotificationObservers() 注册 .alarmDidFire 观察者后
            // 才能调用 checkAndHandleAlertingAlarms（它会发送 .alarmDidFire）
            // 如果在 AppDelegate 中调用，AlarmViewModel 还不存在，通知无人接收
        }

        // V1：应用启动时预生成内置视频缩略图，用户打开选择器时立即可见
        Task { @MainActor in
            VideoBackgroundService.shared.generateThumbnails()
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // R3 修改：有待响闹钟预排程时保持 AudioSession 活跃，否则释放
        // 原逻辑：无闹钟播放时一律释放 -> R1 后台保活失效
        // 新逻辑：无闹钟播放 AND 无后台预排程时才释放
        if !AudioService.shared.isPlaying && !BackgroundAudioKeeper.shared.hasActiveKeepAlive {
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
