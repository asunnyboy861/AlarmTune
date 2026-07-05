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
                        .fixedFont(timeFontSize, weight: .bold, design: .rounded)
                        .foregroundColor(alarm.isEnabled ? .primary : .secondary)

                    if !alarm.wrappedCategory.isEmpty {
                        Image(systemName: categoryIcon(alarm.wrappedCategory))
                            .font(.subheadline)
                            .foregroundColor(categoryColor(alarm.wrappedCategory))
                    }
                }

                HStack(spacing: 8) {
                    Text(alarm.wrappedLabel)
                        .dynamicFont(labelFontSize)
                        .foregroundColor(.secondary)

                    // W5：视频/声音模式指示器，让用户一眼看出闹钟触发方式
                    alarmModeBadge

                    if alarm.isFadeIn {
                        Label("Fade In", systemImage: "waveform.path")
                            .dynamicFont(tagFontSize)
                            .foregroundColor(.accentColor)
                    }
                }

                repeatDaysIndicator

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
                    .dynamicFont(volumeFontSize, weight: .semibold)
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

    /// W5：闹钟模式徽章 — 视频闹钟 / 声音闹钟
    /// 参考竞品 Alarmy：卡片上明确显示闹钟触发方式
    private var alarmModeBadge: some View {
        Group {
            if alarm.videoBackgroundName != nil {
                // 视频闹钟：视频画面 + 视频原声
                Label("Video", systemImage: "play.rectangle.fill")
                    .dynamicFont(tagFontSize, weight: .medium)
                    .foregroundColor(.purple)
            } else {
                // 声音闹钟
                Label(alarm.wrappedSoundName, systemImage: "bell.fill")
                    .dynamicFont(tagFontSize)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var repeatDaysIndicator: some View {
        Group {
            if let days = alarm.repeatDays, !days.isEmpty {
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(AppConstants.DayPicker.daySymbols[index])
                            .dynamicFont(repeatDayFontSize, weight: days.contains(index) ? .bold : .regular)
                            .foregroundColor(days.contains(index) ? .accentColor : .gray.opacity(0.4))
                    }
                }
            }
        }
    }

    private var repeatDayFontSize: CGFloat {
        isPad ? 14 : 10
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
