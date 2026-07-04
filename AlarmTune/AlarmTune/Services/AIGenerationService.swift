import Foundation
import AVFoundation

/// AI 铃声生成服务（M8.3 MVP）
///
/// MVP 方案：设备端使用 AVAudioEngine 合成简单音调
/// 未来可替换为后端 API 调用（MusicGen / AudioLDM 等模型）
///
/// 生成结果保存到 SoundImportService.importedDir，复用 M5 导入铃声架构
final class AIGenerationService {
    static let shared = AIGenerationService()

    private init() {}

    /// AI 生成风格
    enum AIGenStyle: String, CaseIterable, Identifiable {
        case calm = "Calm"
        case energetic = "Energetic"
        case nature = "Nature"
        case retro = "Retro"

        var id: String { rawValue }

        var displayName: String { rawValue }

        var icon: String {
            switch self {
            case .calm:      return "leaf.fill"
            case .energetic: return "bolt.fill"
            case .nature:    return "tree.fill"
            case .retro:     return "music.mic"
            }
        }

        var description: String {
            switch self {
            case .calm:      return "Soft sine waves with gentle fade"
            case .energetic: return "Square waves with fast rhythm"
            case .nature:    return "Bird chirp pattern with harmonics"
            case .retro:     return "8-bit chiptune style melody"
            }
        }

        /// 基础频率
        var baseFrequency: Double {
            switch self {
            case .calm:      return 440.0   // A4
            case .energetic: return 660.0   // E5
            case .nature:    return 880.0   // A5
            case .retro:     return 523.0   // C5
            }
        }

        /// 波形类型
        var waveform: Waveform {
            switch self {
            case .calm:      return .sine
            case .energetic: return .square
            case .nature:    return .triangle
            case .retro:     return .sawtooth
            }
        }
    }

    enum Waveform {
        case sine, square, triangle, sawtooth
    }

    /// AI 生成错误
    enum AIGenError: LocalizedError {
        case importLimitReached

        var errorDescription: String? {
            switch self {
            case .importLimitReached:
                return "Import limit reached. Upgrade to Premium for unlimited tone generation."
            }
        }
    }

    /// 根据风格生成铃声并保存到 ImportedSounds 目录
    /// - Parameters:
    ///   - prompt: 用户输入的描述（MVP 阶段仅用于文件名，不影响生成）
    ///   - style: 生成风格
    /// - Returns: 生成的铃声 ID（格式 "imported:{fileNameNoExt}"），用于直接选中
    @discardableResult
    func generateSound(prompt: String, style: AIGenStyle) async throws -> String {
        // 检查导入配额（与 SoundImportService 一致）
        let canImport = await MainActor.run {
            SoundImportService.shared.canImportMore
        }
        guard canImport else {
            throw AIGenError.importLimitReached
        }

        let fileNameNoExt = "AI_\(sanitize(prompt))_\(UUID().uuidString.prefix(8))"
        let fileName = "\(fileNameNoExt).caf"
        let outputURL = SoundImportService.shared.importedDir.appendingPathComponent(fileName)

        // 生成 10 秒的音频
        let durationSec: Double = 10.0
        let sampleRate: Double = 44100
        let totalSamples = Int(durationSec * sampleRate)

        // 创建 AVAudioFile
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: sampleRate, channels: 1, interleaved: false) else {
            throw NSError(domain: "AIGenerationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio format"])
        }
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        let audioFile = try AVAudioFile(forWriting: outputURL, settings: settings)

        // 生成音频缓冲区
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)),
              let data = buffer.int16ChannelData else {
            throw NSError(domain: "AIGenerationService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate audio buffer"])
        }
        buffer.frameLength = AVAudioFrameCount(totalSamples)

        let channelData = data[0]
        let baseFreq = style.baseFrequency
        let waveform = style.waveform

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let envelope = computeEnvelope(at: t, duration: durationSec)
            let value: Double

            switch waveform {
            case .sine:
                value = sin(2.0 * .pi * baseFreq * t)
            case .square:
                value = sin(2.0 * .pi * baseFreq * t) >= 0 ? 1.0 : -1.0
            case .triangle:
                value = 2.0 / .pi * asin(sin(2.0 * .pi * baseFreq * t))
            case .sawtooth:
                let phase = baseFreq * t
                value = 2.0 * (phase - floor(phase + 0.5))
            }

            // 添加颤音效果（nature 风格）
            let finalValue: Double
            if style == .nature {
                let vibrato = 1.0 + 0.05 * sin(2.0 * .pi * 5.0 * t)  // 5Hz 颤音
                finalValue = value * vibrato
            } else {
                finalValue = value
            }

            // 应用包络并缩放到 16-bit 范围
            let sample = Int16(finalValue * envelope * 0.7 * Double(Int16.max))
            channelData[i] = sample
        }

        try audioFile.write(from: buffer)

        // 刷新导入铃声列表
        await MainActor.run {
            SoundImportService.shared.refreshImportedSounds()
        }

        // 返回 soundId，格式与 ImportedSoundInfo.id 一致
        return "imported:\(fileNameNoExt)"
    }

    /// 计算包络（ADSR：Attack-Decay-Sustain-Release）
    private func computeEnvelope(at t: Double, duration: Double) -> Double {
        let attackTime: Double = 0.1
        let releaseTime: Double = 0.5

        if t < attackTime {
            // Attack：0 → 1
            return t / attackTime
        } else if t > duration - releaseTime {
            // Release：1 → 0
            return max(0, (duration - t) / releaseTime)
        } else {
            // Sustain：1（简化版，无 Decay）
            return 1.0
        }
    }

    /// 清理文件名中的特殊字符
    private func sanitize(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        return text.unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "_" }
            .reduce("") { $0 + String($1) }
            .prefix(20)
            .description
    }
}
