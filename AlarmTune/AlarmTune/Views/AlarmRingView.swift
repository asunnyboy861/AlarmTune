import SwiftUI

struct AlarmRingView: View {
    @ObservedObject var viewModel: AlarmViewModel
    @State private var pulseScale: CGFloat = 1.0
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Text(currentTime.formattedTime)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let alarm = viewModel.ringingAlarm {
                    Text(alarm.wrappedLabel)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 4) {
                        Image(systemName: alarm.volumeIcon)
                            .font(.title3)
                        Text("\(alarm.volumePercentage)%")
                            .font(.title3.weight(.semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 3)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .opacity(2 - Double(pulseScale))

                    Image(systemName: "alarm.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(spacing: 16) {
                    if viewModel.ringingAlarm?.isSnoozeEnabled == true {
                        Button {
                            viewModel.snoozeRingingAlarm()
                            HapticService.shared.medium()
                        } label: {
                            Text("Snooze")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    }

                    Button {
                        viewModel.stopRingingAlarm()
                        HapticService.shared.heavy()
                    } label: {
                        Text("Stop")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }
}
