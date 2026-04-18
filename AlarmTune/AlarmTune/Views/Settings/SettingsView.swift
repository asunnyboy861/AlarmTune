import SwiftUI
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showFeedback = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var showSupport = false

    var body: some View {
        NavigationStack {
            Form {
                appSection
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
