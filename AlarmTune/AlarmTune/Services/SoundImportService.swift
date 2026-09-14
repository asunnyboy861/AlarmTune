import Foundation
import UniformTypeIdentifiers
import os.log

/// I2 新增：音频导入失败原因分类
/// 风格继承 AudioFallbackReason（AudioService.swift），rawValue 为用户可读描述
/// 用于 UI 层展示精准错误提示，替代原有的"返回 nil + 通用弹窗"
enum SoundImportError: Error, LocalizedError {
    case unsupportedFormat(actualExtension: String)   // 格式不支持
    case securityScopeDenied                           // 无法访问文件（安全作用域）
    case copyFailed(reason: String)                    // 文件复制失败
    case quotaExceeded                                 // 免费用户配额已满

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            // 引用 I1 的格式描述常量，确保 UI 提示与实际支持列表一致
            return "Unsupported format: .\(ext). Supported formats: \(AppConstants.Sound.supportedAudioFormatDescription)."
        case .securityScopeDenied:
            return "Unable to access the selected file. Please try again or choose a different file."
        case .copyFailed(let reason):
            return "Failed to import audio file: \(reason)"
        case .quotaExceeded:
            return "Import limit reached. Free users can import up to \(SoundImportService.freeImportLimit) custom sound."
        }
    }
}

/// 封装自定义铃声的导入/列表/删除
/// 单例模式，与项目其他 Service 保持一致
final class SoundImportService: ObservableObject {
    static let shared = SoundImportService()

    /// 免费用户自定义导入数量上限，防止绕过 Premium 声声包
    static let freeImportLimit: Int = 1

    @Published var importedSounds: [ImportedSoundInfo] = []

    struct ImportedSoundInfo: Identifiable, Hashable {
        let id: String           // "imported:{fileNameNoExt}"
        let displayName: String  // 文件名（去扩展名）
        let fileName: String     // 完整文件名（含扩展名）
        let fileSize: Int64      // 文件大小
    }

    /// ImportedSounds 目录 URL（M8 AIGenerationService 需复用，故暴露）
    let importedDir: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        importedDir = docs.appendingPathComponent("ImportedSounds", isDirectory: true)
        createDirectoryIfNeeded()
        refreshImportedSounds()
    }

    /// 当前用户是否还可以继续导入
    /// M7a 已实施：Premium 用户无限导入，免费用户限 1 个
    @MainActor
    var canImportMore: Bool {
        SubscriptionService.shared.isPremium || importedSounds.count < Self.freeImportLimit
    }

    /// 距离免费配额上限还差几个
    var remainingFreeImports: Int {
        max(0, Self.freeImportLimit - importedSounds.count)
    }

    private func createDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: importedDir.path) {
            try? FileManager.default.createDirectory(at: importedDir, withIntermediateDirectories: true)
        }
    }

    /// 刷新导入铃声列表
    func refreshImportedSounds() {
        let allowedExtensions = AppConstants.Sound.supportedAudioExtensions
        let files = (try? FileManager.default.contentsOfDirectory(at: importedDir, includingPropertiesForKeys: [.fileSizeKey])) ?? []

        importedSounds = files.compactMap { url in
            let ext = url.pathExtension.lowercased()
            guard allowedExtensions.contains(ext) else { return nil }
            let name = url.deletingPathExtension().lastPathComponent
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return ImportedSoundInfo(
                id: "imported:\(name)",
                displayName: name,
                fileName: url.lastPathComponent,
                fileSize: Int64(size)
            )
        }
    }

    /// 从 URL 导入文件（DocumentPicker 回调）
    /// I2 修改：增加格式校验，不支持的格式直接返回 nil 并记录日志
    /// - Returns: 导入后的 soundId（格式 "imported:{fileNameNoExt}"），失败返回 nil
    /// - Note: 需要获取具体失败原因时使用 importFileWithError(from:)
    @MainActor
    func importFile(from url: URL) -> String? {
        // I2 修改：复用 Result 版本，保持原有签名向后兼容
        let result = importFileWithError(from: url)
        return try? result.get()
    }

    /// I2 新增：带错误分类的导入方法
    /// - Parameter url: DocumentPicker 返回的文件 URL
    /// - Returns: 成功返回 soundId，失败返回具体的 SoundImportError
    @MainActor
    func importFileWithError(from url: URL) -> Result<String, SoundImportError> {
        // 1. 配额检查
        guard canImportMore else { return .failure(.quotaExceeded) }

        // 2. I2 新增：格式校验（在复制前拦截不支持的格式，避免"复制成功但列表不显示"的断层）
        let ext = url.pathExtension.lowercased()
        guard !ext.isEmpty else {
            return .failure(.unsupportedFormat(actualExtension: "(none)"))
        }
        guard AppConstants.Sound.supportedAudioExtensions.contains(ext) else {
            AppLogger.importService.warning("Rejected unsupported format: .\(ext, privacy: .public)")
            return .failure(.unsupportedFormat(actualExtension: ext))
        }

        // 3. 文件名冲突处理（原逻辑保留）
        let baseName = url.deletingPathExtension().lastPathComponent
        var destURL = importedDir.appendingPathComponent(url.lastPathComponent)
        var counter = 1
        var finalBaseName = baseName
        while FileManager.default.fileExists(atPath: destURL.path) {
            finalBaseName = "\(baseName)_\(counter)"
            destURL = importedDir.appendingPathComponent("\(finalBaseName).\(ext)")
            counter += 1
        }

        // 4. 安全作用域处理（加固）：
        // DocumentPickerWrapper 使用 asCopy: true，此时 URL 指向临时副本，
        // Apple 文档明确不需要安全作用域。部分系统版本下 startAccessing
        // 可能返回 false，若直接报错会导致文件明明可选却被误判为失败。
        // 因此降级策略：startAccessing 返回 false 时仅记录日志，继续尝试直接复制；
        // 只有复制也失败时才返回 securityScopeDenied（复制失败优先归类为 copyFailed）。
        let didAccessScope = url.startAccessingSecurityScopedResource()
        if didAccessScope {
            defer { url.stopAccessingSecurityScopedResource() }
        } else {
            AppLogger.importService.notice("Security scope not granted (asCopy picker); attempting direct copy: \(url.lastPathComponent, privacy: .public)")
        }

        // 5. 复制文件（原逻辑保留，增加错误分类）
        do {
            try FileManager.default.copyItem(at: url, to: destURL)
            refreshImportedSounds()
            AppLogger.importService.info("Imported sound: \(finalBaseName, privacy: .public)")
            return .success("imported:\(finalBaseName)")
        } catch {
            AppLogger.importService.error("Import copy failed: \(error.localizedDescription, privacy: .public)")
            return .failure(.copyFailed(reason: error.localizedDescription))
        }
    }

    /// 删除导入的铃声
    func deleteSound(_ info: ImportedSoundInfo) -> Bool {
        let fileURL = importedDir.appendingPathComponent(info.fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
            refreshImportedSounds()
            return true
        } catch {
            AppLogger.importService.error("Delete failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
