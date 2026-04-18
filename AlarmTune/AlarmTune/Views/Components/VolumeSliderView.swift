import SwiftUI

struct VolumeSliderView: View {
    @Binding var volume: Float
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var onPreview: ((Float) -> Void)?

    private let presets: [(name: String, icon: String, value: Float)] = [
        ("Whisper", "speaker.fill", 0.15),
        ("Gentle", "speaker.wave.1.fill", 0.30),
        ("Moderate", "speaker.wave.2.fill", 0.55),
        ("Loud", "speaker.wave.3.fill", 0.80),
        ("Max", "speaker.wave.3.fill", 1.0)
    ]

    var body: some View {
        VStack(spacing: volumeSpacing) {
            HStack {
                Text("Volume")
                    .font(.system(size: labelFontSize))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.system(size: percentageFontSize, weight: .semibold))
                    .foregroundColor(volumeColor)
            }

            Slider(value: $volume, in: 0...1, step: 0.01) {
                Text("Volume")
            } minimumValueLabel: {
                Image(systemName: "speaker.fill")
                    .font(.system(size: sliderIconSize))
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: sliderIconSize))
                    .foregroundColor(.secondary)
            }
            .tint(volumeColor)
            .scaleEffect(sliderScale)
            .onChange(of: volume) {
                HapticService.shared.selection()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: presetSpacing) {
                    ForEach(presets, id: \.name) { preset in
                        Button {
                            volume = preset.value
                            onPreview?(preset.value)
                        } label: {
                            VStack(spacing: presetVSpacing) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: presetIconSize))
                                Text(preset.name)
                                    .font(.system(size: presetTextSize))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, presetPaddingVertical)
                            .padding(.horizontal, presetPaddingHorizontal)
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
                            .cornerRadius(AppConstants.Layout.cardCornerRadius)
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
                        .font(.system(size: previewFontSize))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var volumeSpacing: CGFloat {
        isPad ? 16 : 12
    }

    private var labelFontSize: CGFloat {
        isPad ? 16 : 14
    }

    private var percentageFontSize: CGFloat {
        isPad ? 18 : 14
    }

    private var sliderIconSize: CGFloat {
        isPad ? 16 : 12
    }

    private var sliderScale: CGFloat {
        isPad ? 1.2 : 1.0
    }

    private var presetSpacing: CGFloat {
        isPad ? 12 : 8
    }

    private var presetVSpacing: CGFloat {
        isPad ? 6 : 4
    }

    private var presetIconSize: CGFloat {
        isPad ? 18 : 12
    }

    private var presetTextSize: CGFloat {
        isPad ? 13 : 10
    }

    private var presetPaddingVertical: CGFloat {
        isPad ? 12 : 8
    }

    private var presetPaddingHorizontal: CGFloat {
        isPad ? 10 : 6
    }

    private var previewFontSize: CGFloat {
        isPad ? 16 : 12
    }

    private var volumeColor: Color {
        if volume < 0.25 { return .blue }
        if volume < 0.5 { return .green }
        if volume < 0.75 { return .orange }
        return .red
    }
}
