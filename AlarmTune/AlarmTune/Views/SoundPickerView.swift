import SwiftUI

struct SoundPickerView: View {
    @Binding var selectedSound: String
    @State private var previewVolume: Float = 0.5

    private let sounds = AppConstants.Sound.builtInSounds

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alarm Sound")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            ForEach(sounds, id: \.self) { sound in
                Button {
                    selectedSound = sound
                    AudioService.shared.previewSound(soundName: sound, volume: previewVolume)
                    HapticService.shared.selection()
                } label: {
                    HStack {
                        Image(systemName: selectedSound == sound ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedSound == sound ? .accentColor : .secondary)

                        Text(sound)
                            .font(.body)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "play.circle")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedSound == sound ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
