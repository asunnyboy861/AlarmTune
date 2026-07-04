import SwiftUI
import PhotosUI

/// 视频背景选择器（M8.2，独立页面）
///
/// 参考竞品分析结论：音视频分离架构，符合 Alarmy #1 最佳实践
/// 三种来源：无背景（默认）/ 内置视频 / 导入视频（相册 + Files）
struct VideoBackgroundPickerView: View {
    @Binding var selectedVideo: String?  // nil = 无视频背景

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showDocumentPicker = false
    @State private var showTrimmer = false
    @State private var pickedVideoURL: URL?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPaywall = false

    @ObservedObject private var importService = VideoImportService.shared
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
                    Button("Done") { dismiss() }
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
                            _ = VideoImportService.shared.importVideo(from: trimmedURL)
                            VideoImportService.shared.refreshImportedVideos()
                            pickedVideoURL = nil
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
        }
    }

    // MARK: - No Background

    private var noBackgroundSection: some View {
        Button {
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
                    ForEach(VideoBackgroundService.shared.builtInVideos) { video in
                        BuiltInVideoCard(
                            video: video,
                            isSelected: selectedVideo == "videoBuiltIn:\(video.id)",
                            onSelect: {
                                selectedVideo = "videoBuiltIn:\(video.id)"
                                HapticService.shared.selection()
                                dismiss()
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
                    onSelect: {
                        selectedVideo = video.id
                        HapticService.shared.selection()
                        dismiss()
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

    // MARK: - Photo Selection

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            do {
                // 将视频数据写入临时文件
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
private struct BuiltInVideoCard: View {
    let video: VideoBackgroundInfo
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: cardWidth, height: cardHeight)

                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue.opacity(0.6))

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
private struct ImportedVideoRow: View {
    let video: VideoImportService.ImportedVideoInfo
    let isSelected: Bool
    let onSelect: () -> Void
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
