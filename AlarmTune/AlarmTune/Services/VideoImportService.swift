import Foundation
import AVFoundation
import UIKit

/// 封装自定义视频背景的导入/管理（M8.2）
/// 单例模式，与 SoundImportService 风格一致
///
/// 视频存储目录：Documents/Videos/
/// 免费用户限 1 个自定义视频，Premium 用户无限
final class VideoImportService: ObservableObject {
    static let shared = VideoImportService()

    /// 免费用户自定义视频导入数量上限，防止绕过 Premium
    /// 与 SoundImportService.freeImportLimit 策略一致
    static let freeImportLimit: Int = 1

    @Published var importedVideos: [ImportedVideoInfo] = []

    struct ImportedVideoInfo: Identifiable, Hashable {
        let id: String              // "videoImported:{fileNameNoExt}"
        let displayName: String     // 文件名（去扩展名）
        let fileName: String        // 完整文件名（含扩展名）
        let fileSize: Int64
        let thumbnailImageData: Data?  // AVAssetImageGenerator 生成的首帧缩略图
    }

    /// 视频存储目录：Documents/Videos/
    let importedDir: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        importedDir = docs.appendingPathComponent("Videos", isDirectory: true)
        createDirectoryIfNeeded()
        refreshImportedVideos()
    }

    /// 当前用户是否还可以继续导入
    /// M7a 已实施：Premium 用户无限导入，免费用户限 1 个
    @MainActor
    var canImportMore: Bool {
        SubscriptionService.shared.isPremium || importedVideos.count < Self.freeImportLimit
    }

    var remainingFreeImports: Int {
        max(0, Self.freeImportLimit - importedVideos.count)
    }

    /// 从 URL 导入视频文件
    /// 视频已在 VideoTrimmerView 中截取，此处仅负责复制到 Videos/ 目录
    /// - Parameter sourceURL: 源视频 URL（已截取）
    /// - Returns: 导入后的 ImportedVideoInfo，失败返回 nil
    @discardableResult
    @MainActor
    func importVideo(from sourceURL: URL) -> ImportedVideoInfo? {
        guard canImportMore else { return nil }

        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let destFileName = "\(baseName).mp4"
        let destURL = importedDir.appendingPathComponent(destFileName)

        // 文件名冲突时追加序号
        var finalURL = destURL
        var counter = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            finalURL = importedDir.appendingPathComponent("\(baseName)_\(counter).mp4")
            counter += 1
        }

        guard sourceURL.startAccessingSecurityScopedResource() else { return nil }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        do {
            // 如果源是 .mov，转码为 .mp4；否则直接复制
            if sourceURL.pathExtension.lowercased() == "mp4" {
                try FileManager.default.copyItem(at: sourceURL, to: finalURL)
            } else {
                try transcodeToMP4(from: sourceURL, to: finalURL)
            }
            refreshImportedVideos()
            return importedVideos.first { $0.fileName == finalURL.lastPathComponent }
        } catch {
            print("Video import failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// 异步导入视频（避免转码阻塞主线程）
    @MainActor
    func importVideoAsync(from sourceURL: URL) async -> ImportedVideoInfo? {
        guard canImportMore else { return nil }

        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let destFileName = "\(baseName).mp4"
        let destURL = importedDir.appendingPathComponent(destFileName)

        // 文件名冲突时追加序号
        var finalURL = destURL
        var counter = 1
        while FileManager.default.fileExists(atPath: finalURL.path) {
            finalURL = importedDir.appendingPathComponent("\(baseName)_\(counter).mp4")
            counter += 1
        }

        guard sourceURL.startAccessingSecurityScopedResource() else { return nil }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        do {
            if sourceURL.pathExtension.lowercased() == "mp4" {
                try FileManager.default.copyItem(at: sourceURL, to: finalURL)
            } else {
                try await transcodeToMP4Async(from: sourceURL, to: finalURL)
            }
            refreshImportedVideos()
            return importedVideos.first { $0.fileName == finalURL.lastPathComponent }
        } catch {
            print("Video import failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// 删除导入的视频
    @discardableResult
    func deleteVideo(_ info: ImportedVideoInfo) -> Bool {
        let fileURL = importedDir.appendingPathComponent(info.fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
            refreshImportedVideos()
            return true
        } catch {
            print("Video delete failed: \(error.localizedDescription)")
            return false
        }
    }

    /// 刷新导入视频列表
    func refreshImportedVideos() {
        let allowedExtensions = Set(["mp4", "mov", "m4v"])
        let files = (try? FileManager.default.contentsOfDirectory(at: importedDir, includingPropertiesForKeys: [.fileSizeKey])) ?? []

        importedVideos = files.compactMap { url in
            let ext = url.pathExtension.lowercased()
            guard allowedExtensions.contains(ext) else { return nil }
            let name = url.deletingPathExtension().lastPathComponent
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            let thumbnail = generateThumbnail(for: url)

            return ImportedVideoInfo(
                id: "videoImported:\(name)",
                displayName: name,
                fileName: url.lastPathComponent,
                fileSize: Int64(size),
                thumbnailImageData: thumbnail
            )
        }
    }

    // MARK: - Private

    private func createDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: importedDir.path) {
            try? FileManager.default.createDirectory(at: importedDir, withIntermediateDirectories: true)
        }
    }

    /// 转码为 MP4（H.264 720p）
    private func transcodeToMP4(from source: URL, to dest: URL) throws {
        let asset = AVURLAsset(url: source)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
            try FileManager.default.copyItem(at: source, to: dest)
            return
        }
        exportSession.outputURL = dest
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        let semaphore = DispatchSemaphore(value: 0)
        exportSession.exportAsynchronously {
            semaphore.signal()
        }
        semaphore.wait()

        if exportSession.status != .completed {
            throw NSError(domain: "VideoImportService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Video transcode failed: \(exportSession.error?.localizedDescription ?? "unknown")"
            ])
        }
    }

    /// 异步转码为 MP4（避免阻塞主线程）
    private func transcodeToMP4Async(from source: URL, to dest: URL) async throws {
        let asset = AVURLAsset(url: source)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
            try FileManager.default.copyItem(at: source, to: dest)
            return
        }
        exportSession.outputURL = dest
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        await exportSession.export()

        if exportSession.status != .completed {
            throw NSError(domain: "VideoImportService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Video transcode failed: \(exportSession.error?.localizedDescription ?? "unknown")"
            ])
        }
    }

    /// 生成视频首帧缩略图
    private func generateThumbnail(for url: URL) -> Data? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 200, height: 200)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7)
        } catch {
            return nil
        }
    }
}
