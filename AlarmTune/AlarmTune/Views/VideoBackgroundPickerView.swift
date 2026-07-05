import SwiftUI
import PhotosUI
import AVKit
import os.log

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

    /// W1 新增：视频音量绑定，videoSound 模式预览时使用此音量提升系统音量
    @Binding var videoVolume: Float

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// W1：音频来源绑定，选择视频后自动切换为 videoSound
    @Binding var audioSource: AppConstants.AudioSource

    @State private var showDocumentPicker = false
    @State private var showTrimmer = false
    @State private var pickedVideoURL: URL?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPaywall = false
    @State private var showImportError = false  // M12 新增：视频导入失败提示
    @State private var isImporting = false      // M12 新增：视频导入进度指示

    // V2 预览状态
    @State private var previewingVideoId: String? = nil
    @State private var previewPlayer: AVPlayer? = nil
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
                DocumentPickerWrapper(onPick: { url in
                    pickedVideoURL = url
                    showTrimmer = true
                }, contentTypes: [UTType.video])
            }
            .sheet(isPresented: $showTrimmer) {
                if let url = pickedVideoURL {
                    VideoTrimmerView(
                        sourceURL: url,
                        onTrimmed: { trimmedURL in
                            Task {
                                isImporting = true
                                let imported = await VideoImportService.shared.importVideoAsync(from: trimmedURL)
                                isImporting = false
                                if let imported = imported {
                                    selectedVideo = imported.id
                                } else {
                                    showImportError = true
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
            .alert("Import Failed", isPresented: $showImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to import video. Please try a different video or check available storage.")
            }
            .overlay {
                if isImporting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Importing video...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
                }
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
            audioSource = .alarmSound
            HapticService.shared.selection()
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

    /// W4：按 VideoCategory 分组显示，与 SoundCategorySection 风格对齐
    private var builtInVideosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles.tv")
                    .foregroundColor(.blue)
                Text("Built-in Videos")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ForEach(VideoCategory.allCases) { category in
                let videos = videoService.builtInVideos.filter { $0.category == category }
                if !videos.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // 分类标题（与 SoundCategorySection 风格一致）
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .foregroundColor(categoryTint(category))
                            Text(category.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        // 水平滚动视频卡片
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(videos) { video in
                                    BuiltInVideoCard(
                                        video: video,
                                        isSelected: selectedVideo == "videoBuiltIn:\(video.id)",
                                        isPreviewing: previewingVideoId == "videoBuiltIn:\(video.id)",
                                        previewPlayer: previewingVideoId == "videoBuiltIn:\(video.id)" ? previewPlayer : nil,
                                        onSelect: {
                                            stopPreview()
                                            selectedVideo = "videoBuiltIn:\(video.id)"
                                            // 选择带音轨的视频后自动切换为 videoSound
                                            if video.hasAudioTrack {
                                                audioSource = .videoSound
                                            }
                                            HapticService.shared.selection()
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
            }
        }
    }

    /// VideoCategory.tint 返回 String 颜色名，转为 Color
    private func categoryTint(_ category: VideoCategory) -> Color {
        switch category.tint {
        case "purple": return .purple
        case "green":  return .green
        case "blue":   return .blue
        case "orange": return .orange
        default:       return .accentColor
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

            // M12 新增：空状态说明
            if importService.importedVideos.isEmpty {
                Text("No imported videos yet. Tap below to import a video from Photos or Files.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }

            ForEach(importService.importedVideos) { video in
                ImportedVideoRow(
                    video: video,
                    isSelected: selectedVideo == video.id,
                    isPreviewing: previewingVideoId == video.id,
                    previewPlayer: previewingVideoId == video.id ? previewPlayer : nil,
                    onSelect: {
                        stopPreview()
                        selectedVideo = video.id
                        // 选择导入视频后默认切换为 videoSound（导入视频通常有音轨）
                        audioSource = .videoSound
                        HapticService.shared.selection()
                    },
                    onPreview: {
                        togglePreview(videoId: video.id)
                    },
                    onDelete: {
                        _ = importService.deleteVideo(video)
                        // P1 fix: 删除当前选中的视频时清除选择，避免悬空引用
                        if selectedVideo == video.id {
                            selectedVideo = nil
                        }
                    }
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
    /// 修复3个根因：
    /// 1. 不调用 stopAlarm()/deactivateAudioSession 避免 session 闪烁 → PlayerRemoteXPC err=-12785
    /// 2. 先赋值 previewPlayer 再延迟 play()，确保 SwiftUI VideoPlayer 视图已渲染
    /// 3. 用 AVPlayer 替代 AVQueuePlayer+AVPlayerLooper，5秒预览无需循环
    private func startPreview(videoId: String) {
        // 1. 清理上一个预览（不 deactivate session，避免闪烁）
        previewPlayer?.pause()
        previewPlayer = nil
        previewTimer?.invalidate()
        previewTimer = nil
        previewingVideoId = nil
        AudioService.shared.stopPreviewOnly()

        previewingVideoId = videoId

        // 2. 配置 AudioSession（仅首次或 session 失效时需要）
        _ = AudioService.shared.configureAudioSession()

        guard let url = resolveVideoURL(videoId) else { return }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)

        if audioSource == .videoSound {
            player.isMuted = false
            VolumeManager.shared.boostSystemVolume(to: videoVolume)
        } else {
            player.isMuted = true
        }

        // 3. 先赋值 previewPlayer，让 SwiftUI 创建 VideoPlayer 视图
        previewPlayer = player

        // 4. 延迟 play()，确保 SwiftUI 已渲染 VideoPlayer 视图
        DispatchQueue.main.async {
            player.play()
        }

        // 5. 播放铃声（alarmSound 模式，不重新配置 session）
        if audioSource == .alarmSound {
            AudioService.shared.previewSoundWithoutSessionConfig(soundName: previewSoundName, volume: previewVolume)
        }

        previewTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            self.stopPreview()
        }
    }

    /// 停止预览
    private func stopPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
        previewTimer?.invalidate()
        previewTimer = nil
        previewingVideoId = nil

        // 使用 stopPreviewOnly() 而非 stopAlarm()，避免 deactivateAudioSession 闪烁
        AudioService.shared.stopPreviewOnly()

        // videoSound 模式下恢复系统音量
        if VolumeManager.shared.isAlarmActive {
            VolumeManager.shared.restoreSystemVolume()
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
                AppLogger.video.error("Photo selection failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Layout

    private var sectionSpacing: CGFloat { horizontalSizeClass == .regular ? 24 : 20 }
}

/// 内置视频卡片
/// V4：用 InlineVideoPlayer 替代 SwiftUI VideoPlayer，解决 Button 内不渲染问题
/// V4：分离卡片点击和预览按钮，不再嵌套 Button
private struct BuiltInVideoCard: View {
    let video: VideoBackgroundInfo
    let isSelected: Bool
    let isPreviewing: Bool
    let previewPlayer: AVPlayer?
    let onSelect: () -> Void
    let onPreview: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: cardWidth, height: cardHeight)

                if isPreviewing, let player = previewPlayer {
                    InlineVideoPlayer(player: player)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .allowsHitTesting(false)
                } else if let data = video.thumbnailData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }

                // 预览播放/停止按钮（独立于卡片点击）
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
            .contentShape(Rectangle())
            .onTapGesture { onSelect() }

            Text(video.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            // W4：显示时长 + 音轨标识
            HStack(spacing: 4) {
                if video.hasAudioTrack {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                }
                Text(video.durationText)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var cardWidth: CGFloat { horizontalSizeClass == .regular ? 160 : 130 }
    private var cardHeight: CGFloat { horizontalSizeClass == .regular ? 100 : 80 }
}

/// 导入视频行
/// V4：用 InlineVideoPlayer 替代 SwiftUI VideoPlayer
/// V4：分离行点击和预览按钮
private struct ImportedVideoRow: View {
    let video: VideoImportService.ImportedVideoInfo
    let isSelected: Bool
    let isPreviewing: Bool
    let previewPlayer: AVPlayer?
    let onSelect: () -> Void
    let onPreview: () -> Void
    let onDelete: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: 12) {
            // 缩略图 / 预览视频
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 56, height: 40)

                if isPreviewing, let player = previewPlayer {
                    InlineVideoPlayer(player: player)
                        .frame(width: 56, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .allowsHitTesting(false)
                } else if let data = video.thumbnailImageData,
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

            // 预览播放按钮（独立于行点击）
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
        .onTapGesture { onSelect() }
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
