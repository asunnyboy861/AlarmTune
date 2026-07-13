import Foundation
import CoreData
import UserNotifications
import os.log
import AudioToolbox

class AlarmScheduler: NSObject {
    static let shared = AlarmScheduler()

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        // R2: 请求通知权限（含 .criticalAlert，系统未授权时自动降级）
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
        notificationCenter.requestAuthorization(options: options) { granted, error in
            if let error = error {
                AppLogger.alarm.error("Notification authorization error: \(error.localizedDescription, privacy: .public)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }

        // R7: iOS 26+ 同时请求 AlarmKit 权限（双保险）
        if #available(iOS 26.0, *) {
            Task {
                _ = await AlarmKitAdapter.shared.requestAuthorization()
            }
        }
    }

    func scheduleAlarm(_ alarm: AlarmItem) {
        guard alarm.isEnabled else { return }

        // R7: 双保险架构 - AlarmKit + UNNotification 同时调度
        // AlarmKit: 系统级闹钟，绕过静音/Focus，App被杀仍可响铃
        // UNNotification: 三层架构 + R8预渲染，确保音量控制和fade-in
        // 两者协同：AlarmKit alerting -> AudioService接管播放；UNNotification willPresent 去重
        if #available(iOS 26.0, *), AlarmKitAdapter.shared.canSchedule(alarm: alarm) {
            Task {
                let success = await AlarmKitAdapter.shared.scheduleAlarm(alarm)
                if success {
                    AppLogger.alarm.info("AlarmKit scheduled for \(alarm.wrappedId, privacy: .public), also scheduling UNNotification as backup")
                } else {
                    AppLogger.alarm.warning("AlarmKit failed for \(alarm.wrappedId, privacy: .public), UNNotification is primary")
                }
            }
            // 同时调度 UNNotification（不 return）
        }

        // 三层架构（R1-R5）+ R8 预渲染（始终调度，作为保底/音量控制层）
        scheduleViaNotification(alarm)
    }

    /// 通过 UNNotification 调度闹钟（三层架构）
    private func scheduleViaNotification(_ alarm: AlarmItem) {
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

        // M8.1：随机铃声 Shuffle 逻辑
        let effectiveSoundName = resolveShuffledSound(for: alarm)

        // R8: 优先使用预渲染声音文件（App 被杀后仍能播放正确铃声+音量）
        // 预渲染文件在闹钟保存时生成，存入 Library/Sounds/
        if let renderedName = SoundPreRenderer.shared.preRenderedFileName(for: alarm.wrappedId) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: renderedName))
            AppLogger.alarm.info("R8: using pre-rendered sound \(renderedName, privacy: .public) for alarm \(alarm.wrappedId, privacy: .public)")
        } else {
            // 回退：.defaultCritical（系统默认关键警报声音，无法反映用户选择的铃声和音量）
            content.sound = .defaultCritical
        }
        content.categoryIdentifier = "ALARM_CATEGORY"

        // R2 新增：timeSensitive 中断级别（iOS 15+，突破 Focus 模式）
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        // M8.2：传递 videoBackgroundName（App 被杀后台时 AlarmViewModel 恢复用）
        let videoBackgroundName = alarm.videoBackgroundName ?? ""

        content.userInfo = [
            "alarmId": alarm.wrappedId,
            "volume": alarm.volume,
            "soundName": effectiveSoundName,
            "videoBackgroundName": videoBackgroundName,
            "audioSource": alarm.audioSource ?? AppConstants.Alarm.defaultAudioSource,
            "videoVolume": alarm.videoVolume,
            "isFadeIn": alarm.isFadeIn,
            "fadeInDuration": alarm.fadeInDuration,
            "isVibrate": alarm.isVibrate,
            "isSnoozeEnabled": alarm.isSnoozeEnabled,
            "snoozeDuration": Int(alarm.snoozeDuration)
        ]
        return content
    }

    /// R2 废弃并删除：notificationSound(for:) 方法
    /// 原因：R2 统一使用 .defaultCritical，不再需要按铃声名查找通知音文件
    /// 原方法查找 Bundle 中的音频文件作为自定义通知音，但现在所有闹钟统一用 .defaultCritical

    /// M8.1：解析 Shuffle 后的铃声名
    /// 如果开启 Shuffle 且到了更换周期，从内置铃声中随机选择一首
    /// 使用 per-alarm key 避免多闹钟互相覆盖
    private func resolveShuffledSound(for alarm: AlarmItem) -> String {
        let modeRaw = UserDefaults.standard.string(forKey: AppConstants.Sound.shuffleModeKey) ?? ""
        guard let mode = AppConstants.Sound.ShuffleMode(rawValue: modeRaw),
              mode != .off else {
            return alarm.wrappedSoundName
        }

        let alarmId = alarm.wrappedId
        let shuffleKey = "alarmShuffleCurrentSound_\(alarmId)"
        let lastChangeKey = "alarmShuffleLastChange_\(alarmId)"

        let lastChange = UserDefaults.standard.double(forKey: lastChangeKey)
        let now = Date().timeIntervalSince1970
        let interval: TimeInterval = (mode == .daily) ? 86400 : 604800  // 1 day : 7 days

        // 还未到更换时间，使用上次 Shuffle 的铃声
        if lastChange > 0 && (now - lastChange) < interval {
            return UserDefaults.standard.string(forKey: shuffleKey) ?? alarm.wrappedSoundName
        }

        // 到了更换时间，随机选择新铃声
        let newSound = AppConstants.Sound.shuffleSound(excluding: alarm.wrappedSoundName)
        UserDefaults.standard.set(newSound, forKey: shuffleKey)
        UserDefaults.standard.set(now, forKey: lastChangeKey)
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
                AppLogger.alarm.error("Failed to schedule one-time alarm: \(error.localizedDescription, privacy: .public)")
            }
        }

        // R1 新增：后台音频保活预排程（与通知双保险）
        if let fireDate = alarm.nextFireDate {
            BackgroundAudioKeeper.shared.scheduleBackgroundPlayback(for: alarm, at: fireDate)
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
                    AppLogger.alarm.error("Failed to schedule repeating alarm for day \(day): \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        // R1 新增：重复闹钟取最近一次触发时间预排程
        if let fireDate = alarm.nextFireDate {
            BackgroundAudioKeeper.shared.scheduleBackgroundPlayback(for: alarm, at: fireDate)
        }
    }

    func scheduleSnooze(for alarm: AlarmItem, minutes: Int) {
        // R7: 同时调度 AlarmKit snooze（双保险）
        if #available(iOS 26.0, *), AlarmKitAdapter.shared.canSchedule(alarm: alarm) {
            AlarmKitAdapter.shared.scheduleSnooze(for: alarm, minutes: minutes)
        }

        // 三层架构 snooze
        let content = UNMutableNotificationContent()
        content.title = "AlarmTune"
        content.body = "\(alarm.wrappedLabel) (Snooze)"
        content.categoryIdentifier = "ALARM_CATEGORY"

        // R8: snooze 通知也使用预渲染声音文件
        if let renderedName = SoundPreRenderer.shared.preRenderedFileName(for: alarm.wrappedId) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: renderedName))
        } else {
            // 回退：.defaultCritical
            content.sound = .defaultCritical
        }

        // R2 新增：timeSensitive 中断级别（iOS 15+，突破 Focus 模式）
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        content.userInfo = [
            "alarmId": alarm.wrappedId,
            "volume": alarm.volume,
            "soundName": alarm.wrappedSoundName,
            "videoBackgroundName": alarm.videoBackgroundName ?? "",
            "audioSource": alarm.audioSource ?? AppConstants.Alarm.defaultAudioSource,
            "videoVolume": alarm.videoVolume,
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
                AppLogger.alarm.error("Failed to schedule snooze: \(error.localizedDescription, privacy: .public)")
            }
        }

        // R1 fix: snooze 也需要后台保活预排程，否则后台 snooze 闹钟仅依赖通知声
        let snoozeFireDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        BackgroundAudioKeeper.shared.scheduleBackgroundPlayback(for: alarm, at: snoozeFireDate)
    }

    func cancelAlarm(_ alarm: AlarmItem) {
        // R7: 同时取消 AlarmKit 闹钟（双保险模式下两者都被调度了）
        if #available(iOS 26.0, *), AlarmKitAdapter.shared.canSchedule(alarm: alarm) {
            AlarmKitAdapter.shared.cancelAlarm(alarmId: alarm.wrappedId)
            AlarmKitAdapter.shared.cancelSnooze(alarmId: alarm.wrappedId)
        }

        // 取消三层架构的闹钟
        var identifiers = [alarm.wrappedId]

        if let repeatDays = alarm.repeatDays, !repeatDays.isEmpty {
            for day in repeatDays {
                identifiers.append("\(alarm.wrappedId)-day\(day)")
            }
        }

        identifiers.append("\(alarm.wrappedId)-snooze")

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)

        // R1 新增：取消后台预排程
        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarm.wrappedId)
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

        // R7 去重：如果 AudioService 已在播放（AlarmKit 先触发了），不重复播放
        if AudioService.shared.isPlaying {
            AppLogger.alarm.info("UNNotification willPresent: AudioService already playing (AlarmKit), skipping duplicate")
            completionHandler([.banner, .badge])
            return
        }

        // R1 新增：将预排程播放器移交给 AudioService，避免重复播放
        if let alarmId = userInfo["alarmId"] as? String {
            BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: alarmId)
        }
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
            AudioService.shared.endVideoAlarmBackgroundTask()
            if let alarmId = userInfo["alarmId"] as? String {
                BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarmId)
            }
            handleStopAction(userInfo: userInfo)
            NotificationCenter.default.post(name: .alarmDidStop, object: nil)

        case "SNOOZE_ACTION":
            AudioService.shared.fadeOutAndStop()
            AudioService.shared.endVideoAlarmBackgroundTask()
            if let alarmId = userInfo["alarmId"] as? String {
                BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarmId)
            }
            handleSnoozeAction(userInfo: userInfo)

        case UNNotificationDefaultActionIdentifier:
            // 用户点击通知体 -> 打开响铃 UI
            // R1 新增：移交预排程播放器
            if let alarmId = userInfo["alarmId"] as? String {
                BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: alarmId)
            }
            handleAlarmNotification(userInfo: userInfo)

        case UNNotificationDismissActionIdentifier:
            // M3 新增：处理用户划走通知（之前 default: break，导致一次性闹钟不自动禁用）
            // 复用 STOP_ACTION 逻辑：停止音频 + 自动禁用一次性闹钟
            AudioService.shared.stopAlarm()
            AudioService.shared.endVideoAlarmBackgroundTask()
            if let alarmId = userInfo["alarmId"] as? String {
                BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: alarmId)
            }
            handleStopAction(userInfo: userInfo)
            NotificationCenter.default.post(name: .alarmDidStop, object: nil)

        default:
            break
        }

        completionHandler()
    }

    /// M3 提取：一次性闹钟自动禁用逻辑（原内联在 STOP_ACTION 中，dismiss action 也复用）
    /// 重复闹钟不受影响，仅一次性闹钟（repeatDays 为空）触发后自动禁用
    private func handleStopAction(userInfo: [AnyHashable: Any]) {
        guard let alarmId = userInfo["alarmId"] as? String else { return }
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarmId)
        guard let alarm = try? context.fetch(fetchRequest).first else { return }
        let repeatDays = alarm.repeatDays ?? []
        if repeatDays.isEmpty {
            alarm.isEnabled = false
            try? context.save()
        }
    }

    /// M3 提取：snooze 调度逻辑（原内联在 SNOOZE_ACTION 中）
    private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
        guard let alarmId = userInfo["alarmId"] as? String else {
            NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)
            return
        }
        // 兼容 Int/NSNumber（推送通知 JSON 解析可能返回 NSNumber）
        let snoozeDuration: Int
        if let v = userInfo["snoozeDuration"] as? Int {
            snoozeDuration = v
        } else if let v = userInfo["snoozeDuration"] as? NSNumber {
            snoozeDuration = v.intValue
        } else {
            AppLogger.alarm.error("handleSnoozeAction: missing snoozeDuration, using default")
            snoozeDuration = AppConstants.Alarm.defaultSnoozeMinutes
        }
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarmId)
        if let alarm = try? context.fetch(fetchRequest).first {
            AlarmScheduler.shared.scheduleSnooze(for: alarm, minutes: snoozeDuration)
        }
        NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)
    }

    private func handleAlarmNotification(userInfo: [AnyHashable: Any]) {
        guard let soundName = userInfo["soundName"] as? String else {
            AppLogger.alarm.error("handleAlarmNotification: missing soundName")
            return
        }
        // 兼容 Float/Double/NSNumber（推送通知 JSON 解析可能返回 Double 而非 Float）
        let volume: Float
        if let v = userInfo["volume"] as? Float {
            volume = v
        } else if let v = userInfo["volume"] as? Double {
            volume = Float(v)
        } else if let v = userInfo["volume"] as? NSNumber {
            volume = v.floatValue
        } else {
            AppLogger.alarm.error("handleAlarmNotification: missing or invalid volume")
            return
        }

        let isFadeIn = userInfo["isFadeIn"] as? Bool ?? false
        let fadeInDuration = userInfo["fadeInDuration"] as? Double ?? 5.0

        // W1/W3：视频原声模式下不播放闹钟铃声，由 VideoBackgroundView 播放视频自带音轨
        let audioSource = userInfo["audioSource"] as? String ?? AppConstants.Alarm.defaultAudioSource
        if audioSource == AppConstants.AudioSource.videoSound.rawValue {
            // W6 修复：videoSound 模式必须激活 AudioSession + 启动 Background Task
            _ = AudioService.shared.prepareForVideoAlarm()
            // 兼容 Float/Double/NSNumber（同 volume 修复）
            let videoVolume: Float
            if let v = userInfo["videoVolume"] as? Float {
                videoVolume = v
            } else if let v = userInfo["videoVolume"] as? Double {
                videoVolume = Float(v)
            } else if let v = userInfo["videoVolume"] as? NSNumber {
                videoVolume = v.floatValue
            } else {
                videoVolume = volume
            }
            VolumeManager.shared.boostSystemVolume(to: videoVolume)
        } else {
            AppLogger.alarm.info("handleAlarmNotification: playing \(soundName, privacy: .public) vol \(volume, privacy: .public) fade \(isFadeIn, privacy: .public)")
            AudioService.shared.playAlarm(
                soundName: soundName,
                volume: volume,
                fadeIn: isFadeIn,
                fadeInDuration: fadeInDuration
            )
        }

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
