import SwiftUI

/// Premium 锁定提示组件
/// 用于在铃声/视频选择器中显示 Premium 内容的锁定状态
struct PremiumLockView: View {
    let onUpgrade: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: isPad ? 18 : 14))
                    .foregroundColor(.yellow)

                Text("Premium")
                    .font(.system(size: isPad ? 16 : 13, weight: .semibold))
                    .foregroundColor(.yellow)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }
}
