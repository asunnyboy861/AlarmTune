import SwiftUI
import AVKit
import os.log

/// 响铃界面的视频背景播放组件（M8.2）
///
/// V3：支持 videoVolume 参数，0 = 静音，>0 = 按音量播放视频原声
/// W1/W3：支持 audioSource 参数，videoSound 模式下播放视频原声，alarmSound 模式下静音
/// 使用 AVPlayerLooper 实现无缝循环
struct VideoBackgroundView: View {
    let videoName: String  // 含前缀的完整标识
    let videoVolume: Float  // V3 新增：视频音量 0.0...1.0
    var audioSource: AppConstants.AudioSource = .alarmSound  // W1 新增：默认闹钟铃声模式

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
            AppLogger.video.error("VideoBackgroundView: URL not found for \(videoName, privacy: .public)")
            return
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)

        // W1/W3：根据 audioSource 决定音频播放策略
        // - alarmSound 模式：视频静音（闹钟铃声由 AudioService 播放）
        // - videoSound 模式：视频原声播放（闹钟铃声不播放）
        //   注意：AVPlayer.volume 在 iOS 上无效（仅 macOS），视频音量实际由
        //   AlarmScheduler 通过 VolumeManager.boostSystemVolume(to: videoVolume) 控制
        if audioSource == .videoSound {
            queuePlayer.isMuted = false
        } else {
            queuePlayer.isMuted = true
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
