import SwiftUI
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showFeedback = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var showSupport = false
    @State private var showPaywall = false
    // F2-3 修复：使用 @ObservedObject 绑定共享单例
    @ObservedObject private var volumeMonitor = VolumeMonitor.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        NavigationStack {
            Form {
                appSection
                premiumSection
                themeSection
                alarmShuffleSection
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
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

                VStack(alignment: .trailing, spacing: 2) {
                    // F2-3 修复：显示系统音量状态
                    HStack(spacing: 4) {
                        Image(systemName: volumeMonitor.volumeLevelIcon)
                            .font(.system(size: 10))
                            .foregroundColor(volumeColor(from: volumeMonitor.volumeLevelColor))
                        Text("\(Int(volumeMonitor.systemVolume * 100))%")
                            .font(.system(size: isPad ? 12 : 10))
                            .foregroundColor(.secondary)
                    }
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(size: versionSize))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, isPad ? 12 : 4)
        }
    }

    private var premiumSection: some View {
        Section {
            if subscriptionService.isPremium {
                // Premium 用户显示状态
                HStack(spacing: isPad ? 20 : 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium Active")
                            .font(.system(size: titleSize, weight: .semibold))
                        Text("All features unlocked")
                            .font(.system(size: subtitleSize))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, isPad ? 8 : 4)

                Button {
                    Task { await subscriptionService.restorePurchases() }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
            } else {
                // 免费用户显示升级入口
                Button {
                    showPaywall = true
                    HapticService.shared.light()
                } label: {
                    HStack(spacing: isPad ? 20 : 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: iconSize))
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Premium")
                                .font(.system(size: titleSize, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Unlimited imports, AI sounds & full volume control")
                                .font(.system(size: subtitleSize))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, isPad ? 8 : 4)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Premium")
        }
    }

    private var themeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(ThemeManager.allThemes) { theme in
                    Button {
                        themeManager.currentTheme = theme
                        HapticService.shared.light()
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(theme.color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: theme.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                )

                            Text(theme.displayName)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)

                            Spacer()

                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.color)
                                    .font(.system(size: 20))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Theme Color")
        }
    }

    /// M8.1：随机铃声 Shuffle 开关
    /// 全局设置，用 UserDefaults 存储模式
    private var alarmShuffleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(AppConstants.Sound.ShuffleMode.allCases) { mode in
                    Button {
                        UserDefaults.standard.set(mode.rawValue, forKey: AppConstants.Sound.shuffleModeKey)
                        HapticService.shared.selection()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16))
                                .foregroundColor(shuffleModeColor)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                if mode != .off {
                                    Text(mode == .daily ? "Random built-in sound each day" : "Random built-in sound each week")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if currentShuffleMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 20))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Sound Shuffle")
        } footer: {
            Text("Automatically change your alarm sound to prevent habituation. Only built-in sounds are shuffled.")
                .font(.caption2)
        }
    }

    private var currentShuffleMode: AppConstants.Sound.ShuffleMode {
        let raw = UserDefaults.standard.string(forKey: AppConstants.Sound.shuffleModeKey) ?? ""
        return AppConstants.Sound.ShuffleMode(rawValue: raw) ?? .off
    }

    private var shuffleModeColor: Color {
        currentShuffleMode != .off ? .accentColor : .secondary
    }

    private var supportSection: some View {
        Section {
            Button {
                showFeedback = true
                HapticService.shared.light()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
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

    // F2-3 修复：将颜色字符串转为 Color（与 AlarmItem.AlarmCategory 风格一致）
    private func volumeColor(from colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        default: return .secondary
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
