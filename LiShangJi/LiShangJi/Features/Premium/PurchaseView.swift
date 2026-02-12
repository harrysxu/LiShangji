//
//  PurchaseView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/10.
//

import SwiftUI
import StoreKit

/// 高级版购买页面
struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var premiumManager = PremiumManager.shared
    @State private var showPrivacyPolicy = false
    @State private var showUserAgreement = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xxl) {
                    // 顶部图标
                    headerSection

                    // 高级功能列表
                    featuresSection

                    // 价格与购买
                    purchaseSection

                    // 法律声明
                    legalSection

                    // 恢复购买
                    restoreSection
                }
                .padding(AppConstants.Spacing.lg)
                .padding(.bottom, AppConstants.Spacing.xxxl)
            }
            .lsjPageBackground()
            .navigationTitle("升级高级版")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("提示", isPresented: Binding(
                get: { premiumManager.errorMessage != nil },
                set: { if !$0 { premiumManager.errorMessage = nil } }
            )) {
                Button("确定") { premiumManager.errorMessage = nil }
            } message: {
                Text(premiumManager.errorMessage ?? "")
            }
            .onChange(of: premiumManager.isPremium) { _, newValue in
                if newValue {
                    // 购买成功后自动关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 顶部

    private var headerSection: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.theme.primary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.theme.primary)
            }

            VStack(spacing: AppConstants.Spacing.sm) {
                Text("礼小记 高级版")
                    .font(.title2.bold())
                    .foregroundStyle(Color.theme.textPrimary)

                Text("一次购买，永久使用所有功能")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
        .padding(.top, AppConstants.Spacing.xl)
    }

    // MARK: - 功能列表

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(icon: "book.closed.fill", title: "无限账本", subtitle: "创建多个账本，分场景管理", color: Color.theme.primary)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "camera.viewfinder", title: "OCR 扫描识别", subtitle: "拍照即可自动识别姓名和金额", color: Color.theme.info)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "mic.fill", title: "语音记账", subtitle: "说出来就记下来，婚礼现场必备", color: Color.theme.warning)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "chart.bar.fill", title: "完整统计图表", subtitle: "收支趋势、关系分布、往来排行", color: Color.theme.received)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "person.2.fill", title: "无限联系人", subtitle: "不再受 \(PremiumManager.FreeLimit.maxContacts) 人限制", color: .purple)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "bell.badge.fill", title: "无限事件提醒", subtitle: "不再受 \(PremiumManager.FreeLimit.maxEventReminders) 个限制", color: .orange)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "icloud.fill", title: "iCloud 多设备同步", subtitle: "iPad / iPhone 无缝切换", color: .blue)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "square.and.arrow.up", title: "数据导出", subtitle: "导出 CSV 文件，用 Excel 打开", color: .teal)
            Divider().foregroundStyle(Color.theme.divider)
            featureRow(icon: "moon.stars.fill", title: "农历日历", subtitle: "农历节日提醒，不错过每一个节点", color: Color.theme.sent)
        }
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func featureRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.theme.received)
                .font(.body)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.md)
    }

    // MARK: - 购买区域

    private var purchaseSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            if premiumManager.isPremium {
                // 已购买状态
                HStack(spacing: AppConstants.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.theme.received)
                    Text("已解锁高级版")
                        .font(.headline)
                        .foregroundStyle(Color.theme.received)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.theme.received.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
            } else if let product = premiumManager.product {
                // 价格显示
                VStack(spacing: AppConstants.Spacing.sm) {
                    Text(product.displayPrice)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.theme.primary)

                    Text("一次性买断，永久使用")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }

                // 购买按钮
                Button {
                    Task {
                        await premiumManager.purchase()
                    }
                } label: {
                    HStack(spacing: AppConstants.Spacing.sm) {
                        if premiumManager.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "crown.fill")
                            Text("立即购买")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                    .shadow(color: Color.theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .disabled(premiumManager.isPurchasing)
            } else {
                // 加载中
                ProgressView("正在加载产品信息...")
                    .foregroundStyle(Color.theme.textSecondary)
                    .padding()
            }
        }
    }

    // MARK: - 法律声明

    private var legalSection: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            if !premiumManager.isPremium {
                // 功能性链接 — 满足 App Store Guideline 3.1.2
                HStack(spacing: 0) {
                    Text("购买即表示您同意")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)

                    Button("《用户协议》") {
                        showUserAgreement = true
                    }
                    .font(.caption)
                    .foregroundStyle(Color.theme.primary)

                    Text("和")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)

                    Button("《隐私政策》") {
                        showPrivacyPolicy = true
                    }
                    .font(.caption)
                    .foregroundStyle(Color.theme.primary)
                }

                Text("付款将通过您的 Apple ID 账户处理\n一次性买断，无订阅，无自动续费\n如需退款，请联系 Apple 支持")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") { showPrivacyPolicy = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showUserAgreement) {
            NavigationStack {
                UserAgreementView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") { showUserAgreement = false }
                        }
                    }
            }
        }
    }

    // MARK: - 恢复购买

    private var restoreSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            if !premiumManager.isPremium {
                Button {
                    Task {
                        await premiumManager.restorePurchases()
                    }
                } label: {
                    Text("恢复购买")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.primary)
                }

                Text("如果你之前已购买，点击恢复即可重新激活")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
