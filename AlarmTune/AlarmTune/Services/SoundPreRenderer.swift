// Services/SoundPreRenderer.swift
// R8: 声音预渲染服务
// 职责：在用户设置闹钟时，将铃声+音量+fade-in 渲染为 .caf 文件存入 Library/Sounds/
// 目的：App 被杀后，UNNotificationSound 仍能播放正确的铃声和音量
// 限制：不支持 Apple Music（DRM 保护）；通知声音最长 30 秒（循环播放）
// 原理：UNNotificationSound(named:) 支持 Library/Sounds/ 目录中的 .caf 文件

import Foundation
import AVFoundation
import os.log

final class SoundPreRenderer {

    static let shared = SoundPreRenderer()

    /// 通知声音最大时长（秒），超过会截断
    private let maxNotificationSoundDuration: TimeInterval = 29.0

    /// Library/Sounds 目录
    private var soundsDirectory: URL {
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return libraryDir.appendingPathComponent("Sounds", isDirectory: true)
    }

    private init() {
        ensureSoundsDirectory()
    }

    // MARK: - Public

    /// 渲染闹钟铃声到 Library/Sounds/
    /// 在闹钟保存/更新时调用，确保 App 被杀后通知仍能播放正确铃声+音量
    /// - Parameter alarm: 闹钟对象
    /// - Returns: 预渲染文件名（用于 UNNotificationSound），nil 表示渲染失败
    @discardableResult
    func render(for alarm: AlarmItem) -> String? {
        let soundName = alarm.wrappedSoundName
        let source = AppConstants.Sound.source(for: soundName)

        // Apple Music 受 DRM 保护，无法提取音频数据
        guard source != .appleMusic else {
            AppLogger.audio.warning("PreRenderer: skip Apple Music sound \(soundName, privacy: .public) (DRM)")
            return nil
        }

        // 获取原始铃声文件 URL
        guard let sourceURL = AudioService.shared.urlForSound(soundName) else {
            AppLogger.audio.error("PreRenderer: source sound not found \(soundName, privacy: .public)")
            return nil
        }

        let alarmId = alarm.wrappedId
        let outputFileName = "alarm_\(alarmId).caf"
        let outputURL = soundsDirectory.appendingPathComponent(outputFileName)

        // 删除旧的预渲染文件
        removeFile(at: outputURL)

        // 读取原始音频
        guard let originalFile = try? AVAudioFile(forReading: sourceURL) else {
            AppLogger.audio.error("PreRenderer: failed to read source audio")
            return nil
        }

        let originalFormat = originalFile.processingFormat
        let frameCount = AVAudioFrameCount(originalFile.length)

        guard let originalBuffer = AVAudioPCMBuffer(pcmFormat: originalFormat, frameCapacity: frameCount) else {
            AppLogger.audio.error("PreRenderer: failed to create PCM buffer")
            return nil
        }

        do {
            try originalFile.read(into: originalBuffer)
        } catch {
            AppLogger.audio.error("PreRenderer: failed to read audio data: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        // 截断到 29 秒（通知声音限制）
        let sampleRate = originalFormat.sampleRate
        let maxFrames = AVAudioFrameCount(maxNotificationSoundDuration * sampleRate)
        let trimmedBuffer: AVAudioPCMBuffer
        if originalBuffer.frameLength > maxFrames {
            trimmedBuffer = originalBuffer
            trimmedBuffer.frameLength = maxFrames
        } else {
            trimmedBuffer = originalBuffer
        }

        // 应用音量增益
        applyVolumeGain(buffer: trimmedBuffer, volume: alarm.volume)

        // 应用 fade-in（如果启用）
        if alarm.isFadeIn && alarm.fadeInDuration > 0 {
            let fadeInFrames = AVAudioFrameCount(min(alarm.fadeInDuration, maxNotificationSoundDuration) * sampleRate)
            applyFadeIn(buffer: trimmedBuffer, fadeInFrames: fadeInFrames, targetVolume: alarm.volume)
        }

        // 写入 .caf 文件
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                          sampleRate: originalFormat.sampleRate,
                                          channels: originalFormat.channelCount,
                                          interleaved: false)!

        guard let convertedBuffer = convertBuffer(trimmedBuffer, to: outputFormat) else {
            AppLogger.audio.error("PreRenderer: buffer conversion failed")
            return nil
        }

        do {
            let outputFile = try AVAudioFile(forWriting: outputURL,
                                              settings: outputFormat.settings,
                                              commonFormat: outputFormat.commonFormat,
                                              interleaved: outputFormat.isInterleaved)
            try outputFile.write(from: convertedBuffer)
            AppLogger.audio.info("PreRenderer: rendered \(outputFileName, privacy: .public) (\(convertedBuffer.frameLength) frames, vol=\(alarm.volume, privacy: .public))")
            return outputFileName
        } catch {
            AppLogger.audio.error("PreRenderer: failed to write file: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// 删除指定闹钟的预渲染文件
    /// 在闹钟删除时调用
    /// - Parameter alarmId: 闹钟 ID
    func removeFile(for alarmId: String) {
        let fileName = "alarm_\(alarmId).caf"
        let fileURL = soundsDirectory.appendingPathComponent(fileName)
        removeFile(at: fileURL)
        AppLogger.audio.info("PreRenderer: removed \(fileName, privacy: .public)")
    }

    /// 获取预渲染文件名（供 AlarmScheduler 使用）
    /// 如果文件存在则返回文件名，否则返回 nil
    /// - Parameter alarmId: 闹钟 ID
    /// - Returns: Library/Sounds/ 中的文件名
    func preRenderedFileName(for alarmId: String) -> String? {
        let fileName = "alarm_\(alarmId).caf"
        let fileURL = soundsDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return fileName
    }

    /// 清理所有预渲染文件（App 启动时可选调用，清理孤儿文件）
    func cleanupOrphanedFiles(activeAlarmIds: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: soundsDirectory,
                                                                         includingPropertiesForKeys: nil) else {
            return
        }

        for file in files {
            let name = file.lastPathComponent
            guard name.hasPrefix("alarm_") && name.hasSuffix(".caf") else { continue }

            // 提取 alarmId: alarm_{uuid}.caf -> {uuid}
            let alarmId = name
                .replacingOccurrences(of: "alarm_", with: "")
                .replacingOccurrences(of: ".caf", with: "")

            if !activeAlarmIds.contains(alarmId) {
                removeFile(at: file)
                AppLogger.audio.info("PreRenderer: cleaned orphaned file \(name, privacy: .public)")
            }
        }
    }

    // MARK: - Private

    private func ensureSoundsDirectory() {
        let dir = soundsDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func removeFile(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// 对 PCM buffer 应用音量增益（振幅缩放）
    /// volume 范围 0.0-1.0，直接缩放每个采样值
    private func applyVolumeGain(buffer: AVAudioPCMBuffer, volume: Float) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)

        for ch in 0..<channels {
            let data = channelData[ch]
            for i in 0..<frameLength {
                data[i] *= volume
            }
        }
    }

    /// 对 PCM buffer 应用 fade-in（线性渐入）
    /// 前 fadeInFrames 帧从 0 渐入到 targetVolume
    private func applyFadeIn(buffer: AVAudioPCMBuffer, fadeInFrames: AVAudioFrameCount, targetVolume: Float) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = Int(min(fadeInFrames, buffer.frameLength))
        let channels = Int(buffer.format.channelCount)

        for ch in 0..<channels {
            let data = channelData[ch]
            for i in 0..<frames {
                let progress = Float(i) / Float(frames)
                // fade-in 后的采样 = 原采样（已含 volume 增益）× fade progress
                data[i] *= progress
            }
        }
    }

    /// 将 buffer 转换为目标格式
    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            return nil
        }

        let frameCount = buffer.frameLength
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        outputBuffer.frameLength = frameCount

        var error: NSError?
        let inputBuffer = buffer
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if status == .error || error != nil {
            AppLogger.audio.error("PreRenderer: conversion failed: \(error?.localizedDescription ?? "unknown", privacy: .public)")
            return nil
        }

        return outputBuffer
    }
}
