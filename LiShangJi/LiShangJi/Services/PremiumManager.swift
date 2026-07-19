//
//  PremiumManager.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/10.
//

import StoreKit
import SwiftUI

/// 高级版购买状态管理（基于 StoreKit 2）
@Observable
final class PremiumManager {

    // MARK: - 单例

    static let shared = PremiumManager()

    // MARK: - 产品 ID

    nonisolated static let premiumProductID = "com.xxl.LiShangJi.premium"

    // MARK: - 免费版限制

    enum FreeLimit {
        static let maxGiftBooks = 1
        static let maxContacts = Int.max
        static let maxEventReminders = Int.max
    }

    var entitlementPolicy: EntitlementPolicy { EntitlementPolicy(isPremium: isPremium) }

    // MARK: - 状态

    /// 用户是否已解锁高级版
    private(set) var isPremium: Bool = false

    /// StoreKit 产品（加载后缓存）
    private(set) var product: Product?

    /// 是否正在加载 StoreKit 产品信息
    private(set) var isLoadingProduct: Bool = false

    /// 产品加载失败时用于页面内展示的可恢复错误
    private(set) var productLoadErrorMessage: String?

    /// 是否正在购买中
    private(set) var isPurchasing: Bool = false

    /// 错误信息
    var errorMessage: String?

    // MARK: - 私有

    private var transactionListener: Task<Void, Error>?

    // MARK: - 初始化

    private init() {
        // 从 UserDefaults 快速恢复（StoreKit 验证后会覆盖）
        isPremium = UserDefaults.standard.bool(forKey: "isPremiumUnlocked")

        let launchArguments = ProcessInfo.processInfo.arguments
        if launchArguments.contains("-ui-testing") {
            isPremium = launchArguments.contains("-ui-testing-premium")
            UserDefaults.standard.set(isPremium, forKey: "isPremiumUnlocked")
            transactionListener = nil
            Task { await loadProduct() }
            return
        }

        // 启动交易监听
        transactionListener = listenForTransactions()

        // 异步检查当前权限
        Task {
            await checkCurrentEntitlements()
            await loadProduct()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 公开方法

    /// 加载产品信息
    @MainActor
    func loadProduct() async {
        guard !isLoadingProduct else { return }

        isLoadingProduct = true
        productLoadErrorMessage = nil
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            guard let premiumProduct = products.first(where: { $0.id == Self.premiumProductID }) else {
                product = nil
                productLoadErrorMessage = "暂时无法获取商品信息，请检查网络后重试"
                return
            }

            product = premiumProduct
        } catch {
            product = nil
            productLoadErrorMessage = "无法加载商品信息：\(error.localizedDescription)"
        }
    }

    /// 购买高级版
    @MainActor
    func purchase() async {
        guard let product else {
            errorMessage = "产品信息尚未加载，请稍后再试"
            return
        }

        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                updatePremiumStatus(true)
                HapticManager.shared.successNotification()

            case .userCancelled:
                break

            case .pending:
                errorMessage = "购买正在等待审核，稍后会自动解锁"

            @unknown default:
                break
            }
        } catch {
            errorMessage = "购买失败: \(error.localizedDescription)"
            HapticManager.shared.errorNotification()
        }
    }

    /// 恢复购买
    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
            if !isPremium {
                errorMessage = "未找到之前的购买记录"
            }
        } catch {
            errorMessage = "恢复购买失败: \(error.localizedDescription)"
        }
    }

    // MARK: - 私有方法

    /// 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    let shouldRefreshPremium = transaction.productID == Self.premiumProductID
                    await transaction.finish()

                    // A transaction update can also represent a refund or revocation.
                    // Re-read current entitlements instead of treating every verified update as a grant.
                    if shouldRefreshPremium {
                        await self.checkCurrentEntitlements()
                    }
                } catch {
                    // 验证失败，忽略
                }
            }
        }
    }

    /// 检查当前权限
    @MainActor
    func checkCurrentEntitlements() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if Self.grantsPremium(
                    productID: transaction.productID,
                    revocationDate: transaction.revocationDate,
                    expirationDate: transaction.expirationDate
                ) {
                    found = true
                    break
                }
            } catch {
                // 验证失败，忽略
            }
        }
        updatePremiumStatus(found)
    }

    nonisolated static func grantsPremium(
        productID: String,
        revocationDate: Date?,
        expirationDate: Date?,
        now: Date = Date()
    ) -> Bool {
        guard productID == premiumProductID, revocationDate == nil else {
            return false
        }

        return expirationDate.map { $0 > now } ?? true
    }

    /// 验证交易
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    /// 更新高级版状态
    @MainActor
    private func updatePremiumStatus(_ premium: Bool) {
        isPremium = premium
        UserDefaults.standard.set(premium, forKey: "isPremiumUnlocked")
    }

    // MARK: - DEBUG 专用

    #if DEBUG
    /// 切换高级版状态（仅用于开发调试）
    @MainActor
    func debugTogglePremium() {
        let newValue = !isPremium
        isPremium = newValue
        UserDefaults.standard.set(newValue, forKey: "isPremiumUnlocked")
        print("🔧 [DEBUG] 高级版状态已切换为: \(newValue ? "✅ 已解锁" : "❌ 未解锁")")
    }

    /// 强制设置高级版状态（仅用于开发调试）
    @MainActor
    func debugSetPremium(_ premium: Bool) {
        isPremium = premium
        UserDefaults.standard.set(premium, forKey: "isPremiumUnlocked")
        print("🔧 [DEBUG] 高级版状态已设置为: \(premium ? "✅ 已解锁" : "❌ 未解锁")")
    }
    #endif
}
