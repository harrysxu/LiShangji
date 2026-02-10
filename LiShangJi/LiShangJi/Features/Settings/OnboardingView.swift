//
//  OnboardingView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/10.
//

import SwiftUI

/// 首次启动欢迎 & 同意页面
struct OnboardingView: View {
    @Binding var hasAgreedToTerms: Bool
    @State private var showPrivacyPolicy = false
    @State private var showUserAgreement = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo 与标语
            VStack(spacing: AppConstants.Spacing.lg) {
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                Text(AppConstants.Brand.appName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.theme.textPrimary)

                Text(AppConstants.Brand.slogan)
                    .font(.title3)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            // 特性亮点
            VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
                highlightRow(
                    icon: "heart.text.clipboard",
                    title: "轻松记录人情往来",
                    description: "支持手动、OCR 拍照、语音三种记录方式"
                )
                highlightRow(
                    icon: "lock.shield.fill",
                    title: "隐私安全有保障",
                    description: "数据仅存于您的设备和 iCloud，开发者无法访问"
                )
                highlightRow(
                    icon: "chart.bar.fill",
                    title: "智能统计分析",
                    description: "收支趋势、关系分布一目了然"
                )
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)

            Spacer()

            // 同意与开始
            VStack(spacing: AppConstants.Spacing.md) {
                Button {
                    withAnimation(AppConstants.Animation.defaultSpring) {
                        hasAgreedToTerms = true
                    }
                } label: {
                    Text("开始使用")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                        .shadow(color: Color.theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }

                // 法律声明文字
                HStack(spacing: 0) {
                    Text("继续即表示您同意")
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
            }
            .padding(.horizontal, AppConstants.Spacing.xxl)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
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

    private func highlightRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 40, height: 40)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
    }
}
