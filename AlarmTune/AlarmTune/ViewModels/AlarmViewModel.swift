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
        // R7 fix: AlarmKit 禁用后，重新调度所有已启用的闹钟
        // 之前通过 AlarmKit 路径创建的闹钟没有 UNNotification，需要补调度
        rescheduleAllAlarms()
    }

    /// 重新调度所有已启用的闹钟（App 启动时调用）
    func rescheduleAllAlarms() {
        let enabledCount = alarms.filter { $0.isEnabled }.count
        var disabledExpired = 0
        for alarm in alarms where alarm.isEnabled {
            // 一次性闹钟过期检查：如果 App 被杀时闹钟已触发，自动禁用逻辑未执行
            // 此时 nextFireDate 返回明天，会导致一次性闹钟明天重复响铃
            let repeatDays = alarm.repeatDays ?? []
            if repeatDays.isEmpty, let nextFire = alarm.nextFireDate {
                if !Calendar.current.isDateInToday(nextFire) {
                    alarm.isEnabled = false
                    SoundPreRenderer.shared.removeFile(for: alarm.wrappedId)
                    AlarmScheduler.shared.cancelAlarm(alarm)
                    disabledExpired += 1
                    AppLogger.viewModel.info("Auto-disabled expired one-time alarm \(alarm.wrappedId, privacy: .public) (fire time already passed)")
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
        AppLogger.viewModel.info("Rescheduled \(enabledCount - disabledExpired, privacy: .public) enabled alarms, auto-disabled \(disabledExpired, privacy: .public) expired")
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
    /// 场景：App在后台时闹钟通过BackgroundAudioKeeper触发，willPresent未被调用，
    /// isRinging仍为false，用户打开App后看不到Stop/Snooze按钮
    /// 修复：检查最近5分钟内delivered的alarm通知，恢复响铃UI
    private func recoverRingingStateIfNeeded() {
        guard !isRinging else { return }
        guard !AudioService.shared.isPlaying else {
            // AudioService在播放但UI未显示（AlarmKit在后台触发了但isRinging未设置）
            // 尝试从delivered notifications找到对应alarm
            recoverFromDeliveredNotifications()
            return
        }
        // BackgroundAudioKeeper可能有活跃播放器（后台触发）
        if BackgroundAudioKeeper.shared.hasActiveKeepAlive {
            recoverFromDeliveredNotifications()
        }
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

        // R7: 同时停止 AlarmKit 闹钟（双保险模式下两者都在响）
        if let alarmId = ringingAlarm?.wrappedId {
            if #available(iOS 26.0, *) {
                AlarmKitAdapter.shared.stopAlarm(alarmId: alarmId)
            }
            // R1: 取消后台预排程
            BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarmId)
        }

        AudioService.shared.stopAlarm()
        AudioService.shared.endVideoAlarmBackgroundTask()
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
        DispatchQueue.main.async {
            self.ringingAlarm = matchingAlarm
            self.isRinging = true
        }
    }

    @objc private func handleAlarmStopped() {
        DispatchQueue.main.async {
            self.isRinging = false
            self.ringingAlarm = nil
        }
    }

    @objc private func handleAlarmSnoozed() {
        DispatchQueue.main.async {
            self.isRinging = false
            self.ringingAlarm = nil
        }
    }
}
