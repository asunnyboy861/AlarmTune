import Foundation
import CoreData
import UserNotifications
import AudioToolbox

class AlarmScheduler: NSObject {
    static let shared = AlarmScheduler()

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func scheduleAlarm(_ alarm: AlarmItem) {
        guard alarm.isEnabled else { return }

        let content = createNotificationContent(for: alarm)
        let repeatDays = alarm.repeatDays as? [Int] ?? []

        if repeatDays.isEmpty {
            scheduleOneTimeAlarm(alarm: alarm, content: content)
        } else {
            scheduleRepeatingAlarm(alarm: alarm, content: content, repeatDays: repeatDays)
        }
    }

    private func createNotificationContent(for alarm: AlarmItem) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "AlarmTune"
        content.body = alarm.wrappedLabel
        content.sound = nil
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.wrappedId,
            "volume": alarm.volume,
            "soundName": alarm.wrappedSoundName,
            "isFadeIn": alarm.isFadeIn,
            "fadeInDuration": alarm.fadeInDuration,
            "isVibrate": alarm.isVibrate,
            "isSnoozeEnabled": alarm.isSnoozeEnabled,
            "snoozeDuration": Int(alarm.snoozeDuration)
        ]
        return content
    }

    private func scheduleOneTimeAlarm(alarm: AlarmItem, content: UNMutableNotificationContent) {
        var dateComponents = DateComponents()
        dateComponents.hour = Int(alarm.hour)
        dateComponents.minute = Int(alarm.minute)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: alarm.wrappedId,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule one-time alarm: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleRepeatingAlarm(alarm: AlarmItem, content: UNMutableNotificationContent, repeatDays: [Int]) {
        for day in repeatDays {
            var dateComponents = DateComponents()
            dateComponents.hour = Int(alarm.hour)
            dateComponents.minute = Int(alarm.minute)
            dateComponents.weekday = day + 1

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let requestId = "\(alarm.wrappedId)-day\(day)"
            let request = UNNotificationRequest(
                identifier: requestId,
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule repeating alarm for day \(day): \(error.localizedDescription)")
                }
            }
        }
    }

    func scheduleSnooze(for alarm: AlarmItem, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "AlarmTune"
        content.body = "\(alarm.wrappedLabel) (Snooze)"
        content.sound = nil
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.wrappedId,
            "volume": alarm.volume,
            "soundName": alarm.wrappedSoundName,
            "isFadeIn": false,
            "fadeInDuration": 0.0,
            "isVibrate": alarm.isVibrate,
            "isSnoozeEnabled": alarm.isSnoozeEnabled,
            "snoozeDuration": Int(alarm.snoozeDuration)
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let snoozeId = "\(alarm.wrappedId)-snooze"
        let request = UNNotificationRequest(
            identifier: snoozeId,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule snooze: \(error.localizedDescription)")
            }
        }
    }

    func cancelAlarm(_ alarm: AlarmItem) {
        var identifiers = [alarm.wrappedId]

        if let repeatDays = alarm.repeatDays as? [Int] {
            for day in repeatDays {
                identifiers.append("\(alarm.wrappedId)-day\(day)")
            }
        }

        identifiers.append("\(alarm.wrappedId)-snooze")

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cancelAllAlarms() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    func registerNotificationCategories() {
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "Stop",
            options: [.destructive]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [stopAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([category])
    }
}

extension AlarmScheduler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        handleAlarmNotification(userInfo: userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "STOP_ACTION":
            AudioService.shared.stopAlarm()
            NotificationCenter.default.post(name: .alarmDidStop, object: nil)

        case "SNOOZE_ACTION":
            AudioService.shared.fadeOutAndStop()
            if let snoozeDuration = userInfo["snoozeDuration"] as? Int,
               let alarmId = userInfo["alarmId"] as? String {
                let context = PersistenceController.shared.viewContext
                let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
                fetchRequest.predicate = NSPredicate(format: "id == %@", alarmId)
                if let alarm = try? context.fetch(fetchRequest).first {
                    AlarmScheduler.shared.scheduleSnooze(for: alarm, minutes: snoozeDuration)
                }
            }
            NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)

        case UNNotificationDefaultActionIdentifier:
            handleAlarmNotification(userInfo: userInfo)

        default:
            break
        }

        completionHandler()
    }

    private func handleAlarmNotification(userInfo: [AnyHashable: Any]) {
        guard let soundName = userInfo["soundName"] as? String,
              let volume = userInfo["volume"] as? Float else { return }

        let isFadeIn = userInfo["isFadeIn"] as? Bool ?? false
        let fadeInDuration = userInfo["fadeInDuration"] as? Double ?? 5.0

        AudioService.shared.playAlarm(
            soundName: soundName,
            volume: volume,
            fadeIn: isFadeIn,
            fadeInDuration: fadeInDuration
        )

        if let isVibrate = userInfo["isVibrate"] as? Bool, isVibrate {
            vibrate()
        }

        NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: userInfo)
    }

    private func vibrate() {
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<3 {
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + Double(i) * 0.5) {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }
        }
    }
}

extension Notification.Name {
    static let alarmDidFire = Notification.Name("alarmDidFire")
    static let alarmDidStop = Notification.Name("alarmDidStop")
    static let alarmDidSnooze = Notification.Name("alarmDidSnooze")
}
