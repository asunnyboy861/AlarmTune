import Foundation
import AVKit
import UIKit

/// 管理内置视频背景资源（M8.2）
///
/// 内置视频存放在 Bundle/Videos/ 目录，文件格式 .mp4
/// W2：视频带原始音轨，支持"视频原声"模式
final class VideoBackgroundService: ObservableObject {
    static let shared = VideoBackgroundService()

    /// 内置视频背景列表
    /// W2：替换为带音轨的高质量视频，按分类组织
    /// W4：每个视频带 duration 字段（秒），用于 UI 显示
    @Published var builtInVideos: [VideoBackgroundInfo] = [
        // Storm（戏剧性最高 — 强制唤醒）
        VideoBackgroundInfo(id: "thunder", title: "Thunder Lightning", videoName: "thunder",
                           category: .storm, hasAudioTrack: true, duration: 24),
        VideoBackgroundInfo(id: "oceancrash", title: "Ocean Crash", videoName: "oceancrash",
                           category: .storm, hasAudioTrack: true, duration: 25),
        // Nature（自然力量 — 沉浸唤醒）
        VideoBackgroundInfo(id: "waterfall", title: "Waterfall Rush", videoName: "waterfall",
                           category: .nature, hasAudioTrack: true, duration: 25),
        VideoBackgroundInfo(id: "forest", title: "Forest Morning", videoName: "forest",
                           category: .nature, hasAudioTrack: true, duration: 24),
        // City（都市节奏 — 脉冲唤醒）
        VideoBackgroundInfo(id: "citylights", title: "City Lights", videoName: "citylights",
                           category: .city, hasAudioTrack: true, duration: 15),
        VideoBackgroundInfo(id: "rainwindow", title: "Rain Window", videoName: "rainwindow",
                           category: .city, hasAudioTrack: true, duration: 22),
        // Cozy（治愈温馨 — 渐进唤醒）
        VideoBackgroundInfo(id: "coffeebrew", title: "Coffee Brew", videoName: "coffeebrew",
                           category: .cozy, hasAudioTrack: true, duration: 14),
        VideoBackgroundInfo(id: "fireplace", title: "Fireplace Crackle", videoName: "fireplace",
                           category: .cozy, hasAudioTrack: true, duration: 7),
    ]

    private init() {}

    /// 获取内置视频文件 URL
    func urlForVideo(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp4", subdirectory: "Videos")
            ?? Bundle.main.url(forResource: name, withExtension: "mp4")
    }

    /// 为所有内置视频生成缩略图（从 AVAssetImageGenerator 提取首帧）
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

    /// 从视频 URL 生成缩略图 Data（统一 320x180 16:9）
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

/// 视频背景分类（W4 新增）
/// 与 SoundCategory 风格对齐：rawValue 为显示名、icon 为 SF Symbol
enum VideoCategory: String, CaseIterable, Identifiable {
    case storm = "Storm"      // 暴风雨（戏剧性最高）
    case nature = "Nature"    // 自然
    case city = "City"        // 城市
    case cozy = "Cozy"        // 温馨

    var id: String { rawValue }
    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .storm:   return "cloud.bolt.fill"
        case .nature:  return "leaf.fill"
        case .city:    return "building.2.fill"
        case .cozy:    return "flame.fill"
        }
    }

    var tint: String {
        switch self {
        case .storm:   return "purple"
        case .nature:  return "green"
        case .city:    return "blue"
        case .cozy:    return "orange"
        }
    }
}

/// 内置视频背景信息
struct VideoBackgroundInfo: Identifiable, Hashable {
    let id: String              // 唯一标识，用于 videoBuiltIn:{id}
    let title: String           // 显示名
    let videoName: String       // Bundle 中的文件名（不含扩展名）
    var thumbnailData: Data?    // 懒加载缩略图
    let category: VideoCategory // W4：视频分类
    let hasAudioTrack: Bool     // W4：是否有音轨
    let duration: TimeInterval  // W4：视频时长（秒），用于 UI 显示

    /// 时长格式化为 "0:15" 形式
    var durationText: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
