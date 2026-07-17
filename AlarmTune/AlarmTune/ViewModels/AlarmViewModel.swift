import Foundation
import SwiftUI
import CoreData
import UserNotifications
import os.log

class AlarmViewModel: ObservableObject {
    @Published var alarms: [AlarmItem] = []
    @Published var nextAlarmText: String = "No alarms set"
    @Published var isRinging: Bool = false
    @Published var ringingAlarm: AlarmItem?

    private let context = PersistenceController.shared.viewContext

    init() {
        fetchAlarms()
        updateNextAlarmText()
        setupNotificationObservers()

        // W1 修复：检查冷启动时 didReceive 保存的待处理闹钟
        // 当 APP 被杀后用户点击通知打开 APP，didReceive 可能在 AlarmViewModel.init() 之前被调用
        // 此时 .alarmDidFire 通知无人接收，userInfo 被保存到 AlarmScheduler.pendingLaunchAlarmUserInfo
        if let pendingUserInfo = AlarmScheduler.shared.pendingLaunchAlarmUserInfo {
            AlarmScheduler.shared.pendingLaunchAlarmUserInfo = nil
            AppLogger.viewModel.info("Found pending launch alarm userInfo, processing")
            // 直接调用 handleAlarmFired，模拟 .alarmDidFire 通知
            handleAlarmFired(Notification(name: .alarmDidFire, object: nil, userInfo: pendingUserInfo))
        }

        // CRITICAL: 主动检查 AlarmKit 是否有正在响铃的闹钟
        // 必须在 setupNotificationObservers() 之后调用，否则 .alarmDidFire 无人接收
        // 场景：App 被杀后 AlarmKit 唤醒 -> 冷启动 -> AlarmViewModel 创建
        // alarmUpdates AsyncSequence 在冷启动时延迟投递，不能依赖它
        if #available(iOS 26.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                // 0.3s 延迟确保 fullScreenCover 已绑定 isRinging
                let found = AlarmKitAdapter.shared.checkAndHandleAlertingAlarms()
                if !found {
                    // AlarmKit 没有 alerting 闹钟，检查 UNNotification
                    self?.recoverRingingStateIfNeeded()
                }
            }
        } else {
            // iOS 26 以下：直接检查 UNNotification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.recoverRingingStateIfNeeded()
            }
        }

        // 5秒后执行 rescheduleAllAlarms（给足 alarmUpdates 投递时间 + AudioService 启动时间）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.rescheduleAllAlarms()
        }
    }

    /// 重新调度所有已启用的闹钟（App 启动时调用）
    func rescheduleAllAlarms() {
        // 硬守卫1：如果 AudioService 正在播放或 UI 正在响铃，说明闹钟正在响铃，绝对不能 cancel
        if AudioService.shared.isPlaying || isRinging {
            AppLogger.viewModel.info("Skipping rescheduleAllAlarms - alarm active (isPlaying=\(AudioService.shared.isPlaying), isRinging=\(self.isRinging))")
            return
        }

        // 硬守卫2：检查 AlarmKit 是否有正在响铃的闹钟（使用同步快照 API）
        // alarmUpdates 可能尚未投递，必须主动检查
        if #available(iOS 26.0, *) {
            for alarm in alarms where alarm.isEnabled {
                if AlarmKitAdapter.shared.isCurrentlyAlerting(alarmId: alarm.wrappedId) {
                    AppLogger.viewModel.info("Skipping rescheduleAllAlarms - AlarmKit alarm \(alarm.wrappedId, privacy: .public) is alerting")
                    // 主动处理这个正在响铃的闹钟（启动 AudioService + UI）
                    AlarmKitAdapter.shared.checkAndHandleAlertingAlarms()
                    return
                }
            }
        }

        let enabledCount = alarms.filter { $0.isEnabled }.count
        var disabledExpired = 0
        var skippedAlerting = 0
        let now = Date()
        let alertingWindow: TimeInterval = 300 // 5 分钟窗口：刚触发的闹钟可能正在响铃

        for alarm in alarms where alarm.isEnabled {
            let repeatDays = alarm.repeatDays ?? []

            // 检查闹钟是否可能正在响铃（避免 cancelAlarm 杀死正在响铃的 AlarmKit 闹钟）
            if isAlarmCurrentlyAlerting(alarm: alarm, repeatDays: repeatDays, now: now, alertingWindow: alertingWindow) {
                skippedAlerting += 1
                AppLogger.viewModel.info("Skipping reschedule for currently-alerting alarm \(alarm.wrappedId, privacy: .public)")
                continue
            }

            // 一次性闹钟过期检查：用 scheduledFireDate 精确判断是否已响过
            if repeatDays.isEmpty {
                let scheduledFireDate = UserDefaults.standard.object(forKey: "scheduledFireDate_\(alarm.wrappedId)") as? Date
                if let scheduled = scheduledFireDate, scheduled < now {
                    alarm.isEnabled = false
                    SoundPreRenderer.shared.removeFile(for: alarm.wrappedId)
                    AlarmScheduler.shared.cancelAlarm(alarm)
                    disabledExpired += 1
                    AppLogger.viewModel.info("Auto-disabled expired one-time alarm \(alarm.wrappedId, privacy: .public) (scheduled fire date \(scheduled, privacy: .public) has passed)")
                    continue
                }
            }

            // R8: 重新预渲染声音文件（确保 AlarmKit 和 UNNotification 都能用正确音量播放）
            SoundPreRenderer.shared.render(for: alarm)
            AlarmScheduler.shared.cancelAlarm(alarm)
            AlarmScheduler.shared.scheduleAlarm(alarm)
        }
        if disabledExpired > 0 {
            PersistenceController.shared.saveContext()
        }
        AppLogger.viewModel.info("Rescheduled \(enabledCount - disabledExpired - skippedAlerting, privacy: .public) enabled alarms, auto-disabled \(disabledExpired, privacy: .public) expired, skipped \(skippedAlerting, privacy: .public) alerting")
    }

    /// 判断闹钟是否可能正在响铃
    /// 1. 检查 AlarmKit alerting 状态（如果 alarmUpdates 已送达）
    /// 2. 时间启发式：一次性闹钟 scheduledFireDate 在 5 分钟内 / 重复闹钟当前时间在 hour:minute 的 5 分钟内
    private func isAlarmCurrentlyAlerting(alarm: AlarmItem, repeatDays: [Int], now: Date, alertingWindow: TimeInterval) -> Bool {
        // 检查 AlarmKit alerting 状态
        if #available(iOS 26.0, *), AlarmKitAdapter.shared.isCurrentlyAlerting(alarmId: alarm.wrappedId) {
            return true
        }

        if repeatDays.isEmpty {
            // 一次性闹钟：检查 scheduledFireDate 是否在 5 分钟内
            let scheduledFireDate = UserDefaults.standard.object(forKey: "scheduledFireDate_\(alarm.wrappedId)") as? Date
            if let scheduled = scheduledFireDate {
                let timeSinceFire = now.timeIntervalSince(scheduled)
                if timeSinceFire >= 0 && timeSinceFire < alertingWindow {
                    return true
                }
            }
        } else {
            // 重复闹钟：检查当前时间是否在 hour:minute 的 5 分钟内
            let calendar = Calendar.current
            if let alarmTime = calendar.date(bySettingHour: Int(alarm.hour), minute: Int(alarm.minute), second: 0, of: now) {
                let timeDiff = now.timeIntervalSince(alarmTime)
                if timeDiff >= 0 && timeDiff < alertingWindow {
                    return true
                }
            }
        }
        return false
    }

    func fetchAlarms() {
        let request = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        request.sortDescriptors = [NSSortDescriptor(key: "hour", ascending: true), NSSortDescriptor(key: "minute", ascending: true)]

        do {
            alarms = try context.fetch(request)
        } catch {
            AppLogger.viewModel.error("Failed to fetch alarms: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 刷新闹钟列表和下次闹钟文本（用于 scenePhase 回到前台时调用）
    func refresh() {
        fetchAlarms()
        updateNextAlarmText()
        recoverRingingStateIfNeeded()
    }

    /// App从后台回到前台时，恢复响铃UI状态
    /// 场景1：App在后台时闹钟触发，willPresent未被调用，AudioService未启动
    /// 场景2：App被AlarmKit唤醒（后台），alarmUpdates未投递，isRinging未被设置
    /// 场景3：AlarmKit系统UI已自动消失，但UNNotification仍在通知中心
    /// 场景4：AudioService正在播放但isRinging=false（AlarmKit已被stop）
    /// 场景5：videoSound 模式，AudioService 未播放（只有 prepareForVideoAlarm），但闹钟正在响
    private func recoverRingingStateIfNeeded() {
        // W1 修复：优先检查 videoSound 闹钟
        // 不依赖 AlarmKit（可能未授权），直接基于 CoreData + scheduledFireDate 判断
        // 用户点击通知打开 APP 时，闹钟应仍处于响铃状态
        let now = Date()
        for alarm in alarms where alarm.isEnabled {
            if alarm.wrappedAudioSource == .videoSound && !(alarm.videoBackgroundName ?? "").isEmpty {
                let scheduledFireDate = UserDefaults.standard.object(forKey: "scheduledFireDate_\(alarm.wrappedId)") as? Date
                if let scheduled = scheduledFireDate {
                    let timeSinceFire = now.timeIntervalSince(scheduled)
                    if timeSinceFire >= 0 && timeSinceFire < 300 { // 5 分钟窗口
                        ringingAlarm = alarm
                        isRinging = true
                        _ = AudioService.shared.prepareForVideoAlarm()
                        VolumeManager.shared.boostSystemVolume(to: alarm.videoVolume)
                        AppLogger.viewModel.info("Recovered videoSound ringing state for \(alarm.wrappedId, privacy: .public) (fire was \(timeSinceFire)s ago)")
                        return
                    }
                }
            }
        }

        // 最终兜底：AudioService正在播放但isRinging=false
        // 场景：observeAlarmUpdates后台Task先执行了handleAlarmUpdate -> stop了AlarmKit
        // 然后checkAndHandleAlertingAlarms找不到.alerting状态
        // 但AudioService已经在播放，需要通过它找到闹钟并设置isRinging
        if AudioService.shared.isPlaying && !isRinging {
            // 遍历所有闹钟，找到可能在播放的那个
            // 策略：找到最近5分钟内应该触发的闹钟
            let now = Date()
            for alarm in alarms where alarm.isEnabled {
                let scheduledFireDate = UserDefaults.standard.object(forKey: "scheduledFireDate_\(alarm.wrappedId)") as? Date
                if let scheduled = scheduledFireDate {
                    if now.timeIntervalSince(scheduled) < 300 { // 5分钟内
                        ringingAlarm = alarm
                        isRinging = true
                        AppLogger.viewModel.info("Recovered ringing state via AudioService.isPlaying for \(alarm.wrappedId, privacy: .public)")
                        return
                    }
                }
            }
            // 如果没有找到scheduledFireDate，用第一个启用的闹钟
            if let alarm = alarms.first(where: { $0.isEnabled }) {
                ringingAlarm = alarm
                isRinging = true
                AppLogger.viewModel.warning("Recovered ringing state via fallback for \(alarm.wrappedId, privacy: .public)")
                return
            }
        }

        // 已在响铃状态：检查 AudioService 是否在播放
        if isRinging {
            // UI 显示但无声音 -> AudioService 可能启动失败或被停止，需要补启动
            if !AudioService.shared.isPlaying, let alarm = ringingAlarm {
                AppLogger.viewModel.warning("isRinging=true but AudioService not playing, restarting audio for \(alarm.wrappedId, privacy: .public)")
                if alarm.wrappedAudioSource == .videoSound && !(alarm.videoBackgroundName ?? "").isEmpty {
                    _ = AudioService.shared.prepareForVideoAlarm()
                    VolumeManager.shared.boostSystemVolume(to: alarm.videoVolume)
                } else {
                    AudioService.shared.playAlarm(
                        soundName: alarm.wrappedSoundName,
                        volume: alarm.volume,
                        fadeIn: alarm.isFadeIn,
                        fadeInDuration: alarm.fadeInDuration
                    )
                }
            }
            return
        }

        // 优先检查 AlarmKit alerting 状态（iOS 26+，App 被 AlarmKit 唤醒的场景）
        if #available(iOS 26.0, *) {
            for alarm in alarms where alarm.isEnabled {
                if AlarmKitAdapter.shared.isCurrentlyAlerting(alarmId: alarm.wrappedId) {
                    ringingAlarm = alarm
                    isRinging = true
                    AppLogger.viewModel.info("Recovered ringing state via AlarmKit alerting for \(alarm.wrappedId, privacy: .public)")
                    // AudioService 应已由 handleAlarmUpdate 启动，但如果未启动则补启动
                    if !AudioService.shared.isPlaying {
                        if alarm.wrappedAudioSource == .videoSound && !(alarm.videoBackgroundName ?? "").isEmpty {
                            _ = AudioService.shared.prepareForVideoAlarm()
                            VolumeManager.shared.boostSystemVolume(to: alarm.videoVolume)
                        } else {
                            BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: alarm.wrappedId)
                            AudioService.shared.playAlarm(
                                soundName: alarm.wrappedSoundName,
                                volume: alarm.volume,
                                fadeIn: alarm.isFadeIn,
                                fadeInDuration: alarm.fadeInDuration
                            )
                        }
                    }
                    return
                }
            }
        }

        // 兜底：始终检查已送达的通知
        // 覆盖场景：App 在后台时闹钟触发，AudioService 未启动，BackgroundAudioKeeper 未活跃
        // UNNotification 在通知中心保留 5 分钟，可通过它恢复 UI 和启动音频
        recoverFromDeliveredNotifications()
    }

    private func recoverFromDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            guard let self = self else { return }
            let now = Date()
            // 找到最近5分钟内触发的alarm通知
            let recentAlarmNotifications = notifications.filter {
                $0.request.content.categoryIdentifier == "ALARM_CATEGORY" &&
                now.timeIntervalSince($0.date) < 300
            }
            guard let notification = recentAlarmNotifications.first,
                  let alarmId = notification.request.content.userInfo["alarmId"] as? String else {
                return
            }
            let matchingAlarm = self.alarms.first { $0.wrappedId == alarmId }
            // getDeliveredNotifications 的回调在后台线程
            // @Published 属性必须在主线程设置才能触发 SwiftUI UI 更新
            DispatchQueue.main.async {
                guard !self.isRinging else { return }
                self.ringingAlarm = matchingAlarm
                self.isRinging = true

                // 后台触发的闹钟：BackgroundAudioKeeper在播放但AudioService未接管
                // 需要移交播放权，确保音量控制和视频音频正确处理
                if !AudioService.shared.isPlaying {
                    BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: alarmId)
                    if let alarm = matchingAlarm {
                        if alarm.wrappedAudioSource == .videoSound,
                           (alarm.videoBackgroundName ?? "").isEmpty == false {
                            // videoSound模式：VideoBackgroundView会播放视频音频
                            // 仅准备AudioSession + 设置系统音量
                            _ = AudioService.shared.prepareForVideoAlarm()
                            VolumeManager.shared.boostSystemVolume(to: alarm.videoVolume)
                        } else {
                            // alarmSound模式：AudioService接管闹钟铃声播放
                            AudioService.shared.playAlarm(
                                soundName: alarm.wrappedSoundName,
                                volume: alarm.volume,
                                fadeIn: alarm.isFadeIn,
                                fadeInDuration: alarm.fadeInDuration
                            )
                        }
                    }
                }
                AppLogger.viewModel.info("Recovered ringing state for alarm \(alarmId, privacy: .public) (was ringing in background without UI)")
            }
        }
    }

    func addAlarm(hour: Int, minute: Int, label: String, volume: Float, soundName: String, isFadeIn: Bool, fadeInDuration: Double, isVibrate: Bool, isSnoozeEnabled: Bool = true, snoozeDuration: Int = AppConstants.Alarm.defaultSnoozeMinutes, category: String?, repeatDays: [Int]? = nil, videoBackgroundName: String? = nil, videoVolume: Float = AppConstants.Alarm.defaultVideoVolume, audioSource: String = AppConstants.Alarm.defaultAudioSource) -> AlarmItem {
        let alarm = AlarmItem.create(in: context)
        alarm.hour = Int16(hour)
        alarm.minute = Int16(minute)
        alarm.label = label
        alarm.volume = volume
        alarm.soundName = soundName
        alarm.isFadeIn = isFadeIn
        alarm.fadeInDuration = fadeInDuration
        alarm.isVibrate = isVibrate
        alarm.isSnoozeEnabled = isSnoozeEnabled
        alarm.snoozeDuration = Int16(snoozeDuration)
        alarm.category = category
        alarm.repeatDays = repeatDays
        alarm.videoBackgroundName = videoBackgroundName  // M8.2
        alarm.videoVolume = videoVolume  // V3
        alarm.audioSource = audioSource  // W1

        PersistenceController.shared.saveContext()

        // R8: 预渲染铃声文件（App 被杀后通知仍能播放正确铃声+音量）
        SoundPreRenderer.shared.render(for: alarm)

        AlarmScheduler.shared.scheduleAlarm(alarm)
        fetchAlarms()
        updateNextAlarmText()
        HapticService.shared.success()

        return alarm
    }

    func updateAlarm(_ alarm: AlarmItem) {
        PersistenceController.shared.saveContext()

        // R8: 重新预渲染铃声文件（音量/铃声/fade-in 可能已变更）
        SoundPreRenderer.shared.render(for: alarm)

        if alarm.isEnabled {
            AlarmScheduler.shared.cancelAlarm(alarm)
            AlarmScheduler.shared.scheduleAlarm(alarm)
        }
        fetchAlarms()
        updateNextAlarmText()
        HapticService.shared.light()
    }

    func deleteAlarm(_ alarm: AlarmItem) {
        AlarmScheduler.shared.cancelAlarm(alarm)
        // R8: 删除预渲染文件
        SoundPreRenderer.shared.removeFile(for: alarm.wrappedId)
        PersistenceController.shared.delete(alarm)
        fetchAlarms()
        updateNextAlarmText()
        HapticService.shared.medium()
    }

    func toggleAlarm(_ alarm: AlarmItem) {
        alarm.isEnabled.toggle()
        PersistenceController.shared.saveContext()

        if alarm.isEnabled {
            AlarmScheduler.shared.scheduleAlarm(alarm)
        } else {
            AlarmScheduler.shared.cancelAlarm(alarm)
        }

        fetchAlarms()
        updateNextAlarmText()
        HapticService.shared.selection()
    }

    func stopRingingAlarm() {
        // 一次性闹钟（无重复日）触发后自动禁用，符合 Apple Clock App 标准行为
        if let alarm = ringingAlarm {
            let repeatDays = alarm.repeatDays ?? []
            if repeatDays.isEmpty && alarm.isEnabled {
                alarm.isEnabled = false
                AlarmScheduler.shared.cancelAlarm(alarm)
                PersistenceController.shared.saveContext()
            }
        }

        // 停止 AlarmKit 闹钟
        // 优先使用 ringingAlarm 的 ID；如果 ringingAlarm 为 nil（UI 未显示但闹钟在响），
        // 主动检查 AlarmManager.shared.alarms 找到正在响铃的闹钟并停止
        if let alarmId = ringingAlarm?.wrappedId {
            if #available(iOS 26.0, *) {
                AlarmKitAdapter.shared.stopAlarm(alarmId: alarmId)
            }
            BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarmId)
        } else if #available(iOS 26.0, *) {
            // 兜底：ringingAlarm 为 nil 时，主动查找并停止所有 alerting 的 AlarmKit 闹钟
            AlarmKitAdapter.shared.stopAllAlertingAlarms()
        }

        AudioService.shared.stopAlarm()
        AudioService.shared.endVideoAlarmBackgroundTask()
        VolumeManager.shared.restoreSystemVolume()
        isRinging = false
        ringingAlarm = nil
        NotificationCenter.default.post(name: .alarmDidStop, object: nil)
        fetchAlarms()
        updateNextAlarmText()
    }

    func snoozeRingingAlarm() {
        guard let alarm = ringingAlarm else { return }

        // R7: 同时停止 AlarmKit 闹钟（snooze 会在 scheduleSnooze 中重新调度 AlarmKit）
        if #available(iOS 26.0, *), AlarmKitAdapter.shared.canSchedule(alarm: alarm) {
            AlarmKitAdapter.shared.stopAlarm(alarmId: alarm.wrappedId)
        }

        // R1: 取消当前预排程（snooze 会重新调度通知 + 预排程）
        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarm.wrappedId)

        AudioService.shared.fadeOutAndStop()
        AudioService.shared.endVideoAlarmBackgroundTask()
        AlarmScheduler.shared.scheduleSnooze(for: alarm, minutes: Int(alarm.snoozeDuration))
        isRinging = false
        ringingAlarm = nil
        NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)
    }

    var groupedAlarms: [(category: String, alarms: [AlarmItem])] {
        let grouped = Dictionary(grouping: alarms) { alarm in
            alarm.wrappedCategory.isEmpty ? "Other" : alarm.wrappedCategory
        }

        let categoryOrder = ["Work", "Weekend", "Important", "Nap", "Medication", "Other"]
        return categoryOrder.compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            return (category: cat, alarms: items)
        }
    }

    private func updateNextAlarmText() {
        let enabledAlarms = alarms.filter { $0.isEnabled }
        guard !enabledAlarms.isEmpty else {
            nextAlarmText = "No alarms set"
            return
        }

        let nextAlarm = enabledAlarms.compactMap { alarm -> Date? in
            guard let next = alarm.nextFireDate else { return nil }
            return next
        }.sorted().first

        if let next = nextAlarm {
            nextAlarmText = "Next alarm in \(next.timeUntil())"
        } else {
            nextAlarmText = "No alarms set"
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAlarmFired(_:)),
            name: .alarmDidFire,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAlarmStopped),
            name: .alarmDidStop,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAlarmSnoozed),
            name: .alarmDidSnooze,
            object: nil
        )
    }

    @objc private func handleAlarmFired(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let alarmId = userInfo["alarmId"] as? String else { return }

        // 冷启动时 alarms 数组可能为空，先 fetch 再查找
        if alarms.isEmpty {
            fetchAlarms()
        }

        let matchingAlarm = alarms.first { $0.wrappedId == alarmId }

        // W1 修复：恢复使用 DispatchQueue.main.async
        // 原因：@Published 属性必须在主线程设置才能可靠触发 SwiftUI UI 更新
        // 在后台线程设置是未定义行为，可能导致 UI 不更新
        // 注意：虽然 App 在后台时 main.async 会延迟，但这是正确的行为：
        // - 用户打开 APP 时，main.async 块立即执行
        // - 此时 isRinging 被设置，UI 显示
        // 关键：必须确保 .alarmDidStop 不会在之前被发送（已通过 handleAlarmDisappeared 修复）
        DispatchQueue.main.async {
            self.ringingAlarm = matchingAlarm
            self.isRinging = true
            AppLogger.viewModel.info("handleAlarmFired: set isRinging=true for \(alarmId, privacy: .public) on main thread")
        }
    }

    @objc private func handleAlarmStopped() {
        // 必须在主线程设置 @Published 属性
        DispatchQueue.main.async {
            self.isRinging = false
            self.ringingAlarm = nil
        }
    }

    @objc private func handleAlarmSnoozed() {
        // 必须在主线程设置 @Published 属性
        DispatchQueue.main.async {
            self.isRinging = false
            self.ringingAlarm = nil
        }
    }
}
