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

    /// AudioService 已接管播放时设为 true
    /// 防止 handleAlarmSnoozed/handleAlarmDisappeared 误停 AudioService
    /// 当 AudioService 启动后，主动停止 AlarmKit 闹钟避免双音叠加
    private var audioServiceTookOver: Bool = false

    /// 当前正在响铃的 AlarmKit 闹钟 ID（videoSound 模式）
    /// 用于在 UI 显示后停止 AlarmKit 避免双音叠加
    private(set) var pendingVideoAlarmKitId: UUID?

    /// 标记当前闹钟是否为 videoSound 模式
    /// videoSound 模式下 AlarmKit 作为"桥接音"，UI 显示后才停止
    /// 暴露为只读属性，供 recoverRingingStateIfNeeded 检查
    private(set) var isVideoSoundMode: Bool = false

    /// UserDefaults key 用于持久化 videoSound 模式状态
    /// App 被杀后恢复时，内存状态会丢失，需要通过 UserDefaults 恢复
    private let videoSoundModeKey = "alarmKitVideoSoundMode"
    private let pendingVideoAlarmIdKey = "alarmKitPendingVideoAlarmId"

    /// 在调度时持久化的 videoSound 闹钟 ID 集合
    /// 关键：isVideoSoundMode 内存变量在 fire time 通过 main.async 设置，
    /// 但 App 被杀后后台启动时 main.async 被挂起，导致内存状态丢失。
    /// 此集合在 scheduleAlarm 时写入，确保 App 重启后仍能判断 videoSound 模式。
    private let videoSoundAlarmIdsKey = "alarmKitVideoSoundAlarmIds"

    private init() {
        observeAlarmUpdates()
    }

    // MARK: - VideoSound Alarm Registration (schedule-time persistence)

    /// 在调度闹钟时注册 videoSound 模式（持久化到 UserDefaults）
    /// 解决 App 被杀后 main.async 挂起导致 isVideoSoundMode 内存状态丢失的问题
    private func registerVideoSoundAlarm(alarmId: String) {
        var ids = UserDefaults.standard.array(forKey: videoSoundAlarmIdsKey) as? [String] ?? []
        if !ids.contains(alarmId) {
            ids.append(alarmId)
            UserDefaults.standard.set(ids, forKey: videoSoundAlarmIdsKey)
            AppLogger.alarm.info("AlarmKit: registered videoSound alarm \(alarmId, privacy: .public) at schedule time")
        }
    }

    private func unregisterVideoSoundAlarm(alarmId: String) {
        var ids = UserDefaults.standard.array(forKey: videoSoundAlarmIdsKey) as? [String] ?? []
        ids.removeAll { $0 == alarmId }
        UserDefaults.standard.set(ids, forKey: videoSoundAlarmIdsKey)
    }

    /// 检查指定闹钟是否为 videoSound 模式（从 UserDefaults 读取，不依赖内存状态）
    /// 用于 handleAlarmDisappeared/Snoozed 和 StopAlarmIntent，避免误停止 videoSound 闹钟
    func isVideoSoundAlarm(alarmId: String) -> Bool {
        // 优先检查内存状态（实时性好）
        if isVideoSoundMode { return true }
        // 从 UserDefaults 恢复（App 冷启动后内存状态丢失）
        let ids = UserDefaults.standard.array(forKey: videoSoundAlarmIdsKey) as? [String] ?? []
        return ids.contains(alarmId)
    }

    /// App 启动时主动检查是否有正在响铃的 AlarmKit 闹钟
    /// Apple 文档：App 重启时必须调用 AlarmManager.shared.alarms 获取当前快照
    /// alarmUpdates AsyncSequence 在冷启动时可能延迟投递，不能依赖它
    @discardableResult
    func checkAndHandleAlertingAlarms() -> Bool {
        guard isAuthorized else { return false }

        do {
            let allAlarms = try AlarmManager.shared.alarms
            let alertingAlarms = allAlarms.filter { $0.state == .alerting }

            if alertingAlarms.isEmpty {
                AppLogger.alarm.info("AlarmKit: no alerting alarms on launch")
                return false
            }

            AppLogger.alarm.info("AlarmKit: found \(alertingAlarms.count) alerting alarm(s) on launch")

            // 同步更新 previousAlertingIds
            previousAlertingIds = Set(alertingAlarms.map { $0.id })

            // 主动处理每个正在响铃的闹钟（不等 alarmUpdates）
            for alarm in alertingAlarms {
                handleAlarmUpdate(alarm)
            }

            return true
        } catch {
            AppLogger.alarm.error("AlarmKit: failed to get alarms snapshot on launch: \(error.localizedDescription, privacy: .public)")
            return false
        }
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

        // 优先检查 previousAlertingIds（来自 alarmUpdates，实时性好）
        if previousAlertingIds.contains(uuid) { return true }

        // previousAlertingIds 为空时，主动获取 AlarmManager.shared.alarms 同步快照
        // Apple 文档：App 重启时必须调用 AlarmManager.shared.alarms 获取当前状态
        // alarmUpdates AsyncSequence 在 App 冷启动/从后台恢复时可能延迟投递
        do {
            let allAlarms = try AlarmManager.shared.alarms
            let alertingIds = Set(allAlarms.filter { $0.state == .alerting }.map { $0.id })
            // 同步更新 previousAlertingIds
            previousAlertingIds = alertingIds
            return alertingIds.contains(uuid)
        } catch {
            AppLogger.alarm.error("AlarmKit: failed to get alarms snapshot: \(error.localizedDescription, privacy: .public)")
            return false
        }
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

        // 在调度时持久化 videoSound 模式状态
        // 关键：App 被杀后 main.async 挂起，fire time 的 isVideoSoundMode 设置会延迟
        // 必须在 schedule 时就记录，确保 App 重启后 handleAlarmDisappeared 能正确判断
        if alarm.wrappedAudioSource == .videoSound && !(alarm.videoBackgroundName ?? "").isEmpty {
            registerVideoSoundAlarm(alarmId: alarm.wrappedId)
        }

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
        unregisterVideoSoundAlarm(alarmId: alarmId)
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
        audioServiceTookOver = false
        isVideoSoundMode = false
        pendingVideoAlarmKitId = nil
        UserDefaults.standard.set(false, forKey: videoSoundModeKey)
        UserDefaults.standard.removeObject(forKey: pendingVideoAlarmIdKey)
        unregisterVideoSoundAlarm(alarmId: alarmId)
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

    /// 停止作为"桥接音"的 AlarmKit 闹钟（videoSound 模式）
    /// 当 VideoBackgroundView 开始播放视频音频时调用，避免双音叠加
    func stopBridgeAlarmIfNeeded() {
        guard isVideoSoundMode, let uuid = pendingVideoAlarmKitId else { return }
        isVideoSoundMode = false
        pendingVideoAlarmKitId = nil
        UserDefaults.standard.set(false, forKey: videoSoundModeKey)
        UserDefaults.standard.removeObject(forKey: pendingVideoAlarmIdKey)
        Task {
            do {
                try AlarmManager.shared.stop(id: uuid)
                AppLogger.alarm.info("AlarmKit: stopped bridge alarm for videoSound mode (video audio started)")
            } catch {
                AppLogger.alarm.error("AlarmKit: stop bridge alarm failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// 停止所有正在响铃的 AlarmKit 闹钟（兜底方法）
    /// 当 ringingAlarm 为 nil 但 AlarmKit 闹钟在响时使用
    func stopAllAlertingAlarms() {
        audioServiceTookOver = false
        guard isAuthorized else {
            AppLogger.alarm.warning("AlarmKit: stopAllAlertingAlarms - not authorized")
            return
        }

        do {
            let allAlarms = try AlarmManager.shared.alarms
            let alertingAlarms = allAlarms.filter { $0.state == .alerting }

            for alarm in alertingAlarms {
                Task {
                    do {
                        try AlarmManager.shared.stop(id: alarm.id)
                        AppLogger.alarm.info("AlarmKit: stopped alerting alarm \(alarm.id.uuidString, privacy: .public)")
                    } catch {
                        AppLogger.alarm.error("AlarmKit: stop failed for \(alarm.id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    }
                }
            }

            if alertingAlarms.isEmpty {
                AppLogger.alarm.info("AlarmKit: stopAllAlertingAlarms - no alerting alarms found")
            }
        } catch {
            AppLogger.alarm.error("AlarmKit: stopAllAlertingAlarms failed: \(error.localizedDescription, privacy: .public)")
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

    /// 纯计算版 snooze UUID 反转（不访问 CoreData，可在任意线程调用）
    /// 用于 handleAlarmUpdate 中同步检查 videoSound 模式
    private func computeSnoozeBaseId(_ snoozeUuid: UUID) -> String {
        var uuid = snoozeUuid
        withUnsafeMutableBytes(of: &uuid) { bytes in
            guard bytes.count == 16 else { return }
            bytes[15] ^= 0x01
        }
        return uuid.uuidString
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
        AppLogger.alarm.info("""
            AlarmKit: alarm disappeared \(alarmIdStr, privacy: .public)
            [DEBUG] Thread: \(Thread.isMainThread ? "main" : "background")
            [DEBUG] audioServiceTookOver=\(self.audioServiceTookOver), isVideoSoundMode=\(self.isVideoSoundMode)
            """)

        // 获取 baseId：优先用 snooze 映射，其次纯计算反推 snooze UUID，最后用原始 UUID
        // 使用 computeSnoozeBaseId（纯计算，不访问 CoreData），可在后台线程安全调用
        let baseId: String
        if let mappedId = snoozeUuidToAlarmId[alarmUuid] {
            baseId = mappedId
        } else {
            let computedBaseId = computeSnoozeBaseId(alarmUuid)
            // 如果计算出的 baseId 在 videoSound 注册集合中，说明这是 snooze 闹钟
            if isVideoSoundAlarm(alarmId: computedBaseId) {
                baseId = computedBaseId
            } else {
                baseId = alarmIdStr
            }
        }
        snoozeUuidToAlarmId.removeValue(forKey: alarmUuid)

        // 如果 AudioService 已接管播放，这个 disappeared 是我们自己调用 stop 导致的
        // 不需要停止 AudioService
        if audioServiceTookOver {
            AppLogger.alarm.info("AlarmKit: ignoring disappeared - AudioService took over")
            audioServiceTookOver = false
            return
        }

        // W1 修复：videoSound 模式下，AlarmKit 作为"桥接音"被停止是预期行为
        // 用户点击通知打开 APP → AlarmKit 系统 UI 关闭 → 闹钟消失
        // 此时 VideoBackgroundView 应该正在播放视频音频，不应发送 .alarmDidStop
        //
        // 关键修复：使用 isVideoSoundAlarm(baseId) 检查 UserDefaults 持久化状态，
        // 而非 isVideoSoundMode 内存变量。App 冷启动后 main.async 被挂起，
        // isVideoSoundMode 未被设置，会导致误停止 videoSound 闹钟。
        if isVideoSoundAlarm(alarmId: baseId) {
            AppLogger.alarm.info("AlarmKit: ignoring disappeared - videoSound mode (bridge alarm stopped, video audio active)")
            isVideoSoundMode = false
            pendingVideoAlarmKitId = nil
            UserDefaults.standard.set(false, forKey: videoSoundModeKey)
            UserDefaults.standard.removeObject(forKey: pendingVideoAlarmIdKey)
            unregisterVideoSoundAlarm(alarmId: baseId)
            return
        }

        if AudioService.shared.isPlaying {
            AppLogger.alarm.info("AlarmKit: stopping AudioService — alarm disappeared")
            AudioService.shared.stopAlarm()
            AudioService.shared.endVideoAlarmBackgroundTask()
            VolumeManager.shared.restoreSystemVolume()
        }

        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: baseId)
        handleAlarmStopped(alarmId: baseId)
        NotificationCenter.default.post(name: .alarmDidStop, object: nil)
    }

    /// 闹钟从 alerting 变为 scheduled（用户通过系统 UI snooze 了闹钟）
    private func handleAlarmSnoozed(_ alarmUuid: UUID) {
        let alarmIdStr = alarmUuid.uuidString
        AppLogger.alarm.info("AlarmKit: alarm snoozed \(alarmIdStr, privacy: .public)")

        // 获取 baseId：优先用 snooze 映射，其次纯计算反推 snooze UUID，最后用原始 UUID
        let baseId: String
        if let mappedId = snoozeUuidToAlarmId[alarmUuid] {
            baseId = mappedId
        } else {
            let computedBaseId = computeSnoozeBaseId(alarmUuid)
            if isVideoSoundAlarm(alarmId: computedBaseId) {
                baseId = computedBaseId
            } else {
                baseId = alarmIdStr
            }
        }
        snoozeUuidToAlarmId.removeValue(forKey: alarmUuid)

        // 如果 AudioService 已接管播放，这个 snoozed 是我们自己调用 stop 导致的
        if audioServiceTookOver {
            AppLogger.alarm.info("AlarmKit: ignoring snoozed - AudioService took over")
            audioServiceTookOver = false
            return
        }

        // W1 修复：videoSound 模式下，忽略 snoozed 事件
        // 桥接音被停止不应触发 snooze 流程
        // 关键修复：使用 isVideoSoundAlarm(baseId) 检查 UserDefaults 持久化状态
        if isVideoSoundAlarm(alarmId: baseId) {
            AppLogger.alarm.info("AlarmKit: ignoring snoozed - videoSound mode")
            isVideoSoundMode = false
            pendingVideoAlarmKitId = nil
            UserDefaults.standard.set(false, forKey: videoSoundModeKey)
            UserDefaults.standard.removeObject(forKey: pendingVideoAlarmIdKey)
            return
        }

        if AudioService.shared.isPlaying {
            AppLogger.alarm.info("AlarmKit: stopping AudioService — alarm snoozed")
            AudioService.shared.fadeOutAndStop()
            AudioService.shared.endVideoAlarmBackgroundTask()
            VolumeManager.shared.restoreSystemVolume()
        }

        BackgroundAudioKeeper.shared.cancelBackgroundPlayback(for: baseId)
        // snooze 不自动禁用一次性闹钟，不调用 handleAlarmStopped
        NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)
    }

    private func handleAlarmUpdate(_ alarm: Alarm) {
        let alarmKitUuid = alarm.id
        let alarmKitIdStr = alarmKitUuid.uuidString

        guard alarm.state == .alerting else { return }
        AppLogger.alarm.info("AlarmKit: alerting \(alarmKitIdStr, privacy: .public)")

        // 关键修复：同步设置 isVideoSoundMode（不等 main.async）
        // App 在后台时 main.async 被挂起，handleAlarmDisappeared 可能在 main.async 之前执行，
        // 导致 isVideoSoundMode 为 false，误停止 videoSound 闹钟。
        // 通过 UserDefaults 持久化状态同步恢复内存变量。
        // 注意：此处不调用 reverseSnoozeToBaseId（它访问 CoreData，需主线程），
        // 而是用纯计算的 snoozeBaseId，检查是否在 videoSound 注册集合中。
        let baseId: String
        if let mappedId = snoozeUuidToAlarmId[alarmKitUuid] {
            baseId = mappedId
        } else {
            let computedSnoozeBaseId = computeSnoozeBaseId(alarmKitUuid)
            if isVideoSoundAlarm(alarmId: computedSnoozeBaseId) {
                baseId = computedSnoozeBaseId
            } else {
                baseId = alarmKitIdStr
            }
        }
        if isVideoSoundAlarm(alarmId: baseId) && !isVideoSoundMode {
            isVideoSoundMode = true
            pendingVideoAlarmKitId = alarmKitUuid
            AppLogger.alarm.info("AlarmKit: pre-set isVideoSoundMode=true for \(baseId, privacy: .public) (sync, before main.async)")
        }

        // W1 修复：将 CoreData 访问和状态修改移到主线程
        // viewContext 是 mainQueueConcurrencyType，后台线程访问可能导致失败或不可预测行为
        // 如果已在主线程，直接调用避免 main.async 延迟
        if Thread.isMainThread {
            handleAlertingAlarmOnMainThread(alarmKitUuid: alarmKitUuid, alarmKitIdStr: alarmKitIdStr)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.handleAlertingAlarmOnMainThread(alarmKitUuid: alarmKitUuid, alarmKitIdStr: alarmKitIdStr)
            }
        }
    }

    /// 在主线程处理 alerting 状态的 AlarmKit 闹钟
    private func handleAlertingAlarmOnMainThread(alarmKitUuid: UUID, alarmKitIdStr: String) {
        // 判断是否是 snooze 闹钟：检查 snoozeUuidToAlarmId 映射或确定性派生反查
        let baseId: String
        if let mappedId = snoozeUuidToAlarmId[alarmKitUuid] {
            baseId = mappedId
            AppLogger.alarm.info("AlarmKit: snooze alarm matched via mapping -> \(baseId, privacy: .public)")
        } else {
            baseId = alarmKitIdStr
        }

        // 从 CoreData 获取闹钟配置
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
        fetchRequest.predicate = NSPredicate(format: "id == %@", baseId)

        guard let alarmItem = try? context.fetch(fetchRequest).first else {
            // CoreData 未找到：可能是 snooze 闹钟但映射丢失（App 重启后）
            handleAlertingAlarmWhenCoreDataMissing(alarmKitUuid: alarmKitUuid, alarmKitIdStr: alarmKitIdStr)
            return
        }

        // 如果 AudioService 已经在播放（UNNotification 已触发），避免重复播放但仍需通知 UI
        if AudioService.shared.isPlaying {
            NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: [
                "alarmId": baseId,
                "alarmKit": true
            ])
            return
        }

        BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: baseId)

        let audioSource = alarmItem.wrappedAudioSource
        let videoBackgroundName = alarmItem.videoBackgroundName ?? ""

        if audioSource == .videoSound && !videoBackgroundName.isEmpty {
            // 视频原声模式：AlarmKit 作为"桥接音"继续播放，直到 UI 显示
            AppLogger.alarm.info("AlarmKit: videoSound mode, keeping AlarmKit as bridge for video \(videoBackgroundName, privacy: .public)")
            _ = AudioService.shared.prepareForVideoAlarm()
            VolumeManager.shared.boostSystemVolume(to: alarmItem.videoVolume)

            // 标记为 videoSound 模式并持久化
            isVideoSoundMode = true
            pendingVideoAlarmKitId = alarmKitUuid
            UserDefaults.standard.set(true, forKey: videoSoundModeKey)
            UserDefaults.standard.set(alarmKitUuid.uuidString, forKey: pendingVideoAlarmIdKey)
        } else {
            AppLogger.alarm.info("AlarmKit: AudioService接管播放 \(alarmItem.wrappedSoundName, privacy: .public) vol \(alarmItem.volume, privacy: .public)")
            AudioService.shared.playAlarm(
                soundName: alarmItem.wrappedSoundName,
                volume: alarmItem.volume,
                fadeIn: alarmItem.isFadeIn,
                fadeInDuration: alarmItem.fadeInDuration
            )

            // alarmSound 模式：AudioService 已接管，立即停止 AlarmKit 避免双音
            audioServiceTookOver = true
            Task {
                do {
                    try AlarmManager.shared.stop(id: alarmKitUuid)
                    AppLogger.alarm.info("AlarmKit: stopped alarm after AudioService takeover (avoid dual sound)")
                } catch {
                    AppLogger.alarm.error("AlarmKit: stop after takeover failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: [
            "alarmId": baseId,
            "alarmKit": true
        ])
    }

    /// CoreData 找不到 alerting 闹钟时的兜底处理
    private func handleAlertingAlarmWhenCoreDataMissing(alarmKitUuid: UUID, alarmKitIdStr: String) {
        // 尝试反查：可能是 snooze 闹钟但映射丢失
        if let reverseBaseId = reverseSnoozeToBaseId(alarmKitUuid) {
            let context = PersistenceController.shared.viewContext
            let fetchRequest2 = NSFetchRequest<AlarmItem>(entityName: "AlarmItem")
            fetchRequest2.predicate = NSPredicate(format: "id == %@", reverseBaseId)
            if let alarmItem = try? context.fetch(fetchRequest2).first {
                if !AudioService.shared.isPlaying {
                    BackgroundAudioKeeper.shared.handoverToAudioService(alarmId: reverseBaseId)
                    AppLogger.alarm.info("AlarmKit: snooze reverse-matched -> \(reverseBaseId, privacy: .public)")

                    if alarmItem.wrappedAudioSource == .videoSound && !(alarmItem.videoBackgroundName ?? "").isEmpty {
                        _ = AudioService.shared.prepareForVideoAlarm()
                        VolumeManager.shared.boostSystemVolume(to: alarmItem.videoVolume)
                        isVideoSoundMode = true
                        pendingVideoAlarmKitId = alarmKitUuid
                        UserDefaults.standard.set(true, forKey: videoSoundModeKey)
                        UserDefaults.standard.set(alarmKitUuid.uuidString, forKey: pendingVideoAlarmIdKey)
                    } else {
                        AudioService.shared.playAlarm(
                            soundName: alarmItem.wrappedSoundName,
                            volume: alarmItem.volume,
                            fadeIn: alarmItem.isFadeIn,
                            fadeInDuration: alarmItem.fadeInDuration
                        )
                        audioServiceTookOver = true
                        Task {
                            do {
                                try AlarmManager.shared.stop(id: alarmKitUuid)
                                AppLogger.alarm.info("AlarmKit: stopped snooze alarm after AudioService takeover")
                            } catch { }
                        }
                    }
                }
                NotificationCenter.default.post(name: .alarmDidFire, object: nil, userInfo: [
                    "alarmId": reverseBaseId,
                    "alarmKit": true
                ])
                return
            }
        }
        AppLogger.alarm.warning("AlarmKit: alerting but alarm not found in CoreData for \(alarmKitIdStr, privacy: .public)")
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
