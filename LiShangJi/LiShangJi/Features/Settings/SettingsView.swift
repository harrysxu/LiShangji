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
    @State private var showPurchaseView = false

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

            // 高级版入口
            if !PremiumManager.shared.isPremium {
                Section {
                    Button {
                        showPurchaseView = true
                    } label: {
                        HStack(spacing: AppConstants.Spacing.md) {
                            Image(systemName: "crown.fill")
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.theme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("升级高级版")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.theme.primary)
                                Text("解锁 OCR、语音、图表等全部功能")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.theme.primary)
                        }
                    }
                }
                .listRowBackground(Color.theme.primary.opacity(0.06))
            }

            // 数据管理
            Section {
                if PremiumManager.shared.isPremium {
                    NavigationLink {
                        DataExportView()
                    } label: {
                        settingsRow(icon: "square.and.arrow.up", title: "导出数据", color: Color.theme.info)
                    }
                    .accessibilityIdentifier("settings_export")
                } else {
                    Button {
                        showPurchaseView = true
                    } label: {
                        HStack {
                            settingsRow(icon: "square.and.arrow.up", title: "导出数据", color: Color.theme.info)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(Color.theme.primary)
                        }
                    }
                }

                if PremiumManager.shared.isPremium {
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
                } else {
                    Button {
                        showPurchaseView = true
                    } label: {
                        HStack {
                            settingsRow(icon: "icloud.fill", title: "iCloud 同步", color: .blue)
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(Color.theme.primary)
                        }
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
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView()
        }
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

                bodyText("更新日期：2026 年 2 月 10 日\n生效日期：2026 年 2 月 10 日")

                Group {
                    sectionTitle("概述")
                    bodyText("礼尚记（以下简称「本应用」）由独立开发者徐晓龙开发和运营。我们深知个人信息的重要性，并会尽全力保护您的隐私安全。本隐私政策适用于本应用的所有功能和服务。")

                    sectionTitle("数据存储")
                    bodyText("本应用采用「本地优先」架构，您的所有人情往来记录、联系人信息等数据仅存储在您的设备和您个人的 iCloud 空间中。开发者无法访问、查看或处理您的任何数据。我们不设立任何服务器来收集或存储用户数据。")

                    sectionTitle("iCloud 同步")
                    bodyText("如果您启用了 iCloud 同步功能，数据将通过 Apple CloudKit 在您的设备间自动同步。同步数据存储在您的 iCloud Private Database 中，仅您本人可以访问。同步功能完全由您自主选择开启或关闭。")
                }

                Group {
                    sectionTitle("权限使用")
                    bodyText("""
                    本应用可能会请求以下设备权限，所有权限均为实现特定功能所必需，您可以随时在系统设置中关闭：

                    • Face ID / Touch ID：仅用于应用锁功能，生物认证过程完全由 iOS 系统处理，本应用不会获取或存储任何生物特征数据

                    • 相机：仅用于 OCR 拍照识别礼单功能，拍摄的照片仅在本地处理，不会上传至任何服务器

                    • 相册：仅用于从相册选择图片进行 OCR 识别，图片仅在本地处理

                    • 麦克风：仅用于语音记账功能，录音数据仅在本地处理，不会上传或存储

                    • 语音识别：使用 Apple Speech Framework 将语音转换为文字，优先使用设备端离线识别，识别完成后音频数据即被丢弃

                    • 通讯录（如使用）：仅用于关联系统联系人信息，不会上传任何通讯录数据
                    """)

                    sectionTitle("第三方服务")
                    bodyText("本应用不集成任何第三方分析、广告或用户追踪 SDK。我们不收集任何用户行为数据，不进行任何形式的用户画像或广告投放。")
                }

                Group {
                    sectionTitle("数据删除")
                    bodyText("您可以随时在应用内通过「清空数据」功能删除所有数据。卸载应用将清除本地数据。如需清除 iCloud 中的同步数据，请前往系统设置 > Apple ID > iCloud > 管理储存空间中进行操作。")

                    sectionTitle("用户权利")
                    bodyText("""
                    根据中华人民共和国《个人信息保护法》等相关法律法规，您享有以下权利：

                    • 查阅权：您可以随时在应用内查阅您的所有数据
                    • 更正权：您可以随时编辑和更正已记录的信息
                    • 删除权：您可以随时删除部分或全部数据
                    • 导出权：高级版用户可将数据导出为 CSV 文件

                    由于本应用采用本地存储架构，您的数据完全由您自行掌控。
                    """)

                    sectionTitle("儿童隐私")
                    bodyText("本应用不面向 16 周岁以下的未成年人。我们不会故意收集未成年人的个人信息。如果您是未成年人的监护人，发现您的孩子在未经同意的情况下使用了本应用，请联系我们。")
                }

                Group {
                    sectionTitle("隐私政策变更")
                    bodyText("如本隐私政策发生变更，我们将通过应用内通知或更新本页面的方式告知您。重大变更将在生效前提前通知。")

                    sectionTitle("联系我们")
                    bodyText("如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：\n\n邮箱：\(AppConstants.Brand.developerEmail)")
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

                bodyText("更新日期：2026 年 2 月 10 日\n生效日期：2026 年 2 月 10 日")

                Group {
                    sectionTitle("概述")
                    bodyText("欢迎使用礼尚记（以下简称「本应用」）。本用户协议（以下简称「本协议」）是您与本应用开发者徐晓龙之间关于使用本应用的法律协议。使用本应用即表示您同意本协议的全部条款。如果您不同意，请停止使用本应用。")

                    sectionTitle("服务说明")
                    bodyText("""
                    本应用是一款人情往来记录工具，帮助您管理和追踪礼金收送往来。

                    购买说明：
                    • 本应用采用一次性买断制（非订阅制），无自动续费
                    • 购买后即可永久使用当前及未来更新的所有高级功能
                    • 付款通过您的 Apple ID 账户由 Apple App Store 处理
                    • 退款政策遵循 Apple App Store 相关规定
                    • 更换设备后可通过「恢复购买」功能重新激活高级版
                    • 免费版可使用基础功能，不购买亦可正常使用
                    """)

                    sectionTitle("使用规范")
                    bodyText("• 本应用仅供个人记录使用，不构成任何财务、税务或法律建议\n• 请勿将本应用用于任何违反法律法规的活动\n• 借贷记录功能仅供个人参考，不具有法律效力\n• 您应对自己记录的数据内容的合法性和准确性负责")
                }

                Group {
                    sectionTitle("免责声明")
                    bodyText("""
                    • 本应用按「现状」提供，开发者不对其适用性作任何明示或暗示的保证
                    • 开发者不对因使用本应用产生的数据丢失承担责任，建议您定期通过导出功能备份数据
                    • iCloud 同步依赖 Apple 服务，同步延迟或异常可能由网络环境或 Apple 服务状态导致
                    • 本应用的礼俗建议仅供参考，各地习俗可能存在差异，请以当地实际情况为准
                    • 因不可抗力（包括但不限于自然灾害、政策变更、系统故障等）导致的服务中断或数据损失，开发者不承担责任
                    """)

                    sectionTitle("知识产权")
                    bodyText("本应用的设计、代码、图标、文案和品牌元素均受中华人民共和国知识产权法保护。未经开发者书面授权，任何人不得复制、修改、分发或以其他方式使用本应用的任何组成部分。")

                    sectionTitle("终止条款")
                    bodyText("• 您可以随时停止使用并删除本应用\n• 如果您严重违反本协议条款，开发者有权终止您对本应用的使用权\n• 终止后，您已购买的内容不受影响，但您应停止使用本应用")
                }

                Group {
                    sectionTitle("年龄限制")
                    bodyText("本应用不面向 16 周岁以下的未成年人。如果您未满 16 周岁，请在监护人的指导下使用本应用。")

                    sectionTitle("协议变更")
                    bodyText("开发者保留修改本协议的权利。重大变更将在更新生效前通过应用内通知告知您。继续使用本应用即表示您接受修改后的协议。")

                    sectionTitle("适用法律与争议解决")
                    bodyText("本协议的订立、执行和解释均适用中华人民共和国法律。因本协议引起的或与本协议有关的任何争议，双方应首先友好协商解决；协商不成的，任何一方均可向开发者所在地有管辖权的人民法院提起诉讼。")

                    sectionTitle("联系我们")
                    bodyText("如果您对本协议有任何疑问或建议，请通过以下方式联系我们：\n\n邮箱：\(AppConstants.Brand.developerEmail)")
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
