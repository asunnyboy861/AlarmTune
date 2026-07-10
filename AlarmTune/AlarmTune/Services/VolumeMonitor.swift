import Foundation
import AVFoundation
import Combine

/// 系统音量监测器 - 监测系统音量变化并提供预警状态（F2-3）
///
/// 使用方式：View 层通过 @ObservedObject var volumeMonitor = VolumeMonitor.shared 绑定
/// 调用 volumeMonitor.warningMessage(for:) 获取预警文案
/// 调用 volumeMonitor.volumeLevelIcon / volumeLevelColor 获取 UI 素材
final class VolumeMonitor: ObservableObject {

    static let shared = VolumeMonitor()

    /// 当前系统输出音量 (0.0 ~ 1.0)
    @Published private(set) var systemVolume: Float = 0.0

    /// 系统音量等级描述
    enum VolumeLevel {
        case muted       // 0.0
        case veryLow     // 0.01 ~ 0.15
        case low         // 0.16 ~ 0.35
        case moderate    // 0.36 ~ 0.65
        case high        // 0.66 ~ 1.0
    }

    /// 当前系统音量等级
    var volumeLevel: VolumeLevel {
        switch systemVolume {
        case 0: return .muted
        case 0.01...0.15: return .veryLow
        case 0.16...0.35: return .low
        case 0.36...0.65: return .moderate
        default: return .high
        }
    }

    /// 系统音量等级对应的 SF Symbol 图标
    var volumeLevelIcon: String {
        switch volumeLevel {
        case .muted: return "speaker.slash.fill"
        case .veryLow: return "speaker.fill"
        case .low: return "speaker.wave.1.fill"
        case .moderate: return "speaker.wave.2.fill"
        case .high: return "speaker.wave.3.fill"
        }
    }

    /// 系统音量等级对应的颜色（用于 AlarmItem.AlarmCategory 风格的 color 字符串）
    var volumeLevelColor: String {
        switch volumeLevel {
        case .muted: return "red"
        case .veryLow: return "red"
        case .low: return "orange"
        case .moderate: return "green"
        case .high: return "blue"
        }
    }

    /// 判断给定闹钟音量下，系统音量是否过低可能听不见
    /// - Parameter alarmVolume: 闹钟设定的音量 (0.0 ~ 1.0)
    /// - Returns: 是否音量过低
    ///
    /// 计算公式：effectiveVolume = systemVolume × alarmVolume
    /// 当 effectiveVolume < AppConstants.Volume.audibleThreshold 时视为过低
    func isVolumeTooLow(for alarmVolume: Float) -> Bool {
        let effectiveVolume = systemVolume * alarmVolume
        return effectiveVolume < AppConstants.Volume.audibleThreshold
    }

    /// 获取给定闹钟音量下的预警文案
    /// - Parameter alarmVolume: 闹钟设定的音量
    /// - Returns: 预警文案，无预警时返回 nil
    func warningMessage(for alarmVolume: Float) -> String? {
        guard isVolumeTooLow(for: alarmVolume) else { return nil }

        if systemVolume == 0 {
            return "Your iPhone is muted. Alarm may not be audible."
        } else if systemVolume < 0.2 {
            return "System volume is very low (\(Int(systemVolume * 100))%). Alarm may be hard to hear."
        } else {
            return "System volume is low (\(Int(systemVolume * 100))%). Consider raising it."
        }
    }

    // MARK: - R5: Reliability Assessment

    /// R5 新增：评估闹钟在静音模式下的可靠性等级
    /// 综合：后台保活开关 + 铃声来源 + 系统音量
    /// - Parameters:
    ///   - alarmVolume: 闹钟设定的音量
    ///   - soundName: 铃声名称
    ///   - isBackgroundKeepAlive: 后台保活是否开启
    /// - Returns: 可靠性等级
    func reliabilityLevel(for alarmVolume: Float, soundName: String, isBackgroundKeepAlive: Bool) -> AppConstants.Reliability.ReliabilityLevel {
        let soundSource = AppConstants.Sound.source(for: soundName)

        // 系统音量为 0 + 无保活 -> 高风险
        if systemVolume == 0 && !isBackgroundKeepAlive {
            return .atRisk
        }

        // Apple Music 铃声无法预排程 -> 部分可靠
        if soundSource == .appleMusic && !isBackgroundKeepAlive {
            return .partial
        }

        // 后台保活开启 + 内置/导入铃声 -> 可靠
        if isBackgroundKeepAlive && soundSource != .appleMusic {
            return .reliable
        }

        // 后台保活关闭 -> 部分可靠（仅非静音模式可响）
        return .partial
    }

    /// R5 新增：可靠性预警文案
    func reliabilityMessage(for level: AppConstants.Reliability.ReliabilityLevel) -> String? {
        switch level {
        case .reliable:
            return nil  // 可靠时不显示预警
        case .partial:
            return "Alarm may not ring in silent mode. Enable Background Alarm Guard in Settings for reliability."
        case .atRisk:
            return "System volume is muted and Background Alarm Guard is off. Alarm may not sound."
        }
    }

    // MARK: - Private

    /// 使用 KVO 监测系统音量变化
    private var volumeObservation: NSKeyValueObservation?

    private init() {
        updateSystemVolume()
        observeVolumeChanges()
    }

    private func updateSystemVolume() {
        systemVolume = AVAudioSession.sharedInstance().outputVolume
    }

    /// 使用 KVO observe(\.outputVolume) 监测系统音量变化
    /// 这是 iOS 上监测系统音量变化的正确方式
    private func observeVolumeChanges() {
        volumeObservation = AVAudioSession.sharedInstance().observe(
            \.outputVolume,
            options: [.new]
        ) { [weak self] session, _ in
            DispatchQueue.main.async {
                self?.systemVolume = session.outputVolume
            }
        }
    }
}
