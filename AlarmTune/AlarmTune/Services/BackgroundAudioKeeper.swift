import Foundation
import AVFoundation
import UIKit
import os.log

/// 后台音频保活服务（R1）
/// 在闹钟调度时预排程 AVAudioPlayer 播放，保持 AudioSession 活跃，
/// 使闹钟在后台 + 静音模式下仍能通过 AVAudioPlayer 发声（.playback 类别不受静音拨片控制）
///
/// 技术方案：AVAudioPlayer.play(atTime:) 预排程（Alarmy 同款方案）
/// - play(atTime:) 让播放器立即"启动"但延迟到指定时间发声，不播放静音
/// - .playback 类别绕过静音拨片限制
/// - UIBackgroundModes: audio（已在 Info.plist 配置）保持后台音频权限
///
/// 使用方式：
/// - AlarmScheduler.scheduleAlarm() 时调用 scheduleBackgroundPlayback(for:at:)
/// - AlarmScheduler.cancelAlarm() 时调用 cancelBackgroundPlayback(for:)
/// - 闹钟触发后（willPresent/didReceive）调用 handoverToAudioService(alarmId:)
///
/// 限制：
/// - 仅对内置/导入铃声有效（AVAudioPlayer 可播放），Apple Music 铃声跳过（通知声兜底）
/// - App 被用户手动杀死后失效，需通知声兜底（R2）
final class BackgroundAudioKeeper: NSObject {

    static let shared = BackgroundAudioKeeper()

    /// 预排程的播放器字典，key = alarmId，value = AVAudioPlayer
    /// 支持多个闹钟同时预排程（如重复闹钟）
    private var scheduledPlayers: [String: AVAudioPlayer] = [:]

    /// 音量提升 Timer 字典，key = alarmId，value = Timer
    /// 在闹钟触发前 1 秒提升系统音量，确保后台闹钟有足够音量
    private var volumeBoostTimers: [String: Timer] = [:]

    /// 后台任务标识，保持 App 在后台不被挂起
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    /// 串行队列保护 scheduledPlayers 的线程安全
    private let lockQueue = DispatchQueue(label: "com.zzoutuo.AlarmTune.BackgroundAudioKeeper", qos: .userInitiated)

    private override init() {
        super.init()
    }

    // MARK: - Public

    /// 为指定闹钟预排程后台播放
    /// - Parameters:
    ///   - alarm: 闹钟实体
    ///   - fireDate: 闹钟触发时间
    /// - Note: 仅对内置/导入铃声有效；Apple Music 铃声跳过（通知声兜底）
    func scheduleBackgroundPlayback(for alarm: AlarmItem, at fireDate: Date) {
        // R4 开关检查：用户可在 Settings 中关闭后台保活（省电模式）
        guard isBackgroundKeepAliveEnabled else {
            AppLogger.backgroundKeeper.info("Background keep-alive disabled by user, skip scheduling")
            return
        }

        // Apple Music 铃声无法用 AVAudioPlayer 播放，跳过预排程
        let soundName = alarm.wrappedSoundName
        guard AppConstants.Sound.source(for: soundName) != .appleMusic else {
            AppLogger.backgroundKeeper.info("Apple Music sound cannot be pre-scheduled, notification will handle it")
            return
        }

        // 复用 AudioService.urlForSound() 查找铃声文件
        guard let soundURL = AudioService.shared.urlForSound(soundName) else {
            AppLogger.backgroundKeeper.warning("Sound file not found for background scheduling: \(soundName, privacy: .public)")
            return
        }

        // 计算距触发的秒数
        let timeInterval = fireDate.timeIntervalSinceNow
        guard timeInterval > 0 else {
            AppLogger.backgroundKeeper.warning("Fire date is in the past, skip scheduling")
            return
        }

        // 取消该闹钟旧的预排程（防止重复调度）
        cancelBackgroundPlayback(for: alarm.wrappedId)

        // 创建并配置 AVAudioPlayer
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.numberOfLoops = -1  // 闹钟循环播放
            player.volume = alarm.volume  // 使用闹钟设定的音量
            player.prepareToPlay()

            // 确保 AudioSession 以 .playback 类别激活（绕过静音拨片）
            guard AudioService.shared.configureAudioSession() else {
                AppLogger.backgroundKeeper.error("Failed to configure audio session for background playback")
                return
            }

            // 关键：play(atTime:) 预排程 - 播放器立即"启动"但延迟到指定时间发声
            // 这不是播放静音，而是调度未来播放，符合 Apple 审核要求
            let scheduledTime = player.deviceCurrentTime + timeInterval
            let success = player.play(atTime: scheduledTime)

            if success {
                lockQueue.sync {
                    scheduledPlayers[alarm.wrappedId] = player
                }
                beginBackgroundTask()
                scheduleVolumeBoost(for: alarm.wrappedId, fireDate: fireDate, alarmVolume: alarm.volume)
                AppLogger.backgroundKeeper.info("Background playback scheduled for alarm \(alarm.wrappedId, privacy: .public) at \(fireDate)")
            } else {
                AppLogger.backgroundKeeper.error("Failed to start scheduled playback for alarm \(alarm.wrappedId, privacy: .public)")
            }
        } catch {
            AppLogger.backgroundKeeper.error("Failed to create AVAudioPlayer for background scheduling: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 取消指定闹钟的后台预排程
    /// - Parameters:
    ///   - alarmId: 闹钟 ID
    ///   - restoreVolume: 是否恢复系统音量（handover 场景设为 false，由 AudioService 接管）
    func cancelBackgroundPlayback(for alarmId: String, restoreVolume: Bool = true) {
        cancelVolumeBoostTimer(for: alarmId)

        let player: AVAudioPlayer? = lockQueue.sync {
            return scheduledPlayers.removeValue(forKey: alarmId)
        }
        player?.stop()

        if restoreVolume && VolumeManager.shared.isAlarmActive {
            VolumeManager.shared.restoreSystemVolume()
        }

        if player != nil {
            AppLogger.backgroundKeeper.info("Background playback cancelled for alarm \(alarmId, privacy: .public)")
        }

        // 没有更多预排程时释放后台任务
        if !hasActiveKeepAlive {
            endBackgroundTask()
        }
    }

    /// 取消所有后台预排程（App 退出/全部闹钟禁用时调用）
    func cancelAllBackgroundPlayback() {
        let timers: [String: Timer] = lockQueue.sync {
            let copy = volumeBoostTimers
            volumeBoostTimers.removeAll()
            return copy
        }
        for (_, timer) in timers { timer.invalidate() }

        let players: [String: AVAudioPlayer] = lockQueue.sync {
            let copy = scheduledPlayers
            scheduledPlayers.removeAll()
            return copy
        }

        for (alarmId, player) in players {
            player.stop()
            AppLogger.backgroundKeeper.info("Background playback cancelled for alarm \(alarmId, privacy: .public)")
        }

        if VolumeManager.shared.isAlarmActive {
            VolumeManager.shared.restoreSystemVolume()
        }

        endBackgroundTask()
    }

    /// 闹钟实际触发后，将预排程的播放器移交给 AudioService 正式管理
    /// 避免预排程播放器与 AudioService.playAlarm() 重复播放
    /// - Parameter alarmId: 闹钟 ID
    func handoverToAudioService(alarmId: String) {
        cancelBackgroundPlayback(for: alarmId, restoreVolume: false)
        // AudioService.playAlarm() 会接管正式播放和音量管理
    }

    /// 是否有正在保活的闹钟（供 AppDelegate 判断是否保持 AudioSession）
    var hasActiveKeepAlive: Bool {
        lockQueue.sync {
            return !scheduledPlayers.isEmpty
        }
    }

    // MARK: - Private

    /// 在闹钟触发前 1 秒提升系统音量到最大
    /// 解决后台预排程播放器音量 = systemVolume × playerVolume 问题
    /// Timer 依赖 UIBackgroundModes: audio 保持 App 存活，App 被杀时 Timer 不触发（通知声兜底）
    private func scheduleVolumeBoost(for alarmId: String, fireDate: Date, alarmVolume: Float) {
        let timeUntilBoost = fireDate.timeIntervalSinceNow - 1
        guard timeUntilBoost > 0 else {
            AppLogger.backgroundKeeper.warning("Alarm fires too soon to schedule volume boost, skipping")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let timer = Timer.scheduledTimer(withTimeInterval: timeUntilBoost, repeats: false) { _ in
                VolumeManager.shared.boostSystemVolume(forAlarmVolume: alarmVolume)
                AppLogger.backgroundKeeper.info("Volume boost triggered for alarm \(alarmId, privacy: .public)")
            }
            RunLoop.main.add(timer, forMode: .common)
            self.lockQueue.sync {
                self.volumeBoostTimers[alarmId] = timer
            }
        }
    }

    /// 取消指定闹钟的音量提升 Timer
    private func cancelVolumeBoostTimer(for alarmId: String) {
        let timer: Timer? = lockQueue.sync {
            return volumeBoostTimers.removeValue(forKey: alarmId)
        }
        timer?.invalidate()
    }

    /// R4 设置开关：读取用户是否启用后台保活
    /// 默认开启（true），用户可在 Settings 中关闭以省电
    private var isBackgroundKeepAliveEnabled: Bool {
        UserDefaults.standard.object(forKey: AppConstants.Reliability.backgroundKeepAliveKey) as? Bool
            ?? AppConstants.Reliability.defaultBackgroundKeepAlive
    }

    private func beginBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "BackgroundAudioKeepAlive") { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
