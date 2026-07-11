import SwiftUI

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: AlarmViewModel

    let alarm: AlarmItem?

    // R5 新增：复用 VolumeMonitor 共享单例（继承 SettingsView 的模式）
    @ObservedObject private var volumeMonitor = VolumeMonitor.shared

    @State private var hour: Int = 7
    @State private var minute: Int = 0
    @State private var label: String = "Alarm"
    @State private var volume: Float = AppConstants.Alarm.defaultVolume
    @State private var soundName: String = AppConstants.Sound.defaultSound
    @State private var isFadeIn: Bool = false
    @State private var fadeInDuration: Double = AppConstants.Alarm.defaultFadeInDuration
    @State private var isVibrate: Bool = true
    @State private var isSnoozeEnabled: Bool = true
    @State private var snoozeDuration: Int = AppConstants.Alarm.defaultSnoozeMinutes
    @State private var category: String = ""
    @State private var repeatDays: [Int] = []
    @State private var showSoundPicker = false
    @State private var videoBackgroundName: String? = nil  // M8.2 新增
    @State private var showVideoPicker = false  // M8.2 新增
    @State private var videoVolume: Float = AppConstants.Alarm.defaultVideoVolume  // V3 新增
    @State private var showVideoPreview = false  // V4 新增
    @State private var audioSource: AppConstants.AudioSource = .alarmSound  // W1 新增

    init(viewModel: AlarmViewModel, alarm: AlarmItem? = nil) {
        self.viewModel = viewModel
        self.alarm = alarm

        if let alarm = alarm {
            _hour = State(initialValue: Int(alarm.hour))
            _minute = State(initialValue: Int(alarm.minute))
            _label = State(initialValue: alarm.wrappedLabel)
            _volume = State(initialValue: alarm.volume)
            _soundName = State(initialValue: alarm.wrappedSoundName)
            _isFadeIn = State(initialValue: alarm.isFadeIn)
            _fadeInDuration = State(initialValue: alarm.fadeInDuration)
            _isVibrate = State(initialValue: alarm.isVibrate)
            _isSnoozeEnabled = State(initialValue: alarm.isSnoozeEnabled)
            _snoozeDuration = State(initialValue: Int(alarm.snoozeDuration))
            _category = State(initialValue: alarm.wrappedCategory)
            _repeatDays = State(initialValue: alarm.repeatDays ?? [])
            _videoBackgroundName = State(initialValue: alarm.videoBackgroundName)  // M8.2
            // W5: 修复已有闹钟 videoVolume=0 导致播放无声；有视频但音量0时设为默认值
            let savedVideoVolume = alarm.videoVolume
            _videoVolume = State(initialValue: (alarm.videoBackgroundName != nil && savedVideoVolume <= 0)
                ? AppConstants.Alarm.defaultVideoVolume : savedVideoVolume)
            // W5: 有视频自动 videoSound，无视频自动 alarmSound（不再需要用户手动选择）
            _audioSource = State(initialValue: alarm.videoBackgroundName != nil ? .videoSound : .alarmSound)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                timeSection
                repeatSection
                labelSection
                volumeSection
                soundSection
                videoBackgroundSection  // M8.2 新增
                optionsSection
                categorySection
            }
            .navigationTitle(alarm == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveAlarm() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerView(selectedSound: $soundName, previewVolume: volume)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoBackgroundPickerView(
                    selectedVideo: $videoBackgroundName,
                    previewSoundName: $soundName,
                    previewVolume: $volume,
                    videoVolume: $videoVolume,
                    audioSource: $audioSource
                )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showVideoPreview) {
                if let videoName = videoBackgroundName {
                    AlarmPreviewView(
                        videoName: videoName,
                        videoVolume: videoVolume,
                        soundName: soundName,
                        soundVolume: volume,
                        audioSource: audioSource
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var timeSection: some View {
        Section {
            DatePicker("", selection: Binding(
                get: { Date.from(hour: hour, minute: minute) },
                set: { date in
                    hour = date.hour
                    minute = date.minute
                }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            .datePickerStyle(.wheel)
            .scaleEffect(datePickerScale)
        } header: {
            Text("Time")
        }
    }

    private var repeatSection: some View {
        Section {
            DayPickerView(selectedDays: $repeatDays)
        } header: {
            Text("Repeat")
        }
    }

    private var labelSection: some View {
        Section {
            TextField("Alarm Label", text: $label)
                .font(.system(size: labelFontSize))
        } header: {
            Text("Label")
        }
    }

    private var volumeSection: some View {
        Section {
            VolumeSliderView(volume: $volume) { vol in
                AudioService.shared.previewSound(soundName: soundName, volume: vol)
            }

            if isFadeIn {
                VStack(alignment: .leading) {
                    Text("Fade-in Duration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("\(Int(fadeInDuration))s")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 40)

                        Slider(value: $fadeInDuration, in: 1...30, step: 1)
                            .tint(.accentColor)
                    }
                }
            }

            // R5 新增：可靠性指示器（仅在不可靠时显示）
            let level = currentReliabilityLevel
            if let message = volumeMonitor.reliabilityMessage(for: level) {
                HStack(spacing: 8) {
                    Image(systemName: level.icon)
                        .foregroundColor(reliabilityColor(from: level.tint))
                        .font(.system(size: 14))
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        } header: {
            Text("Volume")
        }
    }

    private var soundSection: some View {
        Section {
            Button {
                showSoundPicker = true
            } label: {
                HStack {
                    Text("Sound")
                    Spacer()
                    Text(displaySoundName)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            .accessibilityIdentifier("soundPickerButton")
        } header: {
            Text("Sound")
        }
    }

    /// M8.2：视频背景选择菜单项
    /// 与 Sound 菜单项并列，符合 Alarmy 音视频分离架构
    /// V3：选择视频后显示视频音量滑块
    /// V4：添加组合预览按钮
    private var videoBackgroundSection: some View {
        Section {
            HStack {
                Button {
                    showVideoPicker = true
                } label: {
                    HStack {
                        Text("Video Background")
                        Spacer()
                        Text(displayVideoBackgroundName)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                .accessibilityIdentifier("videoPickerButton")

                // V4：组合预览按钮（仅在选择视频后显示）
                if videoBackgroundName != nil {
                    Button {
                        showVideoPreview = true
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.accentColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("videoPreviewButton")
                }
            }

            // V3：视频音量滑块（仅在选择视频后显示）
            // W5：选择视频后自动使用视频原声，无需手动选择音频来源
            if videoBackgroundName != nil {
                VolumeSliderView(volume: $videoVolume)
            }
        } header: {
            Text("Video Background")
        } footer: {
            if videoBackgroundName != nil {
                Text("Video Alarm: video plays with its own sound when alarm rings.")
                    .font(.caption2)
            } else {
                Text("Sound Alarm: alarm sound plays when alarm rings. Select a video to enable video alarm.")
                    .font(.caption2)
            }
        }
    }

    /// 用于 UI 显示的视频背景名：剥离前缀，nil 显示 "None"
    private var displayVideoBackgroundName: String {
        guard let name = videoBackgroundName else { return "None" }
        if name.hasPrefix("videoBuiltIn:") {
            let id = String(name.dropFirst("videoBuiltIn:".count))
            return VideoBackgroundService.shared.builtInVideos.first { $0.id == id }?.title ?? id
        } else if name.hasPrefix("videoImported:") {
            return String(name.dropFirst("videoImported:".count))
        }
        return name
    }

    private var optionsSection: some View {
        Section {
            Toggle("Fade In Volume", isOn: $isFadeIn)

            Toggle("Vibration", isOn: $isVibrate)

            Toggle("Snooze", isOn: $isSnoozeEnabled)

            if isSnoozeEnabled {
                Stepper("Snooze: \(snoozeDuration) min", value: $snoozeDuration, in: 1...30)
            }
        } header: {
            Text("Options")
        }
    }

    private var categorySection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        category = ""
                        HapticService.shared.selection()
                    } label: {
                        Label("None", systemImage: "xmark.circle")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(category.isEmpty ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundColor(category.isEmpty ? .accentColor : .secondary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    ForEach(AlarmItem.AlarmCategory.allCases, id: \.self) { cat in
                        Button {
                            category = cat.rawValue
                            HapticService.shared.selection()
                        } label: {
                            Label(cat.rawValue, systemImage: cat.icon)
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(category == cat.rawValue ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(category == cat.rawValue ? .accentColor : .secondary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } header: {
            Text("Category")
        }
    }

    /// 用于 UI 显示的铃声名：剥离 "imported:" / "appleMusic:" 前缀
    private var displaySoundName: String {
        if soundName.hasPrefix("imported:") {
            return String(soundName.dropFirst("imported:".count))
        } else if soundName.hasPrefix("appleMusic:") {
            return MusicLibraryService.shared.displayName(for: soundName) ?? "Apple Music Song"
        }
        return soundName
    }

    private func saveAlarm() {
        // P1 fix: 保存前停止任何正在播放的预览音频
        if AudioService.shared.isPlaying {
            AudioService.shared.stopAlarm()
        }

        // W5：保存前确保 audioSource 与视频状态一致（有视频=videoSound，无视频=alarmSound）
        audioSource = videoBackgroundName != nil ? .videoSound : .alarmSound

        if let existingAlarm = alarm {
            existingAlarm.hour = Int16(hour)
            existingAlarm.minute = Int16(minute)
            existingAlarm.label = label
            existingAlarm.volume = volume
            existingAlarm.soundName = soundName
            existingAlarm.isFadeIn = isFadeIn
            existingAlarm.fadeInDuration = fadeInDuration
            existingAlarm.isVibrate = isVibrate
            existingAlarm.isSnoozeEnabled = isSnoozeEnabled
            existingAlarm.snoozeDuration = Int16(snoozeDuration)
            existingAlarm.category = category.isEmpty ? nil : category
            existingAlarm.repeatDays = repeatDays.isEmpty ? nil : repeatDays
            existingAlarm.videoBackgroundName = videoBackgroundName  // M8.2
            existingAlarm.videoVolume = videoVolume  // V3
            existingAlarm.audioSource = audioSource.rawValue  // W1
            viewModel.updateAlarm(existingAlarm)
        } else {
            _ = viewModel.addAlarm(
                hour: hour,
                minute: minute,
                label: label,
                volume: volume,
                soundName: soundName,
                isFadeIn: isFadeIn,
                fadeInDuration: fadeInDuration,
                isVibrate: isVibrate,
                isSnoozeEnabled: isSnoozeEnabled,
                snoozeDuration: snoozeDuration,
                category: category.isEmpty ? nil : category,
                repeatDays: repeatDays.isEmpty ? nil : repeatDays,
                videoBackgroundName: videoBackgroundName,  // M8.2
                videoVolume: videoVolume,  // V3
                audioSource: audioSource.rawValue  // W1
            )
        }

        dismiss()
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var datePickerScale: CGFloat {
        isPad ? 1.3 : 1.0
    }

    private var labelFontSize: CGFloat {
        isPad ? 18 : 16
    }

    // MARK: - R5: Reliability Indicator

    /// R5 新增：计算当前闹钟的可靠性等级
    /// 综合 AlarmKit 适配 + 后台保活开关 + 铃声来源 + 系统音量
    private var currentReliabilityLevel: AppConstants.Reliability.ReliabilityLevel {
        let isKeepAlive = UserDefaults.standard.object(forKey: AppConstants.Reliability.backgroundKeepAliveKey) as? Bool
            ?? AppConstants.Reliability.defaultBackgroundKeepAlive
        let hasVideo = !(videoBackgroundName ?? "").isEmpty
        return volumeMonitor.reliabilityLevel(
            for: volume,
            soundName: soundName,
            isBackgroundKeepAlive: isKeepAlive,
            hasVideoBackground: hasVideo
        )
    }

    /// R5 新增：颜色字符串转 Color（继承 SettingsView.volumeColor(from:) 模式）
    private func reliabilityColor(from colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        default: return .secondary
        }
    }
}
