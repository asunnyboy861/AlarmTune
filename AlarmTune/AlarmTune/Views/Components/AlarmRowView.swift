import SwiftUI

struct AlarmRowView: View {
    let alarm: AlarmItem
    var onToggle: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: rowSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(alarm.formattedTime)
                        .font(.system(size: timeFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(alarm.isEnabled ? .primary : .secondary)

                    if !alarm.wrappedCategory.isEmpty {
                        Image(systemName: categoryIcon(alarm.wrappedCategory))
                            .font(.subheadline)
                            .foregroundColor(categoryColor(alarm.wrappedCategory))
                    }
                }

                HStack(spacing: 8) {
                    Text(alarm.wrappedLabel)
                        .font(.system(size: labelFontSize))
                        .foregroundColor(.secondary)

                    if alarm.isFadeIn {
                        Label("Fade In", systemImage: "waveform.path")
                            .font(.system(size: tagFontSize))
                            .foregroundColor(.accentColor)
                    }
                }

                volumeIndicator
            }

            Spacer()

            VStack(spacing: 10) {
                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(.accentColor)
                .scaleEffect(toggleScale)

                Text("\(alarm.volumePercentage)%")
                    .font(.system(size: volumeFontSize, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(rowPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.largeCardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(alarm.isEnabled ? 1.0 : 0.6)
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var timeFontSize: CGFloat {
        isPad ? 48 : 32
    }

    private var labelFontSize: CGFloat {
        isPad ? 20 : 14
    }

    private var tagFontSize: CGFloat {
        isPad ? 16 : 11
    }

    private var volumeFontSize: CGFloat {
        isPad ? 18 : 12
    }

    private var rowSpacing: CGFloat {
        isPad ? 32 : 16
    }

    private var rowPadding: CGFloat {
        isPad ? 28 : 16
    }

    private var toggleScale: CGFloat {
        isPad ? 1.5 : 1.0
    }

    private var volumeIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Float(index) < alarm.volume * 5 ? Color.accentColor : Color.gray.opacity(0.2))
                    .frame(width: volumeBarWidth, height: volumeBarHeight(index))
            }
        }
    }

    private var volumeBarWidth: CGFloat {
        isPad ? 6 : 4
    }

    private func volumeBarHeight(_ index: Int) -> CGFloat {
        let base: CGFloat = isPad ? 10 : 6
        let increment: CGFloat = isPad ? 4 : 2
        return base + CGFloat(index) * increment
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
