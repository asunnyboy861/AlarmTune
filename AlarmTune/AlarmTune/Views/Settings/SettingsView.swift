import SwiftUI
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFeedback = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var showSupport = false

    var body: some View {
        NavigationView {
            Form {
                appSection
                supportSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
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
            HStack {
                Image(systemName: "alarm.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading) {
                    Text("AlarmTune")
                        .font(.headline)
                    Text("Custom Volume for Every Alarm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
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
