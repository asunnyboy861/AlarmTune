// Services/AlarmKitAdapter.swift
// R7: AlarmKit 适配层（iOS 26+）
// 系统级闹钟调度，绕过静音模式和 Focus，App 被杀后仍可响铃
// 仅支持内置 .caf 铃声 + 无视频背景；其他回退到三层架构

import Foundation
import CoreData
import AlarmKit
import ActivityKit
import SwiftUI
import os.log

struct AlarmTuneMetadata: AlarmMetadata {
    var label: String
}

@available(iOS 26.0, *)
final class AlarmKitAdapter {

    static let shared = AlarmKitAdapter()

    private var updateTask: Task<Void, Never>?

    private init() {
        observeAlarmUpdates()
    }

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            AppLogger.alarm.warning("AlarmKit authorization denied")
            return false
        case .notDetermined:
            do {
                let state = try await manager.requestAuthorization()
                AppLogger.alarm.info("AlarmKit authorization: \(String(describing: state), privacy: .public)")
                return state == .authorized
            } catch {
                AppLogger.alarm.error("AlarmKit authorization error: \(error.localizedDescription, privacy: .public)")
                return false
            }
        @unknown default:
            return false
        }
    }

    var isAuthorized: Bool {
        AlarmManager.shared.authorizationState == .authorized
    }

    // MARK: - Scheduling

    func canSchedule(alarm: AlarmItem) -> Bool {
        let soundName = alarm.wrappedSoundName
        guard AppConstants.Sound.source(for: soundName) == .builtIn else { return false }

        let videoBackgroundName = alarm.videoBackgroundName ?? ""
        guard videoBackgroundName.isEmpty else { return false }

        guard UUID(uuidString: alarm.wrappedId) != nil else { return false }

        guard let url = AudioService.shared.urlForSound(soundName) else { return false }
        guard url.pathExtension == "caf" else { return false }

        return true
    }

    func scheduleAlarm(_ alarm: AlarmItem) async -> Bool {
        guard let uuid = UUID(uuidString: alarm.wrappedId) else {
            AppLogger.alarm.error("AlarmKit: invalid UUID \(alarm.wrappedId, privacy: .public)")
            return false
        }

        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else {
                AppLogger.alarm.warning("AlarmKit: not authorized, falling back to UNNotification")
                return false
            }
        }

        let schedule = buildSchedule(for: alarm)
        let attributes = buildAttributes(for: alarm)
        let sound = buildSound(for: alarm)

        let configuration = AlarmManager.AlarmConfiguration<AlarmTuneMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            sound: sound
        )

        do {
            _ = try await AlarmManager.shared.schedule(id: uuid, configuration: configuration)
            AppLogger.alarm.info("AlarmKit: scheduled alarm \(alarm.wrappedId, privacy: .public)")
            return true
        } catch {
            AppLogger.alarm.error("AlarmKit: schedule failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func cancelAlarm(alarmId: String) {
        guard let uuid = UUID(uuidString: alarmId) else { return }
        Task {
            do {
                try AlarmManager.shared.cancel(id: uuid)
                AppLogger.alarm.info("AlarmKit: cancelled \(alarmId, privacy: .public)")
            } catch {
                AppLogger.alarm.error("AlarmKit: cancel failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func stopAlarm(alarmId: String) {
        guard let uuid = UUID(uuidString: alarmId) else { return }
        Task {
            do {
                try AlarmManager.shared.stop(id: uuid)
                AppLogger.alarm.info("AlarmKit: stopped \(alarmId, privacy: .public)")
            } catch {
                AppLogger.alarm.error("AlarmKit: stop failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func scheduleSnooze(for alarm: AlarmItem, minutes: Int) {
        guard UUID(uuidString: alarm.wrappedId) != nil else { return }

        let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let schedule = Alarm.Schedule.fixed(snoozeDate)
        let attributes = buildAttributes(for: alarm)
        let sound = buildSound(for: alarm)

        let snoozeUuid = UUID(uuidString: alarm.wrappedId + "-snooze") ?? UUID()

        let configuration = AlarmManager.AlarmConfiguration<AlarmTuneMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            sound: sound
        )

        Task {
            do {
                _ = try await AlarmManager.shared.schedule(id: snoozeUuid, configuration: configuration)
                AppLogger.alarm.info("AlarmKit: snooze scheduled for \(minutes) min")
            } catch {
                AppLogger.alarm.error("AlarmKit: snooze failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancelSnooze(alarmId: String) {
        guard let snoozeUuid = UUID(uuidString: alarmId + "-snooze") else { return }
        Task {
            do {
                try AlarmManager.shared.cancel(id: snoozeUuid)
            } catch {
                // snooze 可能不存在，忽略
            }
        }
    }

    // MARK: - Alarm Updates

    private func observeAlarmUpdates() {
        updateTask = Task { [weak self] in
            for await alarms in AlarmManager.shared.alarmUpdates {
                for alarm in alarms {
                    self?.handleAlarmUpdate(alarm)
                }
            }
        }
    }

    private func handleAlarmUpdate(_ alarm: Alarm) {
        let alarmId = alarm.id.uuidString

        switch alarm.state {
        case .alerting:
            AppLogger.alarm.info("AlarmKit: alerting \(alarmId, privacy: .public)")

            // 从 CoreData 获取闹钟配置，调用 AudioService 播放铃声（带音量控制和 fade-in）
            let context = PersistenceController.shared.viewContext
            let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
            // AlarmKit 闹钟 ID 可能带 "-snooze" 后缀，需要匹配基础 ID
            let baseId = alarmId.replacingOccurrences(of: "-snooze", with: "")
            fetchRequest.predicate = NSPredicate(format: "id == %@", baseId)
            if let alarmItem = try? context.fetch(fetchRequest).first {
                let soundName = alarmItem.wrappedSoundName
                let volume = alarmItem.volume
                let isFadeIn = alarmItem.isFadeIn
                let fadeInDuration = alarmItem.fadeInDuration

                // 如果 AudioService 还没在播放（避免 UNNotification 已触发时重复播放）
                if !AudioService.shared.isPlaying {
                    AppLogger.alarm.info("AlarmKit: AudioService接管播放 \(soundName, privacy: .public) vol \(volume, privacy: .public)")
                    AudioService.shared.playAlarm(
                        soundName: soundName,
                        volume: volume,
                        fadeIn: isFadeIn,
                        fadeInDuration: fadeInDuration
                    )
                }
            }

            NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: [
                "alarmId": baseId,
                "alarmKit": true
            ])

        default:
            break
        }
    }

    private func handleAlarmStopped(alarmId: String) {
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarmId)
        guard let alarm = try? context.fetch(fetchRequest).first else {
            NotificationCenter.default.post(name: .alarmDidStop, object: nil)
            return
        }
        let repeatDays = alarm.repeatDays ?? []
        if repeatDays.isEmpty {
            alarm.isEnabled = false
            try? context.save()
            AppLogger.alarm.info("AlarmKit: one-time alarm auto-disabled \(alarmId, privacy: .public)")
        }
        NotificationCenter.default.post(name: .alarmDidStop, object: nil)
    }

    // MARK: - Private Builders

    private func buildSchedule(for alarm: AlarmItem) -> Alarm.Schedule {
        let repeatDays = alarm.repeatDays ?? []

        if repeatDays.isEmpty {
            if let fireDate = alarm.nextFireDate {
                return .fixed(fireDate)
            }
            return .fixed(Date().addingTimeInterval(60))
        }

        let time = Alarm.Schedule.Relative.Time(
            hour: Int(alarm.hour),
            minute: Int(alarm.minute)
        )

        let weekdays: [Locale.Weekday] = repeatDays.compactMap { day in
            switch day {
            case 0: return .sunday
            case 1: return .monday
            case 2: return .tuesday
            case 3: return .wednesday
            case 4: return .thursday
            case 5: return .friday
            case 6: return .saturday
            default: return nil
            }
        }

        let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
        return .relative(Alarm.Schedule.Relative(time: time, repeats: recurrence))
    }

    private func buildAttributes(for alarm: AlarmItem) -> AlarmAttributes<AlarmTuneMetadata> {
        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .white,
            systemImageName: "stop.circle"
        )

        let alert = AlarmPresentation.Alert(
            title: "AlarmTune",
            stopButton: stopButton
        )

        return AlarmAttributes<AlarmTuneMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: AlarmTuneMetadata(label: alarm.wrappedLabel),
            tintColor: .orange
        )
    }

    private func buildSound(for alarm: AlarmItem) -> AlertConfiguration.AlertSound {
        let soundName = alarm.wrappedSoundName
        guard AppConstants.Sound.source(for: soundName) == .builtIn else { return .default }

        guard let url = AudioService.shared.urlForSound(soundName) else { return .default }

        let fileName = url.lastPathComponent
        return .named(fileName)
    }
}
