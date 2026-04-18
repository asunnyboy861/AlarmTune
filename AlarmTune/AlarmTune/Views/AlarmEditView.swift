import SwiftUI

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AlarmViewModel

    let alarm: AlarmItem?

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
    @State private var showSoundPicker = false

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
        }
    }

    var body: some View {
        NavigationView {
            Form {
                timeSection
                labelSection
                volumeSection
                soundSection
                optionsSection
                categorySection
            }
            .navigationTitle(alarm == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAlarm() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerView(selectedSound: $soundName)
                    .presentationDetents([.medium])
            }
        }
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
        } header: {
            Text("Time")
        }
    }

    private var labelSection: some View {
        Section {
            TextField("Alarm Label", text: $label)
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
                    Text(soundName)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
        } header: {
            Text("Sound")
        }
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

    private func saveAlarm() {
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
                category: category.isEmpty ? nil : category
            )
        }

        dismiss()
    }
}
