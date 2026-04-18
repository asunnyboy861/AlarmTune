import SwiftUI

struct SoundPickerView: View {
    @Binding var selectedSound: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var previewVolume: Float = 0.5

    private let sounds = AppConstants.Sound.builtInSounds

    var body: some View {
        VStack(alignment: .leading, spacing: soundListSpacing) {
            Text("Alarm Sound")
                .font(.system(size: titleFontSize, weight: .medium))
                .foregroundColor(.secondary)

            ForEach(sounds, id: \.self) { sound in
                Button {
                    selectedSound = sound
                    AudioService.shared.previewSound(soundName: sound, volume: previewVolume)
                    HapticService.shared.selection()
                } label: {
                    HStack(spacing: soundRowSpacing) {
                        Image(systemName: selectedSound == sound ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: iconSize))
                            .foregroundColor(selectedSound == sound ? .accentColor : .secondary)

                        Text(sound)
                            .font(.system(size: soundFontSize))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "play.circle")
                            .font(.system(size: playIconSize))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, soundRowPaddingVertical)
                    .padding(.horizontal, soundRowPaddingHorizontal)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.largeCardCornerRadius)
                            .fill(selectedSound == sound ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var soundListSpacing: CGFloat {
        isPad ? 16 : 12
    }

    private var titleFontSize: CGFloat {
        isPad ? 18 : 15
    }

    private var soundRowSpacing: CGFloat {
        isPad ? 14 : 12
    }

    private var iconSize: CGFloat {
        isPad ? 24 : 20
    }

    private var soundFontSize: CGFloat {
        isPad ? 18 : 16
    }

    private var playIconSize: CGFloat {
        isPad ? 26 : 22
    }

    private var soundRowPaddingVertical: CGFloat {
        isPad ? 14 : 8
    }

    private var soundRowPaddingHorizontal: CGFloat {
        isPad ? 16 : 12
    }
}
