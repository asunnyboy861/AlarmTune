import Foundation
import StoreKit

/// Premium 订阅服务（StoreKit 2 封装）
/// 单例模式，与项目其他 Service 保持一致
///
/// M7a 阶段：使用 StoreKit Configuration File 本地模拟购买
/// M7b 阶段：App Store Connect 配置订阅商品后激活真实购买
@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    /// 订阅商品 ID（需与 App Store Connect 配置一致）
    enum ProductID: String, CaseIterable {
        case monthly = "com.zzoutuo.AlarmTune.premium.monthly"
        case yearly = "com.zzoutuo.AlarmTune.premium.yearly"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly:  return "Yearly"
            }
        }

        var priceDescription: String {
            switch self {
            case .monthly: return "$2.99"
            case .yearly:  return "$14.99"
            }
        }
    }

    /// 当前是否为 Premium 用户
    @Published private(set) var isPremium: Bool = false

    /// 可购买的订阅商品
    @Published private(set) var products: [Product] = []

    /// 正在购买中
    @Published private(set) var isPurchasing: Bool = false

    /// 购买错误信息
    @Published var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedStatus()
            #if DEBUG
            // M7a：检查本地模拟购买 override（仅 DEBUG 模式，上线前移除）
            await MainActor.run {
                if UserDefaults.standard.bool(forKey: "premiumOverride") {
                    self.isPremium = true
                }
            }
            #endif
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public

    /// 加载可购买的订阅商品
    func loadProducts() async {
        do {
            let productIds = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIds)
            await MainActor.run {
                self.products = storeProducts.sorted { $0.price < $1.price }
            }
        } catch {
            print("Failed to load products: \(error.localizedDescription)")
        }
    }

    /// 购买指定订阅商品
    func purchase(_ product: Product) async {
        await MainActor.run {
            self.isPurchasing = true
            self.errorMessage = nil
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                await updatePurchasedStatus()
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                await MainActor.run {
                    self.errorMessage = "Purchase pending approval"
                }
            @unknown default:
                break
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            self.isPurchasing = false
        }
    }

    /// 恢复购买
    func restorePurchases() async {
        await MainActor.run {
            self.isPurchasing = true
            self.errorMessage = nil
        }

        do {
            try await AppStore.sync()
            await updatePurchasedStatus()
        } catch {
            await MainActor.run {
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            self.isPurchasing = false
        }
    }

    #if DEBUG
    /// M7a 本地模拟购买（仅 DEBUG 模式，上线前移除）
    /// M7b 阶段替换为真实 StoreKit 购买
    func simulatePurchase() async {
        await MainActor.run {
            self.isPurchasing = true
            self.errorMessage = nil
        }

        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            self.isPremium = true
            UserDefaults.standard.set(true, forKey: "premiumOverride")
            self.isPurchasing = false
        }
    }
    #endif

    // MARK: - Private

    /// 监听交易更新
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await self?.updatePurchasedStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 验证交易（nonisolated static 以便从 detached task 调用）
    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    /// 更新订阅状态
    private func updatePurchasedStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)
                if ProductID(rawValue: transaction.productID) != nil {
                    hasActiveSubscription = true
                    break
                }
            } catch {
                continue
            }
        }

        await MainActor.run {
            self.isPremium = hasActiveSubscription
        }
    }

    // MARK: - Errors

    enum StoreError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed:
                return "Transaction verification failed"
            }
        }
    }
}
