//
//  AboutView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 关于页面
struct AboutView: View {
    #if DEBUG
    @State private var devTapCount = 0
    @State private var showTestDataGenerator = false
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xxxl) {
                // Logo 区域
                VStack(spacing: AppConstants.Spacing.lg) {
                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        #if DEBUG
                        .onTapGesture {
                            devTapCount += 1
                            if devTapCount >= 3 {
                                devTapCount = 0
                                showTestDataGenerator = true
                            }
                            // 2秒内未连续点击则重置计数
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if devTapCount > 0 && devTapCount < 3 {
                                    devTapCount = 0
                                }
                            }
                        }
                        #endif

                    Text(AppConstants.Brand.appName)
                        .font(.title.bold())
                        .foregroundStyle(Color.theme.textPrimary)

                    Text(AppConstants.Brand.slogan)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .padding(.top, AppConstants.Spacing.xxxl)

                // 特性列表
                VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
                    featureRow(icon: "lock.shield.fill", title: "隐私至上", description: "数据仅存于你的设备和 iCloud")
                    featureRow(icon: "icloud.fill", title: "多端同步", description: "iPhone 和 iPad 无缝切换")
                    featureRow(icon: "camera.viewfinder", title: "OCR 识别", description: "拍照即可识别纸质礼单")
                    featureRow(icon: "mic.fill", title: "语音记账", description: "说一声就记录")
                    featureRow(icon: "moon.stars.fill", title: "农历日历", description: "农历生日与节日提醒")
                }
                .padding(.horizontal, AppConstants.Spacing.xl)

                // 联系与反馈
                VStack(spacing: AppConstants.Spacing.md) {
                    Button {
                        if let url = URL(string: "mailto:\(AppConstants.Brand.developerEmail)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: AppConstants.Spacing.sm) {
                            Image(systemName: "envelope.fill")
                                .font(.body)
                            Text("联系开发者 / 反馈建议")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color.theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.theme.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                    }

                    HStack(spacing: AppConstants.Spacing.lg) {
                        if let privacyURL = URL(string: AppConstants.Brand.privacyPolicyURL) {
                            Link("隐私政策", destination: privacyURL)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                        if let termsURL = URL(string: AppConstants.Brand.termsOfServiceURL) {
                            Link("用户协议", destination: termsURL)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.xl)

                // 版本信息
                VStack(spacing: 4) {
                    Text("版本 \(AppConstants.Brand.version) (1)")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text("Made with ❤️ in China")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary.opacity(0.6))
                }
                .padding(.top, AppConstants.Spacing.xl)
                .padding(.bottom, AppConstants.Spacing.xl)
            }
            .frame(maxWidth: .infinity)
        }
        .lsjPageBackground()
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .sheet(isPresented: $showTestDataGenerator) {
            TestDataGeneratorView()
        }
        #endif
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
