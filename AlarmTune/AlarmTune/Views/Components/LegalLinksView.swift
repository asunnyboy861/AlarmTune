import SwiftUI

/// 法律链接共享组件（M1）
/// 复用场景：PaywallView（App Store Guideline 3.1.2 合规）、SettingsView、未来 OnboardingView
/// 复用现有：AppConstants.privacyURL / termsURL / supportURL（直接挂在 AppConstants 下）
/// 复用现有：SafariView（定义在 SettingsView.swift，UIViewControllerRepresentable 包装 SFSafariViewController）
struct LegalLinksView: View {
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    @State private var showingSupport = false

    var body: some View {
        HStack(spacing: 16) {
            linkButton("Privacy Policy", isPresented: $showingPrivacy)
            linkButton("Terms of Use", isPresented: $showingTerms)
            linkButton("Support", isPresented: $showingSupport)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: URL(string: AppConstants.privacyURL)!)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: URL(string: AppConstants.termsURL)!)
        }
        .sheet(isPresented: $showingSupport) {
            SafariView(url: URL(string: AppConstants.supportURL)!)
        }
    }

    private func linkButton(_ title: String, isPresented: Binding<Bool>) -> some View {
        Button(title) { isPresented.wrappedValue = true }
            .foregroundColor(.secondary)
            .underline()
    }
}
