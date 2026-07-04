import SwiftUI
import StoreKit

/// Premium 订阅页面
/// 展示 Premium 权益 + 订阅选项 + 恢复购买
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    benefitsSection
                    subscriptionOptionsSection
                    restoreButton
                    legalText
                }
                .padding()
                .frame(maxWidth: maxContentWidth)
            }
            .navigationTitle("AlarmTune Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Purchase Error", isPresented: .constant(subscriptionService.errorMessage != nil)) {
                Button("OK") {
                    subscriptionService.errorMessage = nil
                }
            } message: {
                Text(subscriptionService.errorMessage ?? "")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: isPad ? 64 : 48))
                .foregroundColor(.yellow)

            Text("Unlock Premium")
                .font(.system(size: isPad ? 28 : 24, weight: .bold))

            Text("Get unlimited access to all premium sounds, videos, and features")
                .font(.system(size: isPad ? 18 : 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(icon: "infinity.circle.fill", title: "Unlimited Sound Imports", description: "Import unlimited custom sounds from Files")
            benefitRow(icon: "music.note.list", title: "90+ Premium Sounds", description: "Exclusive ASMR, white noise, and sleep stories")
            benefitRow(icon: "video.fill", title: "Unlimited Video Backgrounds", description: "Import unlimited custom video backgrounds")
            benefitRow(icon: "shuffle.circle.fill", title: "Smart Shuffle", description: "Auto-rotate sounds daily or weekly to prevent fatigue")
            benefitRow(icon: "wand.and.stars", title: "AI Sound Generation", description: "Generate custom alarm sounds with AI")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: isPad ? 24 : 20))
                .foregroundColor(.accentColor)
                .frame(width: isPad ? 36 : 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isPad ? 17 : 15, weight: .semibold))
                Text(description)
                    .font(.system(size: isPad ? 15 : 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Subscription Options

    private var subscriptionOptionsSection: some View {
        VStack(spacing: 12) {
            if subscriptionService.products.isEmpty {
                // StoreKit Configuration File 未配置时的占位
                placeholderProduct(.monthly)
                placeholderProduct(.yearly)
            } else {
                ForEach(subscriptionService.products, id: \.id) { product in
                    productCard(product)
                }
            }
        }
    }

    private func placeholderProduct(_ id: SubscriptionService.ProductID) -> some View {
        Button {
            Task { await purchasePlaceholder(id) }
        } label: {
            productCardContent(
                title: id.displayName,
                price: id.priceDescription,
                period: id == .yearly ? "/year" : "/month",
                isBestValue: id == .yearly,
                isLoading: subscriptionService.isPurchasing
            )
        }
        .disabled(subscriptionService.isPurchasing)
    }

    private func productCard(_ product: Product) -> some View {
        Button {
            Task { await subscriptionService.purchase(product) }
        } label: {
            let isYearly = product.id == SubscriptionService.ProductID.yearly.rawValue
            productCardContent(
                title: SubscriptionService.ProductID.allCases.first { $0.rawValue == product.id }?.displayName ?? product.displayName,
                price: product.displayPrice,
                period: isYearly ? "/year" : "/month",
                isBestValue: isYearly,
                isLoading: subscriptionService.isPurchasing
            )
        }
        .disabled(subscriptionService.isPurchasing)
    }

    private func productCardContent(title: String, price: String, period: String, isBestValue: Bool, isLoading: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: isPad ? 20 : 17, weight: .semibold))
                    if isBestValue {
                        Text("Best Value")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }

            Spacer()

            if isLoading {
                ProgressView()
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.system(size: isPad ? 22 : 18, weight: .bold))
                    Text(period)
                        .font(.system(size: isPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isBestValue ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.largeCardCornerRadius)
                .stroke(isBestValue ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(AppConstants.Layout.largeCardCornerRadius)
    }

    private func purchasePlaceholder(_ id: SubscriptionService.ProductID) async {
        // M7a 阶段：本地模拟购买成功（需配合 StoreKit Configuration File）
        // M7b 阶段：替换为真实 StoreKit 购买
        await subscriptionService.simulatePurchase()
        dismiss()
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task { await subscriptionService.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: isPad ? 16 : 14))
                .foregroundColor(.accentColor)
        }
        .disabled(subscriptionService.isPurchasing)
    }

    // MARK: - Legal

    private var legalText: some View {
        Text("Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. Manage in Settings > Apple ID > Subscriptions.")
            .font(.system(size: isPad ? 13 : 11))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    // MARK: - Layout

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var maxContentWidth: CGFloat {
        isPad ? 600 : AppConstants.Layout.maxContentWidth
    }
}
