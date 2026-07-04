import Foundation
import AVKit

/// 管理内置视频背景资源（M8.2）
/// 单例模式，与 VideoBackgroundService 风格一致
///
/// 内置视频存放在 Bundle/Videos/ 目录，文件格式 .mp4
/// 视频应无声或可静音（App 会强制静音播放）
final class VideoBackgroundService: ObservableObject {
    static let shared = VideoBackgroundService()

    /// 内置视频背景列表
    /// MVP 阶段先放入 Bundle；后续可迁移到 CDN 按需下载
    let builtInVideos: [VideoBackgroundInfo] = [
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
}

/// 内置视频背景信息
struct VideoBackgroundInfo: Identifiable, Hashable {
    let id: String          // 唯一标识，用于 videoBuiltIn:{id}
    let title: String       // 显示名
    let videoName: String   // Bundle 中的文件名（不含扩展名）
}
