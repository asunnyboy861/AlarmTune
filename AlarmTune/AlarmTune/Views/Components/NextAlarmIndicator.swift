import SwiftUI

struct NextAlarmIndicator: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "alarm")
                .font(.caption)
                .foregroundColor(.accentColor)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
    }
}
