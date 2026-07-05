import SwiftUI

struct AlarmRingView: View {
    @ObservedObject var viewModel: AlarmViewModel
    @ObservedObject private var volumeManager = VolumeManager.shared
    @ObservedObject private var audioService = AudioService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var pulseScale: CGFloat = 1.0
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // M8.2：视频背景分支（如果有视频背景则播放视频，否则使用渐变背景）
            // V3：传入 videoVolume，支持视频独立音量控制
            // W1/W3：传入 audioSource，决定是视频原声还是闹钟铃声
            if let alarm = viewModel.ringingAlarm,
               let videoName = alarm.videoBackgroundName, !videoName.isEmpty {
                VideoBackgroundView(videoName: videoName,
                                    videoVolume: alarm.videoVolume,
                                    audioSource: alarm.wrappedAudioSource)
                // 半透明遮罩，确保 UI 文字可读
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [themeManager.accentColor.opacity(0.9), themeManager.accentColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: ringSpacing) {
                Spacer()

                Text(currentTime.formattedTime)
                    .fixedFont(timeFontSize, weight: .bold, design: .rounded)
                    .foregroundColor(.white)
                    .accessibilityLabel("Current time: \(currentTime.formattedTime)")

                if let alarm = viewModel.ringingAlarm {
                    Text(alarm.wrappedLabel)
                        .dynamicFont(labelFontSize)
                        .foregroundColor(.white.opacity(0.9))
                        .accessibilityLabel("Alarm: \(alarm.wrappedLabel)")

                    HStack(spacing: 4) {
                        Image(systemName: alarm.volumeIcon)
                            .font(.system(size: volumeIconSize))
                        Text("\(alarm.volumePercentage)%")
                            .dynamicFont(volumeIconSize, weight: .semibold)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .accessibilityLabel("Volume: \(alarm.volumePercentage) percent")

                    // M5：音频回退提示（显示具体原因，仅在实际 fallback 时显示）
                    if audioService.didFallbackToDefault,
                       let reason = audioService.currentFallbackReason {
                        Text(reason.rawValue)
                            .dynamicFont(isPad ? 13 : 11)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // F2-5 新增：显示系统音量已被临时调高的提示
                    if volumeManager.isAlarmActive {
                        Text("System volume boosted for alarm")
                            .dynamicFont(isPad ? 13 : 11)
                            .foregroundColor(.white.opacity(0.5))
                    }
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
                            Text("Snooze for \(viewModel.ringingAlarm?.snoozeDuration ?? 5) min")
                                .dynamicFont(buttonFontSize, weight: .semibold)
                                .frame(maxWidth: buttonMaxWidth)
                                .padding(.vertical, buttonPaddingVertical)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
                        }
                        .accessibilityLabel("Snooze for \(viewModel.ringingAlarm?.snoozeDuration ?? 5) minutes")
                        .accessibilityHint("Snooze the alarm temporarily")
                    }

                    Button {
                        viewModel.stopRingingAlarm()
                        HapticService.shared.heavy()
                    } label: {
                        Text("Stop")
                            .dynamicFont(buttonFontSize, weight: .semibold)
                            .frame(maxWidth: buttonMaxWidth)
                            .padding(.vertical, buttonPaddingVertical)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
                    }
                    .accessibilityLabel("Stop alarm")
                    .accessibilityHint("Stop the ringing alarm")
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
