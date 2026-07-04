import Foundation
import AVKit
import UIKit

/// 管理内置视频背景资源（M8.2）
/// 单例模式，与 VideoImportService 风格一致
///
/// 内置视频存放在 Bundle/Videos/ 目录，文件格式 .mp4
/// 视频应无声或可静音（App 会强制静音播放）
final class VideoBackgroundService: ObservableObject {
    static let shared = VideoBackgroundService()

    /// 内置视频背景列表
    /// V1：改为 var 以支持懒加载缩略图
    /// MVP 阶段先放入 Bundle；后续可迁移到 CDN 按需下载
    @Published var builtInVideos: [VideoBackgroundInfo] = [
        VideoBackgroundInfo(id: "sunrise", title: "Sunrise", videoName: "sunrise"),
        VideoBackgroundInfo(id: "coffee", title: "Morning Coffee", videoName: "coffee"),
        VideoBackgroundInfo(id: "ocean", title: "Ocean Waves", videoName: "ocean"),
        VideoBackgroundInfo(id: "forest", title: "Forest", videoName: "forest")
    ]

    private init() {}

    /// 获取内置视频文件 URL
    /// - Parameter name: 视频文件名（不含扩展名）
    /// - Returns: 视频 URL，找不到返回 nil
    func urlForVideo(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp4", subdirectory: "Videos")
            ?? Bundle.main.url(forResource: name, withExtension: "mp4")
    }

    /// 为所有内置视频生成缩略图（从 AVAssetImageGenerator 提取首帧）
    /// V1 新增：与 VideoImportService 共享缩略图尺寸 320x180（16:9）
    @MainActor
    func generateThumbnails() {
        for index in builtInVideos.indices {
            guard builtInVideos[index].thumbnailData == nil else { continue }
            guard let url = urlForVideo(builtInVideos[index].videoName) else { continue }

            Task { [weak self] in
                guard let self = self else { return }
                if let data = await Self.generateThumbnailData(from: url) {
                    await MainActor.run {
                        if index < self.builtInVideos.count {
                            self.builtInVideos[index].thumbnailData = data
                        }
                    }
                }
            }
        }
    }

    /// 从视频 URL 生成缩略图 Data（与 VideoImportService 共享逻辑和尺寸）
    /// V1：统一缩略图尺寸为 320x180（16:9），与视频原生比例一致
    static func generateThumbnailData(from url: URL, at time: CMTime = .zero) async -> Data? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 320, height: 180)

        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.7)
        } catch {
            return nil
        }
    }
}

/// 内置视频背景信息
struct VideoBackgroundInfo: Identifiable, Hashable {
    let id: String          // 唯一标识，用于 videoBuiltIn:{id}
    let title: String       // 显示名
    let videoName: String   // Bundle 中的文件名（不含扩展名）
    var thumbnailData: Data?  // V1 新增：懒加载缩略图
}
