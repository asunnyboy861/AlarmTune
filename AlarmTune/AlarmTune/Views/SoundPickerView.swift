import SwiftUI
import MediaPlayer

struct SoundPickerView: View {
    @Binding var selectedSound: String
    let previewVolume: Float

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showMusicPicker = false
    @State private var showDocumentPicker = false
    @State private var showImportLimitAlert = false
    @State private var showPaywall = false
    @State private var showAIGenerator = false  // M8.3 新增
    @State private var cachedAppleMusicSongs: [CachedSong] = []

    @ObservedObject private var importService = SoundImportService.shared
    @ObservedObject private var musicService = MusicLibraryService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared

    private let categories = AppConstants.Sound.SoundCategory.allCases
    private let builtInSounds = AppConstants.Sound.builtInSounds

    /// 包装缓存的 Apple Music 歌曲，使其符合 Identifiable
    struct CachedSong: Identifiable, Hashable {
        let key: String
        let name: String
        var id: String { key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: sectionSpacing) {
                    builtInSoundsSection
                    appleMusicSection
                    importedSection
                }
                .padding()
            }
            .navigationTitle("Alarm Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                refreshAppleMusicCache()
                MusicLibraryService.shared.checkAuthorization()
                SoundImportService.shared.refreshImportedSounds()
            }
            .sheet(isPresented: $showMusicPicker) {
                MusicPickerWrapper(selectedSound: $selectedSound)
                    .onDisappear { refreshAppleMusicCache() }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerWrapper { url in
                    if let soundId = SoundImportService.shared.importFile(from: url) {
                        selectedSound = soundId
                    } else if !SoundImportService.shared.canImportMore {
                        showImportLimitAlert = true
                    }
                }
            }
            .alert("Import Limit Reached", isPresented: $showImportLimitAlert) {
                Button("Upgrade to Premium") { showPaywall = true }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Free users can import up to \(SoundImportService.freeImportLimit) custom sound. Upgrade to Premium for unlimited imports.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showAIGenerator) {
                AIAlarmGeneratorView()
                    .onReceive(NotificationCenter.default.publisher(for: .aiSoundGenerated)) { notification in
                        if let soundId = notification.userInfo?["soundId"] as? String {
                            selectedSound = soundId
                            HapticService.shared.success()
                        }
                    }
            }
        }
    }

    private func refreshAppleMusicCache() {
        cachedAppleMusicSongs = MusicLibraryService.shared.cachedSongs().map { CachedSong(key: $0.key, name: $0.name) }
    }

    // MARK: - Built-in Sounds (by category)

    private var builtInSoundsSection: some View {
        VStack(alignment: .leading, spacing: categorySpacing) {
            ForEach(categories) { category in
                let soundsInCategory = builtInSounds.filter { $0.category == category }
                if !soundsInCategory.isEmpty {
                    SoundCategorySection(
                        category: category,
                        sounds: soundsInCategory,
                        selectedSound: selectedSound,
                        onSelect: { name in
                            selectedSound = name
                            HapticService.shared.selection()
                        },
                        onPlay: { name in
                            AudioService.shared.previewSound(soundName: name, volume: previewVolume)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Apple Music

    private var appleMusicSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .foregroundColor(.pink)
                Text("Apple Music")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if musicService.authorized {
                ForEach(cachedAppleMusicSongs) { song in
                    SoundRow(
                        name: song.name,
                        isSelected: selectedSound == song.key,
                        onPlay: {
                            AudioService.shared.previewSound(soundName: song.key, volume: previewVolume)
                        },
                        onSelect: {
                            selectedSound = song.key
                            HapticService.shared.selection()
                        }
                    )
                }

                Button {
                    showMusicPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Choose from Music Library")
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.accentColor)
                }
            } else {
                Button {
                    MusicLibraryService.shared.requestAuthorization { granted in
                        if granted { showMusicPicker = true }
                    }
                } label: {
                    HStack {
                        Image(systemName: "music.note.list")
                        Text("Allow Music Library Access")
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Imported Sounds

    private var importedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.badge.plus")
                    .foregroundColor(.orange)
                Text("Imported Sounds")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ForEach(importService.importedSounds) { sound in
                SoundRow(
                    name: sound.displayName,
                    isSelected: selectedSound == sound.id,
                    onPlay: {
                        AudioService.shared.previewSound(soundName: sound.id, volume: previewVolume)
                    },
                    onSelect: {
                        selectedSound = sound.id
                        HapticService.shared.selection()
                    }
                )
                .contextMenu {
                    Button(role: .destructive) {
                        _ = SoundImportService.shared.deleteSound(sound)
                        if selectedSound == sound.id {
                            selectedSound = AppConstants.Sound.defaultSound
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if importService.canImportMore {
                Button {
                    showDocumentPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Import from Files")
                        if !subscriptionService.isPremium {
                            Text("(\(importService.remainingFreeImports) left)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.accentColor)
                }
            } else {
                // 免费用户配额已满，显示升级按钮
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.yellow)
                        Text("Upgrade for unlimited imports")
                            .font(.system(size: 15))
                            .foregroundColor(.accentColor)
                    }
                }
            }

            // M8.3：AI 生成铃声入口
            // AI 生成会写入 ImportedSounds 目录，因此受导入配额限制
            if importService.canImportMore {
                Button {
                    showAIGenerator = true
                    HapticService.shared.light()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Generate with AI")
                        if !subscriptionService.isPremium {
                            Text("(\(importService.remainingFreeImports) left)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.purple)
                }
            } else {
                // 配额已满，显示升级按钮
                Button {
                    showPaywall = true
                    HapticService.shared.light()
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.yellow)
                        Text("Upgrade for AI Generation")
                            .font(.system(size: 15))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
    }

    private var sectionSpacing: CGFloat { horizontalSizeClass == .regular ? 24 : 20 }
    private var categorySpacing: CGFloat { horizontalSizeClass == .regular ? 20 : 16 }
}

/// 分类 Section — 每个分类的标题 + 铃声列表
private struct SoundCategorySection: View {
    let category: AppConstants.Sound.SoundCategory
    let sounds: [AppConstants.Sound.SoundInfo]
    let selectedSound: String
    let onSelect: (String) -> Void
    let onPlay: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .foregroundColor(tint)
                Text(category.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            ForEach(sounds) { sound in
                SoundRow(
                    name: sound.displayName,
                    isSelected: selectedSound == sound.displayName,
                    onPlay: { onPlay(sound.displayName) },
                    onSelect: { onSelect(sound.displayName) }
                )
            }
        }
    }

    private var tint: Color {
        switch category.tint {
        case "red":    return .red
        case "green":  return .green
        case "blue":   return .blue
        case "orange": return .orange
        case "purple": return .purple
        default:       return .secondary
        }
    }
}
