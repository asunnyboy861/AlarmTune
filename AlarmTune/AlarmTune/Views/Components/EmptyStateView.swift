import SwiftUI

struct EmptyStateView: View {
    var onAdd: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: sizeClassSpacing) {
            Spacer()

            Image(systemName: "alarm.fill")
                .font(.system(size: iconSize))
                .foregroundColor(.accentColor.opacity(0.5))
                .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text("No Alarms Yet")
                    .font(.system(size: titleSize, weight: .semibold))

                Text("Add your first alarm with custom volume")
                    .font(.system(size: subtitleSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAdd) {
                Label("Add Alarm", systemImage: "plus.circle.fill")
                    .font(.system(size: buttonFontSize, weight: .semibold))
                    .frame(maxWidth: buttonMaxWidth)
                    .padding(.vertical, buttonPaddingVertical)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
        .frame(maxWidth: horizontalSizeClass == .regular ? 800 : AppConstants.Layout.maxContentWidth)
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var iconSize: CGFloat {
        isPad ? 120 : 64
    }

    private var titleSize: CGFloat {
        isPad ? 34 : 22
    }

    private var subtitleSize: CGFloat {
        isPad ? 22 : 16
    }

    private var buttonFontSize: CGFloat {
        isPad ? 22 : 16
    }

    private var buttonMaxWidth: CGFloat {
        isPad ? 360 : .infinity
    }

    private var buttonPaddingVertical: CGFloat {
        isPad ? 20 : 14
    }

    private var sizeClassSpacing: CGFloat {
        isPad ? 40 : 24
    }
}
