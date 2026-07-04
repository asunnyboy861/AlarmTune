import SwiftUI
import AVKit

/// 响铃界面的视频背景播放组件（M8.2）
///
/// V3：支持 videoVolume 参数，0 = 静音，>0 = 按音量播放视频原声
/// 使用 AVPlayerLooper 实现无缝循环
struct VideoBackgroundView: View {
    let videoName: String  // 含前缀的完整标识
    let videoVolume: Float  // V3 新增：视频音量 0.0...1.0

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                setupPlayer()
                player?.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
                looper = nil
            }
    }

    private func setupPlayer() {
        guard let url = resolvedURL else {
            print("VideoBackgroundView: URL not found for \(videoName)")
            return
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)

        // V3：根据 videoVolume 决定是否静音
        if videoVolume <= 0 {
            queuePlayer.isMuted = true
        } else {
            queuePlayer.isMuted = false
            queuePlayer.volume = videoVolume
        }

        // AVPlayerLooper 实现无缝循环
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer
    }

    /// 根据 videoName 前缀解析 URL
    /// videoBuiltIn: → Bundle/Videos/
    /// videoImported: → Documents/Videos/
    private var resolvedURL: URL? {
        if videoName.hasPrefix("videoBuiltIn:") {
            let name = String(videoName.dropFirst("videoBuiltIn:".count))
            return VideoBackgroundService.shared.urlForVideo(name)
        } else if videoName.hasPrefix("videoImported:") {
            let name = String(videoName.dropFirst("videoImported:".count))
            // 尝试 .mp4 和 .mov
            let mp4URL = VideoImportService.shared.importedDir.appendingPathComponent("\(name).mp4")
            if FileManager.default.fileExists(atPath: mp4URL.path) {
                return mp4URL
            }
            let movURL = VideoImportService.shared.importedDir.appendingPathComponent("\(name).mov")
            if FileManager.default.fileExists(atPath: movURL.path) {
                return movURL
            }
            return mp4URL  // 返回默认，让 AVPlayer 处理错误
        }
        return nil
    }
}
