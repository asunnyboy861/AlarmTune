import SwiftUI

struct EmptyStateView: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Alarms Yet")
                    .font(.title2.weight(.semibold))

                Text("Add your first alarm with custom volume")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAdd) {
                Label("Add Alarm", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}
