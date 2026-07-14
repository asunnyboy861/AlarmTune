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

    /// snooze UUID 映射（alarmId → snoozeUuid），用于 handleAlarmUpdate 反查
    /// snoozeUuid 通过确定性算法从 alarmId 派生（XOR 最后一个字节），App 重启后可重建
    private var snoozeUuidToAlarmId: [UUID: String] = [:]

    /// 上一次 alarmUpdates 中的 alerting 闹钟集合
    /// 用于检测用户通过系统 UI 停止闹钟（闹钟从列表中消失）
    private var previousAlertingIds: Set<UUID> = []

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

    /// 检查指定闹钟是否正在响铃（供 rescheduleAllAlarms 调用，避免取消正在响铃的闹钟）
    func isCurrentlyAlerting(alarmId: String) -> Bool {
        guard let uuid = UUID(uuidString: alarmId) else { return false }
        return previousAlertingIds.contains(uuid)
    }

    // MARK: - Scheduling

    func canSchedule(alarm: AlarmItem) -> Bool {
        let soundName = alarm.wrappedSoundName
        guard AppConstants.Sound.source(for: soundName) == .builtIn else { return false }

        guard UUID(uuidString: alarm.wrappedId) != nil else { return false }

        guard let url = AudioService.shared.urlForSound(soundName) else { return false }
        guard url.pathExtension == "caf" else { return false }

        // 视频闹钟也允许 AlarmKit 调度：AlarmKit 播放内置铃声作为桥接音，
        // App 启动后由 handleAlarmUpdate 切换到视频音频
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

        // stopIntent/secondaryIntent 让用户在 AlarmKit 系统 UI 点 Stop/Snooze 时自动打开 App
        let stopIntent = StopAlarmIntent(alarmID: alarm.wrappedId)
        let snoozeIntent: SnoozeAlarmIntent? = alarm.isSnoozeEnabled
            ? SnoozeAlarmIntent(alarmID: alarm.wrappedId)
            : nil

        let configuration = AlarmManager.AlarmConfiguration<AlarmTuneMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: snoozeIntent,
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
        cancelSnooze(alarmId: alarmId)
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
        // 同时停止 snooze 闹钟（当前响铃的可能是 snooze）
        if let snoozeUuid = snoozeUuid(for: alarmId) {
            Task {
                do {
                    try AlarmManager.shared.stop(id: snoozeUuid)
                    AppLogger.alarm.info("AlarmKit: stopped snooze for \(alarmId, privacy: .public)")
                } catch {
                    // snooze 可能不存在，忽略
                }
            }
        }
    }

    func scheduleSnooze(for alarm: AlarmItem, minutes: Int) {
        guard UUID(uuidString: alarm.wrappedId) != nil else { return }
        guard let snoozeUuid = snoozeUuid(for: alarm.wrappedId) else { return }

        let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let schedule = Alarm.Schedule.fixed(snoozeDate)
        let attributes = buildAttributes(for: alarm)
        let sound = buildSound(for: alarm)

        let stopIntent = StopAlarmIntent(alarmID: alarm.wrappedId)
        let snoozeIntent: SnoozeAlarmIntent? = alarm.isSnoozeEnabled
            ? SnoozeAlarmIntent(alarmID: alarm.wrappedId)
            : nil

        let configuration = AlarmManager.AlarmConfiguration<AlarmTuneMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: snoozeIntent,
            sound: sound
        )

        // 记录映射，用于 handleAlarmUpdate 反查
        snoozeUuidToAlarmId[snoozeUuid] = alarm.wrappedId

        Task {
            do {
                _ = try await AlarmManager.shared.schedule(id: snoozeUuid, configuration: configuration)
                AppLogger.alarm.info("AlarmKit: snooze scheduled for \(minutes) min, uuid=\(snoozeUuid.uuidString, privacy: .public)")
            } catch {
                AppLogger.alarm.error("AlarmKit: snooze failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancelSnooze(alarmId: String) {
        guard let snoozeUuid = snoozeUuid(for: alarmId) else { return }
        Task {
            do {
                try AlarmManager.shared.cancel(id: snoozeUuid)
                AppLogger.alarm.info("AlarmKit: cancelled snooze for \(alarmId, privacy: .public)")
            } catch {
                // snooze 可能不存在，忽略
            }
        }
    }

    // MARK: - Deterministic Snooze UUID

    /// 从 alarmId 确定性派生 snooze UUID
    /// 算法：将原始 UUID 的最后一个字节 XOR 0x01（翻转最低位）
    /// 保证：同一 alarmId 总是返回同一 snoozeUuid，App 重启后可重建
    private func snoozeUuid(for alarmId: String) -> UUID? {
        guard var uuid = UUID(uuidString: alarmId) else { return nil }
        withUnsafeMutableBytes(of: &uuid) { bytes in
            guard bytes.count == 16 else { return }
            bytes[15] ^= 0x01
        }
        return uuid
    }

    // MARK: - Alarm Updates

    private func observeAlarmUpdates() {
        updateTask = Task { [weak self] in
            for await alarms in AlarmManager.shared.alarmUpdates {
                guard let self = self else { return }

                let currentAlertingIds = Set(alarms.filter { $0.state == .alerting }.map { $0.id })
                let disappearedIds = self.previousAlertingIds.subtracting(currentAlertingIds)
                let allAlarmIds = Set(alarms.map { $0.id })

                for disappearedId in disappearedIds {
                    if allAlarmIds.contains(disappearedId) {
                        // 闹钟仍在列表中但不再 alerting → 用户 snooze 了
                        self.handleAlarmSnoozed(disappearedId)
                    } else {
                        // 闹钟完全从列表中消失 → 用户 stop 了
                        self.handleAlarmDisappeared(disappearedId)
                    }
                }
                self.previousAlertingIds = currentAlertingIds

                for alarm in alarms {
                    self.handleAlarmUpdate(alarm)
                }
            }
        }
    }

    /// 闹钟从 alarmUpdates 列表中完全消失（用户通过系统 UI 停止了闹钟）
    private func handleAlarmDisappeared(_ alarmUuid: UUID) {
        let alarmIdStr = alarmUuid.uuidString
        AppLogger.alarm.info("AlarmKit: alarm disappeared \(alarmIdStr, privacy: .public) — user stopped via system UI")

        let baseId = snoozeUuidToAlarmId[alarmUuid] ?? alarmIdStr
        snoozeUuidToAlarmId.removeValue(forKey: alarmUuid)

        if AudioService.shared.isPlaying {
            AppLogger.alarm.info("AlarmKit: stopping AudioService — alarm disappeared")
            AudioService.shared.stopAlarm()
            AudioService.shared.endVideoAlarmBackgroundTask()
        }

        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: baseId)
        handleAlarmStopped(alarmId: baseId)
        NotificationCenter.default.post(name: .alarmDidStop, object: nil)
    }

    /// 闹钟从 alerting 变为 scheduled（用户通过系统 UI snooze 了闹钟）
    private func handleAlarmSnoozed(_ alarmUuid: UUID) {
        let alarmIdStr = alarmUuid.uuidString
        AppLogger.alarm.info("AlarmKit: alarm snoozed \(alarmIdStr, privacy: .public) — user snoozed via system UI")

        let baseId = snoozeUuidToAlarmId[alarmUuid] ?? alarmIdStr
        snoozeUuidToAlarmId.removeValue(forKey: alarmUuid)

        if AudioService.shared.isPlaying {
            AppLogger.alarm.info("AlarmKit: stopping AudioService — alarm snoozed")
            AudioService.shared.fadeOutAndStop()
            AudioService.shared.endVideoAlarmBackgroundTask()
        }

        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: baseId)
        // snooze 不自动禁用一次性闹钟，不调用 handleAlarmStopped
        NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)
    }

    private func handleAlarmUpdate(_ alarm: Alarm) {
        let alarmKitUuid = alarm.id
        let alarmKitIdStr = alarmKitUuid.uuidString

        switch alarm.state {
        case .alerting:
            AppLogger.alarm.info("AlarmKit: alerting \(alarmKitIdStr, privacy: .public)")

            // 判断是否是 snooze 闹钟：检查 snoozeUuidToAlarmId 映射或确定性派生反查
            let baseId: String
            if let mappedId = snoozeUuidToAlarmId[alarmKitUuid] {
                baseId = mappedId
                AppLogger.alarm.info("AlarmKit: snooze alarm matched via mapping -> \(baseId, privacy: .public)")
            } else {
                // 尝试反查：检查所有已知 alarmId 的 snoozeUuid 是否匹配
                baseId = alarmKitIdStr
            }

            // 从 CoreData 获取闹钟配置
            let context = PersistenceController.shared.viewContext
            let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
            fetchRequest.predicate = NSPredicate(format: "id == %@", baseId)

            if let alarmItem = try? context.fetch(fetchRequest).first {
                let soundName = alarmItem.wrappedSoundName
                let volume = alarmItem.volume
                let isFadeIn = alarmItem.isFadeIn
                let fadeInDuration = alarmItem.fadeInDuration
                let audioSource = alarmItem.wrappedAudioSource
                let videoBackgroundName = alarmItem.videoBackgroundName ?? ""

                // 如果 AudioService 还没在播放（避免 UNNotification 已触发时重复播放）
                if !AudioService.shared.isPlaying {
                    BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: baseId)

                    if audioSource == .videoSound && !videoBackgroundName.isEmpty {
                        // 视频原声模式：不播放闹钟铃声，由 VideoBackgroundView 播放视频音频
                        AppLogger.alarm.info("AlarmKit: videoSound mode, preparing AudioSession for video \(videoBackgroundName, privacy: .public)")
                        _ = AudioService.shared.prepareForVideoAlarm()
                        VolumeManager.shared.boostSystemVolume(to: alarmItem.videoVolume)
                    } else {
                        AppLogger.alarm.info("AlarmKit: AudioService接管播放 \(soundName, privacy: .public) vol \(volume, privacy: .public)")
                        AudioService.shared.playAlarm(
                            soundName: soundName,
                            volume: volume,
                            fadeIn: isFadeIn,
                            fadeInDuration: fadeInDuration
                        )
                    }
                }
            } else {
                // CoreData 未找到：可能是 snooze 闹钟但映射丢失（App 重启后）
                // 尝试用 alarmKitIdStr 反向派生 baseId
                if let reverseBaseId = reverseSnoozeToBaseId(alarmKitUuid) {
                    let fetchRequest2 = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
                    fetchRequest2.predicate = NSPredicate(format: "id == %@", reverseBaseId)
                    if let alarmItem = try? context.fetch(fetchRequest2).first {
                        if !AudioService.shared.isPlaying {
                            BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: reverseBaseId)
                            AppLogger.alarm.info("AlarmKit: snooze reverse-matched -> \(reverseBaseId, privacy: .public)")

                            if alarmItem.wrappedAudioSource == .videoSound && !(alarmItem.videoBackgroundName ?? "").isEmpty {
                                _ = AudioService.shared.prepareForVideoAlarm()
                                VolumeManager.shared.boostSystemVolume(to: alarmItem.videoVolume)
                            } else {
                                AudioService.shared.playAlarm(
                                    soundName: alarmItem.wrappedSoundName,
                                    volume: alarmItem.volume,
                                    fadeIn: alarmItem.isFadeIn,
                                    fadeInDuration: alarmItem.fadeInDuration
                                )
                            }
                        }
                        let snoozeUserInfo: [String: Any] = [
                            "alarmId": reverseBaseId,
                            "alarmKit": true
                        ]
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: snoozeUserInfo)
                        }
                        return
                    }
                }
                AppLogger.alarm.warning("AlarmKit: alerting but alarm not found in CoreData for \(baseId, privacy: .public)")
            }

            // 在主线程发送 .alarmDidFire，确保 AlarmViewModel 立即接收并更新 UI
            // 避免 App 在后台时 main.async 块被延迟执行
            let userInfo: [String: Any] = [
                "alarmId": baseId,
                "alarmKit": true
            ]
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: userInfo)
            }

        default:
            break
        }
    }

    /// 反向推导：给定一个可能的 snoozeUuid，尝试找到对应的 baseId
    /// 算法：将 UUID 最后一个字节 XOR 0x01 还原原始 UUID
    private func reverseSnoozeToBaseId(_ snoozeUuid: UUID) -> String? {
        var uuid = snoozeUuid
        withUnsafeMutableBytes(of: &uuid) { bytes in
            guard bytes.count == 16 else { return }
            bytes[15] ^= 0x01
        }
        let baseUuidStr = uuid.uuidString
        // 验证 CoreData 中是否存在该 alarm
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", baseUuidStr)
        if (try? context.fetch(fetchRequest).first) != nil {
            return baseUuidStr
        }
        return nil
    }

    private func handleAlarmStopped(alarmId: String) {
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", alarmId)
        guard let alarm = try? context.fetch(fetchRequest).first else {
            return
        }
        let repeatDays = alarm.repeatDays ?? []
        if repeatDays.isEmpty {
            alarm.isEnabled = false
            try? context.save()
            AppLogger.alarm.info("AlarmKit: one-time alarm auto-disabled \(alarmId, privacy: .public)")
        }
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

        // snooze 按钮仅在用户启用 snooze 时显示
        let snoozeButton: AlarmButton? = alarm.isSnoozeEnabled ? AlarmButton(
            text: "Snooze",
            textColor: .white,
            systemImageName: "clock.arrow.circlepath"
        ) : nil

        let alert = AlarmPresentation.Alert(
            title: "AlarmTune",
            stopButton: stopButton,
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: snoozeButton != nil ? .countdown : nil
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

        // AlarmKit 只能播放 App Bundle 内的声音文件，无法播放 Library/Sounds/ 中的预渲染文件
        // 因此直接使用原始铃声文件（无音量控制），音量由 AudioService 接管后控制
        guard let url = AudioService.shared.urlForSound(soundName) else { return .default }
        let fileName = url.lastPathComponent
        AppLogger.alarm.info("AlarmKit: using bundle sound \(fileName, privacy: .public) (volume controlled by AudioService)")
        return .named(fileName)
    }
}
