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

    static let premiumProductID = "com.xxl.LiShangJi.premium"

    // MARK: - 免费版限制

    enum FreeLimit {
        static let maxGiftBooks = 1
        static let maxContacts = 20
        static let maxEventReminders = 3
    }

    // MARK: - 状态

    /// 用户是否已解锁高级版
    private(set) var isPremium: Bool = false

    /// StoreKit 产品（加载后缓存）
    private(set) var product: Product?

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
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
        } catch {
            errorMessage = "无法加载产品信息: \(error.localizedDescription)"
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
                await updatePremiumStatus(true)
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
                    if transaction.productID == Self.premiumProductID {
                        await self.updatePremiumStatus(true)
                    }
                    await transaction.finish()
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
                if transaction.productID == Self.premiumProductID {
                    found = true
                    break
                }
            } catch {
                // 验证失败，忽略
            }
        }
        await updatePremiumStatus(found)
    }

    /// 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
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
}
