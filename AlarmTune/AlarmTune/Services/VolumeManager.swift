import Foundation
import MediaPlayer
import AVFoundation
import UIKit
import os.log

/// 系统音量管理器 - 负责闹钟触发时的系统音量临时调整与恢复
/// 解决 AVAudioPlayer.volume 依赖系统音量导致闹钟听不见的问题（F2-2）
///
/// 使用方式：AudioService 在 playAlarm() 开始时调用 boostSystemVolume()，
/// 在 stopAlarm() 时调用 restoreSystemVolume()
///
/// 注意：MPVolumeView slider 方案在 iOS 15+ 上可能受限，
/// 若失败则依赖 VolumeMonitor 预警机制作为兜底
final class VolumeManager: ObservableObject {

    static let shared = VolumeManager()

    /// 闹钟触发前的系统音量，用于播放结束后恢复
    private var savedSystemVolume: Float?

    /// 隐藏的 MPVolumeView，用于程序化调整系统音量
    private let volumeView = MPVolumeView()

    /// 是否正在闹钟播放模式（系统音量已被临时调高）
    @Published private(set) var isAlarmActive: Bool = false

    private init() {
        // MPVolumeView 需要添加到窗口层级中才能使用其 slider
        // iOS 15+ 兼容：使用 connectedScenes 替代已废弃的 windows
        setupVolumeView()
    }

    // MARK: - Public

    /// 获取当前系统输出音量 (0.0 ~ 1.0)
    /// 使用 AVAudioSession.outputVolume，与 VolumeMonitor 保持一致
    var currentSystemVolume: Float {
        AVAudioSession.sharedInstance().outputVolume
    }

    /// 闹钟触发时调用：保存当前系统音量并提升到最大
    /// - Parameter targetAlarmVolume: 闹钟设定的音量 (0.0 ~ 1.0)，仅用于日志记录
    /// - Returns: 是否成功提升系统音量
    /// - Note: 用于 AVAudioPlayer 播放场景（AVAudioPlayer.volume 独立控制闹钟音量）
    @discardableResult
    func boostSystemVolume(forAlarmVolume targetAlarmVolume: Float) -> Bool {
        // 防止重复调用（多个闹钟同时触发时保护）
        guard !isAlarmActive else { return true }

        let current = currentSystemVolume
        savedSystemVolume = current

        // 仅当系统音量低于最大值时才提升
        if current < 1.0 {
            setSystemVolume(1.0)
        }

        isAlarmActive = true
        return true
    }

    /// 闹钟触发时调用：保存当前系统音量并设置为指定音量
    /// - Parameter targetVolume: 目标系统音量 (0.0 ~ 1.0)
    /// - Returns: 是否成功设置系统音量
    /// - Note: 用于 MPMusicPlayerController 播放场景（iOS 不允许设置 player.volume，
    ///   只能通过系统音量控制播放音量）
    @discardableResult
    func boostSystemVolume(to targetVolume: Float) -> Bool {
        guard !isAlarmActive else { return true }

        let current = currentSystemVolume
        savedSystemVolume = current
        setSystemVolume(targetVolume)
        isAlarmActive = true
        return true
    }

    /// 闹钟停止时调用：恢复原始系统音量
    func restoreSystemVolume() {
        guard isAlarmActive, let saved = savedSystemVolume else {
            isAlarmActive = false
            return
        }

        setSystemVolume(saved)
        savedSystemVolume = nil
        isAlarmActive = false
    }

    // MARK: - Private

    /// 将 MPVolumeView 添加到当前窗口场景
    /// iOS 15+ 兼容：使用 UIWindowScene 替代已废弃的 UIApplication.shared.windows
    private func setupVolumeView() {
        volumeView.isHidden = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            window.addSubview(self.volumeView)
            self.volumeView.frame = CGRect(x: -1000, y: -1000, width: 100, height: 100)
        }
    }

    /// 通过 MPVolumeView 的 slider 设置系统音量
    /// 线程安全：强制在主线程执行
    /// M11：带重试机制，slider 可能尚未附加到窗口或尚未完成布局
    private func setSystemVolume(_ volume: Float) {
        setSystemVolumeWithRetry(volume, attempts: 3)
    }

    /// M11 新增：带重试的系统音量设置
    /// slider 查找失败时延迟重试，最多 attempts 次
    private func setSystemVolumeWithRetry(_ volume: Float, attempts: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 确保 volumeView 已附加到窗口（可能因场景切换被移除）
            self.ensureVolumeViewAttached()

            if let slider = self.volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                slider.value = volume
                return
            }

            // slider 未找到
            if attempts > 1 {
                // 延迟重试（slider 可能尚未完成布局）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.setSystemVolumeWithRetry(volume, attempts: attempts - 1)
                }
            } else {
                // 重试耗尽 — 记录警告，闹钟仍可通过 AVAudioPlayer.volume 播放（不依赖系统音量）
                AppLogger.volume.warning("Unable to set system volume after retries — MPVolumeView slider not found")
            }
        }
    }

    /// M11 新增：确保 volumeView 已附加到当前窗口场景
    /// 场景切换或 App 重新激活后，volumeView 可能需要重新附加
    private func ensureVolumeViewAttached() {
        if volumeView.superview != nil { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.addSubview(volumeView)
        volumeView.frame = CGRect(x: -1000, y: -1000, width: 100, height: 100)
    }
}
