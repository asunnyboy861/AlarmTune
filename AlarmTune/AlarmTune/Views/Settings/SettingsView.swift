import SwiftUI
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showFeedback = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var showSupport = false
    @State private var isTestPlaying = false

    var body: some View {
        NavigationStack {
            Form {
                appSection
                testAlarmSection
                supportSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                SafariView(url: URL(string: AppConstants.privacyURL)!)
            }
            .sheet(isPresented: $showTerms) {
                SafariView(url: URL(string: AppConstants.termsURL)!)
            }
            .sheet(isPresented: $showSupport) {
                SafariView(url: URL(string: AppConstants.supportURL)!)
            }
        }
    }

    private var appSection: some View {
        Section {
            HStack(spacing: isPad ? 20 : 12) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 6) {
                    Text("AlarmTune")
                        .font(.system(size: titleSize, weight: .semibold))
                    Text("Custom Volume for Every Alarm")
                        .font(.system(size: subtitleSize))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("v1.0")
                    .font(.system(size: versionSize))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, isPad ? 12 : 4)
        }
    }

    private var testAlarmSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                Text("Background Audio Test")
                    .font(.system(size: 16, weight: .semibold))

                VStack(alignment: .leading, spacing: 6) {
                    testStep(number: 1, text: "Tap the button below to start playing")
                    testStep(number: 2, text: "Press Home or swipe up to background the app")
                    testStep(number: 3, text: "Audio should continue playing in background")
                }

                if isTestPlaying {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .foregroundColor(.accentColor)
                            .symbolEffect(.pulse)
                        Text("Playing in background...")
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                    }
                }

                Button {
                    toggleTestAudio()
                } label: {
                    HStack {
                        Image(systemName: isTestPlaying ? "stop.fill" : "play.fill")
                        Text(isTestPlaying ? "Stop Test" : "Play Test Alarm")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isTestPlaying ? Color.red.opacity(0.9) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Audio Test")
        }
    }

    private func testStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold))
                .frame(width: 18, height: 18)
                .background(Color.accentColor.opacity(0.2))
                .foregroundColor(.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func toggleTestAudio() {
        if isTestPlaying {
            AudioService.shared.stopAlarm()
            isTestPlaying = false
        } else {
            AudioService.shared.playAlarm(
                soundName: AppConstants.Sound.defaultSound,
                volume: 0.7,
                fadeIn: false
            )
            isTestPlaying = true
        }
        HapticService.shared.light()
    }

    private var supportSection: some View {
        Section {
            Button {
                showFeedback = true
                HapticService.shared.light()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
            }

            Button {
                if let url = URL(string: "mailto:\(AppConstants.contactEmail)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Email Us", systemImage: "paperplane.fill")
            }
        } header: {
            Text("Support")
        }
    }

    private var legalSection: some View {
        Section {
            Button {
                showPrivacyPolicy = true
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Button {
                showTerms = true
            } label: {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }

            Button {
                showSupport = true
            } label: {
                Label("Technical Support", systemImage: "wrench.and.screwdriver.fill")
            }
        } header: {
            Text("Legal")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Made with")
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("in the USA")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var iconSize: CGFloat {
        isPad ? 36 : 28
    }

    private var titleSize: CGFloat {
        isPad ? 22 : 17
    }

    private var subtitleSize: CGFloat {
        isPad ? 16 : 13
    }

    private var versionSize: CGFloat {
        isPad ? 16 : 13
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = .systemBlue
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
