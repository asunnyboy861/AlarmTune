import SwiftUI

struct AlarmRowView: View {
    let alarm: AlarmItem
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(alarm.formattedTime)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(alarm.isEnabled ? .primary : .secondary)

                    if !alarm.wrappedCategory.isEmpty {
                        Image(systemName: categoryIcon(alarm.wrappedCategory))
                            .font(.caption)
                            .foregroundColor(categoryColor(alarm.wrappedCategory))
                    }
                }

                HStack(spacing: 8) {
                    Text(alarm.wrappedLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if alarm.isFadeIn {
                        Label("Fade In", systemImage: "waveform.path")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                }

                volumeIndicator
            }

            Spacer()

            VStack(spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(.accentColor)

                Text("\(alarm.volumePercentage)%")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.6)
    }

    private var volumeIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Float(index) < alarm.volume * 5 ? Color.accentColor : Color.gray.opacity(0.2))
                    .frame(width: 4, height: 6 + CGFloat(index) * 2)
            }
        }
    }

    private func categoryIcon(_ category: String) -> String {
        AlarmItem.AlarmCategory(rawValue: category)?.icon ?? "alarm.fill"
    }

    private func categoryColor(_ category: String) -> Color {
        switch AlarmItem.AlarmCategory(rawValue: category)?.color {
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "indigo": return .indigo
        case "green": return .green
        default: return .accentColor
        }
    }
}
