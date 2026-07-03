import Foundation
import UniformTypeIdentifiers

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
    /// M5 阶段：所有用户统一按免费配额限制（1 个）
    /// M7 阶段：扩展为 `SubscriptionService.shared.isPremium || importedSounds.count < Self.freeImportLimit`
    var canImportMore: Bool {
        importedSounds.count < Self.freeImportLimit
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
        let allowedExtensions = Set(["mp3", "m4a", "wav", "aiff", "caf"])
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
    /// - Returns: true 导入成功；false 失败或超出配额
    func importFile(from url: URL) -> Bool {
        guard canImportMore else { return false }

        let fileName = url.lastPathComponent
        let destURL = importedDir.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destURL.path) {
            return false
        }

        guard url.startAccessingSecurityScopedResource() else { return false }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            try FileManager.default.copyItem(at: url, to: destURL)
            refreshImportedSounds()
            return true
        } catch {
            print("Import failed: \(error.localizedDescription)")
            return false
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
            print("Delete failed: \(error.localizedDescription)")
            return false
        }
    }
}
