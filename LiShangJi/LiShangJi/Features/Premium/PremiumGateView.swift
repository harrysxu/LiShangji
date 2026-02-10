//
//  PremiumGateView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/10.
//

import SwiftUI

/// 高级功能锁定提示视图 —— 嵌入到被锁功能入口处，点击后弹出购买页
struct PremiumGateView: View {
    let icon: String
    let title: String
    let subtitle: String

    @State private var showPurchase = false

    var body: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.theme.primary.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.theme.primary.opacity(0.5))

                // 锁标识
                Image(systemName: "lock.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Color.theme.primary)
                    .clipShape(Circle())
                    .offset(x: 30, y: 30)
            }

            VStack(spacing: AppConstants.Spacing.sm) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.Spacing.xxl)
            }

            Button {
                HapticManager.shared.lightImpact()
                showPurchase = true
            } label: {
                HStack(spacing: AppConstants.Spacing.sm) {
                    Image(systemName: "crown.fill")
                    Text("解锁高级版")
                }
                .font(.headline)
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(Color.theme.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                .shadow(color: Color.theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showPurchase) {
            PurchaseView()
        }
    }
}

/// 高级功能模糊覆盖层 —— 用于覆盖在统计图表等内容上方
struct PremiumBlurOverlay: View {
    @State private var showPurchase = false

    var body: some View {
        ZStack {
            // 模糊背景
            Rectangle()
                .fill(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))

            VStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(Color.theme.primary)

                Text("升级高级版查看完整图表")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.textPrimary)

                Button {
                    HapticManager.shared.lightImpact()
                    showPurchase = true
                } label: {
                    HStack(spacing: AppConstants.Spacing.xs) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                        Text("解锁")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseView()
        }
    }
}

/// ViewModifier：为被锁定的功能添加锁定角标
struct PremiumBadgeModifier: ViewModifier {
    let isPremium: Bool

    func body(content: Content) -> some View {
        if isPremium {
            content
        } else {
            content
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.primary)
                        .padding(3)
                        .background(Color.theme.primary.opacity(0.15))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
        }
    }
}

extension View {
    /// 给视图添加高级版角标（当未解锁时）
    func premiumBadge(isPremium: Bool) -> some View {
        modifier(PremiumBadgeModifier(isPremium: isPremium))
    }
}
