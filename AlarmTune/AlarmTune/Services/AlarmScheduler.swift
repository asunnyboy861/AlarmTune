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
        let repeatDays = alarm.repeatDays ?? []

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
        // F2-1 修复：设置兜底系统声音，确保APP被杀后台时仍能听到通知
        // 当APP在前台时，willPresent 回调启动 AVAudioPlayer 自定义音量播放，
        // completionHandler 中不传 .sound 避免双重播放
        content.sound = .default
        content.categoryIdentifier = "ALARM_CATEGORY"

        // M8.1：随机铃声 Shuffle 逻辑
        // 如果开启 Shuffle 且到了更换周期，从内置铃声中随机选择
        let effectiveSoundName = resolveShuffledSound(for: alarm)

        // M8.2：传递 videoBackgroundName（App 被杀后台时 AlarmViewModel 恢复用）
        let videoBackgroundName = alarm.videoBackgroundName ?? ""

        content.userInfo = [
            "alarmId": alarm.wrappedId,
            "volume": alarm.volume,
            "soundName": effectiveSoundName,
            "videoBackgroundName": videoBackgroundName,
            "isFadeIn": alarm.isFadeIn,
            "fadeInDuration": alarm.fadeInDuration,
            "isVibrate": alarm.isVibrate,
            "isSnoozeEnabled": alarm.isSnoozeEnabled,
            "snoozeDuration": Int(alarm.snoozeDuration)
        ]
        return content
    }

    /// M8.1：解析 Shuffle 后的铃声名
    /// 如果开启 Shuffle 且到了更换周期，从内置铃声中随机选择一首
    private func resolveShuffledSound(for alarm: AlarmItem) -> String {
        let modeRaw = UserDefaults.standard.string(forKey: AppConstants.Sound.shuffleModeKey) ?? ""
        guard let mode = AppConstants.Sound.ShuffleMode(rawValue: modeRaw),
              mode != .off else {
            return alarm.wrappedSoundName
        }

        let lastChange = UserDefaults.standard.double(forKey: AppConstants.Sound.shuffleLastChangeKey)
        let now = Date().timeIntervalSince1970
        let interval: TimeInterval = (mode == .daily) ? 86400 : 604800  // 1 day : 7 days

        // 还未到更换时间，使用上次 Shuffle 的铃声
        if lastChange > 0 && (now - lastChange) < interval {
            return UserDefaults.standard.string(forKey: "alarmShuffleCurrentSound") ?? alarm.wrappedSoundName
        }

        // 到了更换时间，随机选择新铃声
        let newSound = AppConstants.Sound.shuffleSound(excluding: alarm.wrappedSoundName)
        UserDefaults.standard.set(newSound, forKey: "alarmShuffleCurrentSound")
        UserDefaults.standard.set(now, forKey: AppConstants.Sound.shuffleLastChangeKey)
        return newSound
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
        // F2-1 修复：贪睡通知也需要兜底声音
        content.sound = .default
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

        if let repeatDays = alarm.repeatDays, !repeatDays.isEmpty {
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
        // F2-1 修复：APP在前台时，AVAudioPlayer 已在 handleAlarmNotification 中启动，
        // 不传 .sound 避免系统通知声音与 AVAudioPlayer 同时播放
        completionHandler([.banner, .badge])
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
