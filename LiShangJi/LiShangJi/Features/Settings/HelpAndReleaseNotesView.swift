import SwiftUI

struct HelpAndReleaseNotesView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("当前版本", value: "\(AppConstants.Brand.version) (\(AppConstants.Brand.buildNumber))")
                helpRow(
                    icon: "externaldrive.badge.checkmark",
                    title: "数据安全升级",
                    detail: "1.0 数据会在首次启动时自动升级，并在升级前创建本机恢复点。更新前后仍建议另存完整备份。"
                )
                helpRow(
                    icon: "arrow.left.arrow.right",
                    title: "备份与迁移",
                    detail: "完整备份、恢复、CSV 导入导出和 iCloud 同步属于免费数据能力。"
                )
                helpRow(
                    icon: "person.2.fill",
                    title: "往来与回礼",
                    detail: "联系人、提醒和基础记录免费；回礼助手与高级分析属于高级版。"
                )
            } header: {
                Text("1.2 更新说明")
            }

            Section {
                helpRow(
                    icon: "camera.viewfinder",
                    title: "OCR 与语音识别",
                    detail: "识别和解析结果可能有误，请在保存前核对姓名、金额、方向和场景。"
                )
                helpRow(
                    icon: "arrow.uturn.forward.circle",
                    title: "回礼建议",
                    detail: "建议仅基于历史记录供您参考，不构成法律、财务或当地礼俗保证。"
                )
            } header: {
                Text("使用边界")
            }

            Section {
                helpRow(
                    icon: "icloud.fill",
                    title: "同步状态",
                    detail: "iCloud 为可选能力，切换后需重新启动 App。页面无法证明每条数据已经上传或下载。"
                )
                helpRow(
                    icon: "person.crop.circle.badge.xmark",
                    title: "退出 iCloud 前",
                    detail: "请先创建完整备份。退出账号或关闭 iCloud Drive 后，同步将不可用。"
                )
            } header: {
                Text("iCloud")
            }

            Section {
                helpRow(
                    icon: "crown.fill",
                    title: "一次性买断",
                    detail: "高级版是非消耗型一次性购买，不是订阅，不会自动续费。实际价格以 App Store 显示为准。"
                )
                helpRow(
                    icon: "arrow.clockwise",
                    title: "恢复购买",
                    detail: "在购买页选择恢复购买，可用同一 Apple ID 重新获取已购权益。"
                )
            } header: {
                Text("购买与恢复")
            }

            Section {
                Link(destination: URL(string: "mailto:\(AppConstants.Brand.developerEmail)")!) {
                    Label("联系开发者", systemImage: "envelope.fill")
                }
                LabeledContent("邮箱", value: AppConstants.Brand.developerEmail)
            } header: {
                Text("支持")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("帮助与更新说明")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppConstants.Spacing.xs)
    }
}
