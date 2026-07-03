import Foundation
import MediaPlayer
import AVFoundation
import UIKit

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
    /// - Parameter targetAlarmVolume: 闹钟设定的音量 (0.0 ~ 1.0)
    /// - Returns: 是否成功提升系统音量
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
    private func setSystemVolume(_ volume: Float) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let slider = self.volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else {
                print("[VolumeManager] Warning: Unable to set system volume — MPVolumeView slider not found")
                return
            }
            slider.value = volume
        }
    }
}
