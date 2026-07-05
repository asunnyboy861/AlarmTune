import SwiftUI
import AVKit

/// 闹钟组合预览组件（V4）
///
/// 同时播放视频背景+铃声，让用户在保存前确认整体效果
/// 5 秒后自动关闭，或用户手动点击 Stop Preview 关闭
struct AlarmPreviewView: View {
    let videoName: String
    let videoVolume: Float
    let soundName: String
    let soundVolume: Float
    var audioSource: AppConstants.AudioSource = .alarmSound  // W1 新增

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var countdown = 5

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            // 视频预览窗口
            VideoPlayer(player: player)
                .frame(height: videoHeight)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius))
                .padding(.horizontal)

            // 铃声信息
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.accentColor)
                Text(displaySoundName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(soundVolume * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)

            // 倒计时
            Text("Preview: \(countdown)s")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Stop Preview") {
                stopAndDismiss()
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 8)
        }
        .padding(.top, 20)
        .onAppear {
            startPreview()
        }
        .onDisappear {
            // P1 fix: 确保用户下滑关闭 sheet 时也停止音频和视频
            stopAndDismiss()
        }
        .onReceive(timer) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                stopAndDismiss()
            }
        }
    }

    private var videoHeight: CGFloat {
        horizontalSizeClass == .regular ? 280 : 220
    }

    private var displaySoundName: String {
        if soundName.hasPrefix("imported:") {
            return String(soundName.dropFirst("imported:".count))
        } else if soundName.hasPrefix("appleMusic:") {
            return "Apple Music"
        }
        return soundName
    }

    private func startPreview() {
        // 1. 播放视频
        if let url = resolveVideoURL() {
            let item = AVPlayerItem(url: url)
            let queuePlayer = AVQueuePlayer(playerItem: item)
            // W1/W3：根据 audioSource 决定是否播放视频原声
            // 注意：AVPlayer.volume 在 iOS 上无效，预览时视频原声以系统音量播放
            if audioSource == .videoSound {
                queuePlayer.isMuted = false
            } else {
                queuePlayer.isMuted = true
            }
            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            queuePlayer.play()
            player = queuePlayer
        }

        // 2. 播放铃声（仅 alarmSound 模式）
        if audioSource != .videoSound {
            AudioService.shared.previewSound(soundName: soundName, volume: soundVolume)
        }
    }

    private func stopAndDismiss() {
        player?.pause()
        player = nil
        looper = nil
        if AudioService.shared.isPlaying {
            AudioService.shared.stopAlarm()
        }
        dismiss()
    }

    private func resolveVideoURL() -> URL? {
        if videoName.hasPrefix("videoBuiltIn:") {
            let name = String(videoName.dropFirst("videoBuiltIn:".count))
            return VideoBackgroundService.shared.urlForVideo(name)
        } else if videoName.hasPrefix("videoImported:") {
            let name = String(videoName.dropFirst("videoImported:".count))
            let mp4URL = VideoImportService.shared.importedDir.appendingPathComponent("\(name).mp4")
            if FileManager.default.fileExists(atPath: mp4URL.path) { return mp4URL }
            let movURL = VideoImportService.shared.importedDir.appendingPathComponent("\(name).mov")
            if FileManager.default.fileExists(atPath: movURL.path) { return movURL }
            return mp4URL
        }
        return nil
    }
}
