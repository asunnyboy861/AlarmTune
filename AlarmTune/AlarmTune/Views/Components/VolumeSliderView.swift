import SwiftUI

struct VolumeSliderView: View {
    @Binding var volume: Float
    var onPreview: ((Float) -> Void)?

    private let presets: [(name: String, icon: String, value: Float)] = [
        ("Whisper", "speaker.fill", 0.15),
        ("Gentle", "speaker.wave.1.fill", 0.30),
        ("Moderate", "speaker.wave.2.fill", 0.55),
        ("Loud", "speaker.wave.3.fill", 0.80),
        ("Max", "speaker.wave.3.fill", 1.0)
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Volume")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(volumeColor)
            }

            Slider(value: $volume, in: 0...1, step: 0.01) {
                Text("Volume")
            } minimumValueLabel: {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .tint(volumeColor)
            .onChange(of: volume) {
                HapticService.shared.selection()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.name) { preset in
                        Button {
                            volume = preset.value
                            onPreview?(preset.value)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: preset.icon)
                                    .font(.caption)
                                Text(preset.name)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .background(
                                abs(volume - preset.value) < 0.02
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.gray.opacity(0.1)
                            )
                            .foregroundColor(
                                abs(volume - preset.value) < 0.02
                                    ? .accentColor
                                    : .secondary
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let onPreview = onPreview {
                Button {
                    onPreview(volume)
                } label: {
                    Label("Preview Volume", systemImage: "play.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var volumeColor: Color {
        if volume < 0.25 { return .blue }
        if volume < 0.5 { return .green }
        if volume < 0.75 { return .orange }
        return .red
    }
}
