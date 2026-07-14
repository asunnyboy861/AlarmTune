import Foundation
import AppIntents
import CoreData
import AlarmKit

/// 用户在 AlarmKit 系统 UI 点击 Stop 时触发
/// openAppWhenRun = true 使系统自动打开 App，显示自定义响铃 UI
@available(iOS 26.0, *)
struct StopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    static var description = IntentDescription("Stop the ringing alarm")
    static var openAppWhenRun = true

    @Parameter(title: "AlarmID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // 停止 AlarmKit 闹钟
        if let uuid = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.stop(id: uuid)
        }

        // 停止 AudioService
        if AudioService.shared.isPlaying {
            AudioService.shared.stopAlarm()
            AudioService.shared.endVideoAlarmBackgroundTask()
        }

        // 停止 BackgroundAudioKeeper
        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarmID)

        // 处理一次性闹钟自动禁用
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarmID)
        if let alarm = try? context.fetch(fetchRequest).first {
            let repeatDays = alarm.repeatDays ?? []
            if repeatDays.isEmpty {
                alarm.isEnabled = false
                try? context.save()
            }
        }

        // 通知 UI 更新
        NotificationCenter.default.post(name: .alarmDidStop, object: nil)

        return .result()
    }
}

/// 用户在 AlarmKit 系统 UI 点击 Snooze 时触发
/// openAppWhenRun = true 使系统自动打开 App，显示自定义响铃 UI
@available(iOS 26.0, *)
struct SnoozeAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Snooze Alarm"
    static var description = IntentDescription("Snooze the ringing alarm")
    static var openAppWhenRun = true

    @Parameter(title: "AlarmID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // 停止当前播放（fade out）
        if AudioService.shared.isPlaying {
            AudioService.shared.fadeOutAndStop()
            AudioService.shared.endVideoAlarmBackgroundTask()
        }

        // 停止 AlarmKit 闹钟（snooze 会在 scheduleSnooze 中重新调度）
        if let uuid = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.stop(id: uuid)
        }

        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarmID)

        // 调度 snooze
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarmID)
        if let alarm = try? context.fetch(fetchRequest).first {
            let snoozeDuration = Int(alarm.snoozeDuration)
            AlarmScheduler.shared.scheduleSnooze(for: alarm, minutes: snoozeDuration)
        }

        // 通知 UI 更新
        NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)

        return .result()
    }
}
