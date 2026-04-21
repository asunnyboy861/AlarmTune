import Foundation
import SwiftUI
import CoreData

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
            print("Failed to fetch alarms: \(error.localizedDescription)")
        }
    }

    func addAlarm(hour: Int, minute: Int, label: String, volume: Float, soundName: String, isFadeIn: Bool, fadeInDuration: Double, isVibrate: Bool, category: String?, repeatDays: [Int]? = nil) -> AlarmItem {
        let alarm = AlarmItem.create(in: context)
        alarm.hour = Int16(hour)
        alarm.minute = Int16(minute)
        alarm.label = label
        alarm.volume = volume
        alarm.soundName = soundName
        alarm.isFadeIn = isFadeIn
        alarm.fadeInDuration = fadeInDuration
        alarm.isVibrate = isVibrate
        alarm.category = category
        alarm.repeatDays = repeatDays

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
        AudioService.shared.stopAlarm()
        isRinging = false
        ringingAlarm = nil
        NotificationCenter.default.post(name: .alarmDidStop, object: nil)
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
    }

    @objc private func handleAlarmFired(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let alarmId = userInfo["alarmId"] as? String else { return }

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
}
