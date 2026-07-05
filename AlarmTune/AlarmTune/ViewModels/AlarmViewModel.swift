import Foundation
import SwiftUI
import CoreData
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
        AlarmScheduler.shared.scheduleAlarm(alarm)
        fetchAlarms()
        updateNextAlarmText()
        HapticService.shared.success()

        return alarm
    }

    func updateAlarm(_ alarm: AlarmItem) {
        PersistenceController.shared.saveContext()
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

        AudioService.shared.stopAlarm()
        isRinging = false
        ringingAlarm = nil
        NotificationCenter.default.post(name: .alarmDidStop, object: nil)
        fetchAlarms()
        updateNextAlarmText()
    }

    func snoozeRingingAlarm() {
        guard let alarm = ringingAlarm else { return }
        AudioService.shared.fadeOutAndStop()
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
