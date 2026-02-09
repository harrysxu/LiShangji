//
//  SettingsView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData
import StoreKit

/// "我的" 设置页
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "system"
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            // 页面标题
            HStack(alignment: .bottom) {
                Text("我的")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.top, AppConstants.Spacing.sm)
            .padding(.bottom, AppConstants.Spacing.md)

            List {
            // 功能区
            Section {
                NavigationLink {
                    ContactListView()
                } label: {
                    settingsRow(icon: "person.2.fill", title: "联系人管理", color: Color.theme.primary)
                }
                .accessibilityIdentifier("settings_contacts")

                NavigationLink {
                    EventListView()
                } label: {
                    settingsRow(icon: "calendar.badge.clock", title: "事件与节日", color: Color.theme.warning)
                }
                .accessibilityIdentifier("settings_events")
            }
            .listRowBackground(Color.theme.card)

            // 数据管理
            Section {
                NavigationLink {
                    DataExportView()
                } label: {
                    settingsRow(icon: "square.and.arrow.up", title: "导出数据", color: Color.theme.info)
                }
                .accessibilityIdentifier("settings_export")

                NavigationLink {
                    ICloudSyncView()
                } label: {
                    HStack {
                        settingsRow(icon: "icloud.fill", title: "iCloud 同步", color: .blue)
                        Spacer()
                        Text(iCloudSyncEnabled ? "已开启" : "已关闭")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }

                NavigationLink {
                    ClearDataView()
                } label: {
                    settingsRow(icon: "trash.fill", title: "清空数据", color: Color.theme.sent)
                }
                .accessibilityIdentifier("settings_clear_data")
            }
            .listRowBackground(Color.theme.card)

            // 偏好设置
            Section {
                Toggle(isOn: $isAppLockEnabled) {
                    settingsRow(
                        icon: "lock.fill",
                        title: "应用锁 (\(BiometricAuthService.shared.biometricName))",
                        color: Color.theme.primary
                    )
                }
                .tint(Color.theme.primary)
                .onChange(of: isAppLockEnabled) { _, newValue in
                    if newValue {
                        // 开启时验证身份
                        Task {
                            let success = await BiometricAuthService.shared.authenticate()
                            if !success {
                                await MainActor.run {
                                    isAppLockEnabled = false
                                }
                            }
                        }
                    }
                }

                Picker(selection: $colorSchemePreference) {
                    Text("跟随系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                } label: {
                    settingsRow(icon: "moon.fill", title: "深色模式", color: .purple)
                }
            }
            .listRowBackground(Color.theme.card)

            // 关于
            Section {
                Button {
                    requestReview()
                } label: {
                    settingsRow(icon: "star.fill", title: "给我们评分", color: .yellow)
                }
                .debounced()

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    settingsRow(icon: "lock.shield.fill", title: "隐私政策", color: Color.theme.textSecondary)
                }

                NavigationLink {
                    UserAgreementView()
                } label: {
                    settingsRow(icon: "doc.text.fill", title: "用户协议", color: Color.theme.textSecondary)
                }

                NavigationLink {
                    AboutView()
                } label: {
                    settingsRow(icon: "info.circle.fill", title: "关于礼尚记", color: Color.theme.primary)
                }
                .accessibilityIdentifier("settings_about")
            }
            .listRowBackground(Color.theme.card)

            // 版本号
            Section {
                HStack {
                    Spacer()
                    Text("\(AppConstants.Brand.appName) v\(AppConstants.Brand.version)")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        } // VStack
        .lsjPageBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 设置行

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(.body)
                .foregroundStyle(Color.theme.textPrimary)
        }
    }

}

// MARK: - 系统分享面板

/// 可标识的分享项，用于 sheet(item:) 驱动分享面板
struct ExportShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 隐私政策

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
                Text("隐私政策")
                    .font(.title2.bold())
                    .foregroundStyle(Color.theme.textPrimary)

                Group {
                    sectionTitle("数据存储")
                    bodyText("礼尚记采用「本地优先」架构，您的所有数据仅存储在您的设备和您个人的 iCloud 空间中。开发者无法访问、查看或处理您的任何数据。")

                    sectionTitle("iCloud 同步")
                    bodyText("如果您启用了 iCloud，数据将通过 Apple CloudKit 在您的设备间自动同步。同步数据存储在您的 iCloud Private Database 中，仅您本人可以访问。")

                    sectionTitle("权限使用")
                    bodyText("• Face ID/Touch ID：仅用于应用锁功能，认证过程由 iOS 系统处理\n• 通讯录（如使用）：仅用于联系人关联，不会上传任何通讯录数据\n• 相机（如使用 OCR）：仅用于本地图片识别，照片不会离开您的设备")

                    sectionTitle("第三方服务")
                    bodyText("礼尚记不集成任何第三方分析、广告或追踪 SDK。我们不收集任何用户行为数据。")

                    sectionTitle("数据删除")
                    bodyText("您可以随时在 App 内删除所有数据。卸载 App 将清除本地数据。如需清除 iCloud 数据，请在系统设置中管理 iCloud 存储。")
                }
            }
            .padding(AppConstants.Spacing.lg)
        }
        .lsjPageBackground()
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.theme.textPrimary)
            .padding(.top, AppConstants.Spacing.sm)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Color.theme.textSecondary)
            .lineSpacing(4)
    }
}

// MARK: - 用户协议

struct UserAgreementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.lg) {
                Text("用户协议")
                    .font(.title2.bold())
                    .foregroundStyle(Color.theme.textPrimary)

                Group {
                    sectionTitle("服务说明")
                    bodyText("礼尚记是一款人情往来记录工具，帮助您管理和追踪礼金往来。本应用采用一次性买断制，购买后即可永久使用所有功能。")

                    sectionTitle("使用规范")
                    bodyText("• 本应用仅供个人记录使用，不构成财务或法律建议\n• 请勿将本应用用于任何违法活动\n• 借贷记录功能仅供个人参考，不具有法律效力")

                    sectionTitle("免责声明")
                    bodyText("• 开发者不对因使用本应用产生的数据丢失承担责任，建议定期导出数据备份\n• iCloud 同步依赖 Apple 服务，同步延迟或异常由网络环境导致\n• 本应用的礼俗建议仅供参考，各地习俗可能存在差异")

                    sectionTitle("知识产权")
                    bodyText("礼尚记的设计、代码和品牌元素受知识产权法保护。未经授权，不得复制或分发。")
                }
            }
            .padding(AppConstants.Spacing.lg)
        }
        .lsjPageBackground()
        .navigationTitle("用户协议")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.theme.textPrimary)
            .padding(.top, AppConstants.Spacing.sm)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Color.theme.textSecondary)
            .lineSpacing(4)
    }
}
