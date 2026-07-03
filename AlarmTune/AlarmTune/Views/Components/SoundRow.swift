import SwiftUI

/// 单个铃声行，被内置/音乐库/导入三处复用
/// 设计原则：三次法则 — 内置铃声列表、Apple Music 列表、自定义导入列表均使用此组件
struct SoundRow: View {
    let name: String
    let isSelected: Bool
    let onPlay: () -> Void
    let onSelect: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: isPad ? 14 : 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: iconSize))
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                Text(name)
                    .font(.system(size: soundFontSize))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Button {
                    onPlay()
                    HapticService.shared.selection()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: playIconSize))
                        .foregroundColor(.accentColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, isPad ? 14 : 8)
            .padding(.horizontal, isPad ? 16 : 12)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Layout.largeCardCornerRadius)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var isPad: Bool { horizontalSizeClass == .regular }
    private var iconSize: CGFloat { isPad ? 24 : 20 }
    private var soundFontSize: CGFloat { isPad ? 18 : 16 }
    private var playIconSize: CGFloat { isPad ? 30 : 26 }
}
