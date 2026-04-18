import SwiftUI

struct AlarmRingView: View {
    @ObservedObject var viewModel: AlarmViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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

            VStack(spacing: ringSpacing) {
                Spacer()

                Text(currentTime.formattedTime)
                    .font(.system(size: timeFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let alarm = viewModel.ringingAlarm {
                    Text(alarm.wrappedLabel)
                        .font(.system(size: labelFontSize))
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 4) {
                        Image(systemName: alarm.volumeIcon)
                            .font(.system(size: volumeIconSize))
                        Text("\(alarm.volumePercentage)%")
                            .font(.system(size: volumeIconSize, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: pulseCircleSize, height: pulseCircleSize)

                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 3)
                        .frame(width: pulseCircleSize, height: pulseCircleSize)
                        .scaleEffect(pulseScale)
                        .opacity(2 - Double(pulseScale))

                    Image(systemName: "alarm.fill")
                        .font(.system(size: alarmIconSize))
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
                                .font(.system(size: buttonFontSize, weight: .semibold))
                                .frame(maxWidth: buttonMaxWidth)
                                .padding(.vertical, buttonPaddingVertical)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
                        }
                    }

                    Button {
                        viewModel.stopRingingAlarm()
                        HapticService.shared.heavy()
                    } label: {
                        Text("Stop")
                            .font(.system(size: buttonFontSize, weight: .semibold))
                            .frame(maxWidth: buttonMaxWidth)
                            .padding(.vertical, buttonPaddingVertical)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
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

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var timeFontSize: CGFloat {
        isPad ? 80 : 60
    }

    private var labelFontSize: CGFloat {
        isPad ? 24 : 18
    }

    private var volumeIconSize: CGFloat {
        isPad ? 22 : 18
    }

    private var pulseCircleSize: CGFloat {
        isPad ? 160 : 120
    }

    private var alarmIconSize: CGFloat {
        isPad ? 56 : 44
    }

    private var buttonFontSize: CGFloat {
        isPad ? 20 : 16
    }

    private var buttonMaxWidth: CGFloat {
        isPad ? 400 : .infinity
    }

    private var buttonPaddingVertical: CGFloat {
        isPad ? 18 : 14
    }

    private var ringSpacing: CGFloat {
        isPad ? 48 : 40
    }
}
