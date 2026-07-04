import SwiftUI
import PhotosUI
import AVKit

/// 视频背景选择器（M8.2，独立页面）
///
/// 参考竞品分析结论：音视频分离架构，符合 Alarmy #1 最佳实践
/// 三种来源：无背景（默认）/ 内置视频 / 导入视频（相册 + Files）
///
/// V1：内置视频卡片显示首帧缩略图（懒加载）
/// V2：视频卡片/行添加预览播放按钮，点击后同步播放视频+铃声 5 秒
struct VideoBackgroundPickerView: View {
    @Binding var selectedVideo: String?  // nil = 无视频背景

    /// V2 新增：外部传入当前铃声名和音量，预览时同步播放
    @Binding var previewSoundName: String
    @Binding var previewVolume: Float

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showDocumentPicker = false
    @State private var showTrimmer = false
    @State private var pickedVideoURL: URL?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPaywall = false

    // V2 预览状态
    @State private var previewingVideoId: String? = nil
    @State private var previewPlayer: AVQueuePlayer? = nil
    @State private var previewLooper: AVPlayerLooper? = nil
    @State private var previewTimer: Timer? = nil

    @ObservedObject private var importService = VideoImportService.shared
    @ObservedObject private var videoService = VideoBackgroundService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    noBackgroundSection
                    builtInVideosSection
                    importedVideosSection
                }
                .padding()
            }
            .navigationTitle("Video Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        stopPreview()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerWrapper { url in
                    pickedVideoURL = url
                    showTrimmer = true
                }
            }
            .sheet(isPresented: $showTrimmer) {
                if let url = pickedVideoURL {
                    VideoTrimmerView(
                        sourceURL: url,
                        onTrimmed: { trimmedURL in
                            Task {
                                if let imported = await VideoImportService.shared.importVideoAsync(from: trimmedURL) {
                                    selectedVideo = imported.id
                                }
                                VideoImportService.shared.refreshImportedVideos()
                                pickedVideoURL = nil
                            }
                        },
                        onCancel: {
                            pickedVideoURL = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                videoService.generateThumbnails()
            }
            .onDisappear {
                stopPreview()
            }
        }
    }

    // MARK: - No Background

    private var noBackgroundSection: some View {
        Button {
            stopPreview()
            selectedVideo = nil
            HapticService.shared.selection()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "nosign")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)

                Text("No Video Background")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                if selectedVideo == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 20))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Built-in Videos

    private var builtInVideosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles.tv")
                    .foregroundColor(.blue)
                Text("Built-in Videos")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(videoService.builtInVideos) { video in
                        BuiltInVideoCard(
                            video: video,
                            isSelected: selectedVideo == "videoBuiltIn:\(video.id)",
                            isPreviewing: previewingVideoId == "videoBuiltIn:\(video.id)",
                            onSelect: {
                                stopPreview()
                                selectedVideo = "videoBuiltIn:\(video.id)"
                                HapticService.shared.selection()
                                dismiss()
                            },
                            onPreview: {
                                togglePreview(videoId: "videoBuiltIn:\(video.id)")
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Imported Videos

    private var importedVideosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundColor(.orange)
                Text("My Videos")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ForEach(importService.importedVideos) { video in
                ImportedVideoRow(
                    video: video,
                    isSelected: selectedVideo == video.id,
                    isPreviewing: previewingVideoId == video.id,
                    onSelect: {
                        stopPreview()
                        selectedVideo = video.id
                        HapticService.shared.selection()
                        dismiss()
                    },
                    onPreview: {
                        togglePreview(videoId: video.id)
                    },
                    onDelete: { _ = importService.deleteVideo(video) }
                )
            }

            if importService.canImportMore {
                VStack(spacing: 10) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .videos) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Photos")
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.accentColor)
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        handlePhotoSelection(newItem)
                    }

                    Button {
                        showDocumentPicker = true
                        HapticService.shared.light()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Import from Files")
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.accentColor)
                    }

                    if !subscriptionService.isPremium {
                        Text("\(importService.remainingFreeImports) free import remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // 配额已满，显示升级按钮
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.yellow)
                        Text("Upgrade for unlimited videos")
                            .font(.system(size: 15))
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }

    // MARK: - V2 Preview

    /// 切换预览状态：未预览则开始，正在预览则停止
    private func togglePreview(videoId: String) {
        if previewingVideoId == videoId {
            stopPreview()
        } else {
            startPreview(videoId: videoId)
        }
    }

    /// 开始预览视频+铃声（5 秒自动停止）
    private func startPreview(videoId: String) {
        stopPreview()
        previewingVideoId = videoId

        // 1. 播放视频（静音，铃声由 AudioService 独立播放）
        guard let url = resolveVideoURL(videoId) else { return }
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: item)
        player.isMuted = true
        let looper = AVPlayerLooper(player: player, templateItem: item)
        player.play()
        previewPlayer = player
        previewLooper = looper

        // 2. 同步播放铃声
        AudioService.shared.previewSound(soundName: previewSoundName, volume: previewVolume)

        // 3. 5 秒后自动停止
        previewTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            stopPreview()
        }
    }

    /// 停止预览
    private func stopPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
        previewLooper = nil
        previewTimer?.invalidate()
        previewTimer = nil
        previewingVideoId = nil

        // 停止铃声预览
        if AudioService.shared.isPlaying {
            AudioService.shared.stopAlarm()
        }
    }

    /// 解析视频 URL（复用 VideoBackgroundView 的 resolvedURL 逻辑）
    private func resolveVideoURL(_ videoId: String) -> URL? {
        if videoId.hasPrefix("videoBuiltIn:") {
            let name = String(videoId.dropFirst("videoBuiltIn:".count))
            return VideoBackgroundService.shared.urlForVideo(name)
        } else if videoId.hasPrefix("videoImported:") {
            let name = String(videoId.dropFirst("videoImported:".count))
            let mp4URL = VideoImportService.shared.importedDir.appendingPathComponent("\(name).mp4")
            if FileManager.default.fileExists(atPath: mp4URL.path) { return mp4URL }
            let movURL = VideoImportService.shared.importedDir.appendingPathComponent("\(name).mov")
            if FileManager.default.fileExists(atPath: movURL.path) { return movURL }
            return mp4URL
        }
        return nil
    }

    // MARK: - Photo Selection

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            do {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).mov")
                if let data = try await item.loadTransferable(type: Data.self) {
                    try data.write(to: tempURL)
                    await MainActor.run {
                        pickedVideoURL = tempURL
                        showTrimmer = true
                    }
                }
            } catch {
                print("Photo selection failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Layout

    private var sectionSpacing: CGFloat { horizontalSizeClass == .regular ? 24 : 20 }
}

/// 内置视频卡片
/// V1：渲染首帧缩略图（降级显示图标）
/// V2：添加预览播放按钮
private struct BuiltInVideoCard: View {
    let video: VideoBackgroundInfo
    let isSelected: Bool
    let isPreviewing: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: cardWidth, height: cardHeight)

                    // V1：渲染缩略图，与 ImportedVideoRow 风格一致
                    if let data = video.thumbnailData,
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth, height: cardHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // 降级：无缩略图时显示图标
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }

                    // V2：预览播放按钮（底部居中，非选中态显示）
                    if !isSelected {
                        Button {
                            onPreview()
                            HapticService.shared.selection()
                        } label: {
                            Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2)
                        }
                        .buttonStyle(.plain)
                    }

                    // 选中态覆盖
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 3)
                            .frame(width: cardWidth, height: cardHeight)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(8)
                    }
                }

                Text(video.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private var cardWidth: CGFloat { horizontalSizeClass == .regular ? 160 : 130 }
    private var cardHeight: CGFloat { horizontalSizeClass == .regular ? 100 : 80 }
}

/// 导入视频行
/// V2：添加预览播放按钮
private struct ImportedVideoRow: View {
    let video: VideoImportService.ImportedVideoInfo
    let isSelected: Bool
    let isPreviewing: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    let onDelete: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 缩略图
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 56, height: 40)

                    if let data = video.thumbnailImageData,
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "video.fill")
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(video.displayName)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(formatFileSize(video.fileSize))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // V2：预览播放按钮（与 SoundRow 的 play 按钮风格一致）
                Button {
                    onPreview()
                    HapticService.shared.selection()
                } label: {
                    Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.accentColor.opacity(0.7))
                }
                .buttonStyle(.plain)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 20))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
