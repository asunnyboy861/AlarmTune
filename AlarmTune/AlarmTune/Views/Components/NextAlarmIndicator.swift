import SwiftUI

struct NextAlarmIndicator: View {
    let text: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack(spacing: indicatorSpacing) {
            Image(systemName: "alarm")
                .font(.system(size: iconSize))
                .foregroundColor(.accentColor)

            Text(text)
                .font(.system(size: textFontSize))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, indicatorPaddingHorizontal)
        .padding(.vertical, indicatorPaddingVertical)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(AppConstants.Layout.cardCornerRadius)
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var indicatorSpacing: CGFloat {
        isPad ? 10 : 6
    }

    private var iconSize: CGFloat {
        isPad ? 16 : 12
    }

    private var textFontSize: CGFloat {
        isPad ? 16 : 12
    }

    private var indicatorPaddingHorizontal: CGFloat {
        isPad ? 16 : 12
    }

    private var indicatorPaddingVertical: CGFloat {
        isPad ? 10 : 6
    }
}
