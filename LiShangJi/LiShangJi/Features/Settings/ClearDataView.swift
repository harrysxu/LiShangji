//
//  ClearDataView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/9.
//

import SwiftUI
import SwiftData

/// 清空数据视图 — 三步确认流程防止误操作
struct ClearDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false

    // 数据统计
    @Query private var books: [GiftBook]
    @Query private var records: [GiftRecord]
    @Query private var contacts: [Contact]
    @Query private var eventReminders: [EventReminder]

    // 确认流程状态
    @State private var showSecondConfirm = false
    @State private var showTextConfirm = false
    @State private var confirmText = ""
    @State private var isClearing = false
    @State private var clearCompleted = false
    @FocusState private var isTextFieldFocused: Bool

    /// 确认关键词
    private let confirmKeyword = "确认删除"

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                if clearCompleted {
                    // 清空完成状态
                    completedSection
                } else if showTextConfirm {
                    // 步骤3: 文字输入确认
                    textConfirmSection
                } else {
                    // 步骤1: 数据概览与警告
                    warningSection
                    dataOverviewSection
                    if iCloudSyncEnabled {
                        iCloudWarningSection
                    }
                    actionSection
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.top, AppConstants.Spacing.md)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .navigationTitle("清空数据")
        .navigationBarTitleDisplayMode(.inline)
        // 步骤2: 二次确认弹窗
        .alert("确认清空所有数据", isPresented: $showSecondConfirm) {
            Button("取消", role: .cancel) { }
            Button("继续", role: .destructive) {
                withAnimation(AppConstants.Animation.defaultSpring) {
                    showTextConfirm = true
                }
            }
        } message: {
            if iCloudSyncEnabled {
                Text("此操作不可撤销！清空后本地和 iCloud 中的所有数据将被永久删除，无法恢复。确定要继续吗？")
            } else {
                Text("此操作不可撤销！清空后所有数据将被永久删除，无法恢复。确定要继续吗？")
            }
        }
    }

    // MARK: - 警告标头

    private var warningSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.theme.sent)

            Text("清空所有数据")
                .font(.title2.bold())
                .foregroundStyle(Color.theme.textPrimary)

            Text("此操作将永久删除您的所有数据，且不可恢复。请仔细确认。")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.lg)
    }

    // MARK: - 数据概览

    private var dataOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("将删除以下数据")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.theme.textSecondary)

            LSJCard {
                VStack(spacing: 0) {
                    dataRow(icon: "book.closed.fill", label: "账本", count: books.count, unit: "个", color: Color.theme.primary)
                    Divider().foregroundStyle(Color.theme.divider)
                    dataRow(icon: "doc.text.fill", label: "礼金记录", count: records.count, unit: "条", color: Color.theme.info)
                    Divider().foregroundStyle(Color.theme.divider)
                    dataRow(icon: "person.2.fill", label: "联系人", count: contacts.count, unit: "位", color: Color.theme.received)
                    Divider().foregroundStyle(Color.theme.divider)
                    dataRow(icon: "bell.badge.fill", label: "事件提醒", count: eventReminders.count, unit: "个", color: Color.theme.warning)
                }
            }
        }
    }

    private func dataRow(icon: String, label: String, count: Int, unit: String, color: Color) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(label)
                .font(.body)
                .foregroundStyle(Color.theme.textPrimary)

            Spacer()

            Text("\(count) \(unit)")
                .font(.body.monospacedDigit())
                .foregroundStyle(count > 0 ? Color.theme.sent : Color.theme.textSecondary)
        }
        .padding(.vertical, AppConstants.Spacing.sm)
    }

    // MARK: - iCloud 警告

    private var iCloudWarningSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
                Image(systemName: "icloud.fill")
                    .font(.title2)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: AppConstants.Spacing.xs) {
                    Text("iCloud 数据同步警告")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)

                    Text("您已开启 iCloud 同步。清空数据后，iCloud 中的数据也将被删除，您在其他设备上的数据也会被同步清除，且不可恢复！")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                        .lineSpacing(3)
                }
            }
            .padding(AppConstants.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Radius.sm)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - 操作按钮（步骤1）

    private var actionSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            let hasData = books.count + records.count + contacts.count + eventReminders.count > 0

            Button {
                HapticManager.shared.warningNotification()
                showSecondConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("我已了解，继续清空")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppConstants.Spacing.md)
                .background(hasData ? Color.theme.sent : Color.theme.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
            }
            .disabled(!hasData)
            .debounced()

            if !hasData {
                Text("当前没有数据需要清空")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
        .padding(.top, AppConstants.Spacing.md)
    }

    // MARK: - 文字输入确认（步骤3）

    private var textConfirmSection: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            VStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)

                Text("最终确认")
                    .font(.title2.bold())
                    .foregroundStyle(Color.theme.textPrimary)

                Text("请在下方输入「\(confirmKeyword)」以完成操作")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.Spacing.lg)

            if iCloudSyncEnabled {
                HStack(spacing: AppConstants.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("iCloud 数据将被同步删除，不可恢复")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
                }
                .padding(AppConstants.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
            }

            LSJCard {
                VStack(spacing: AppConstants.Spacing.md) {
                    TextField("请输入「\(confirmKeyword)」", text: $confirmText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.theme.textPrimary)
                        .focused($isTextFieldFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if !confirmText.isEmpty && confirmText != confirmKeyword {
                        Text("输入内容不匹配")
                            .font(.caption)
                            .foregroundStyle(Color.theme.sent)
                    }
                }
            }

            HStack(spacing: AppConstants.Spacing.md) {
                Button {
                    withAnimation(AppConstants.Animation.defaultSpring) {
                        showTextConfirm = false
                        confirmText = ""
                    }
                } label: {
                    Text("取消")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.Spacing.md)
                        .background(Color.theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                }

                Button {
                    performClearData()
                } label: {
                    HStack {
                        if isClearing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "trash.fill")
                        }
                        Text("确认清空")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.Spacing.md)
                    .background(confirmText == confirmKeyword ? Color.red : Color.theme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                }
                .disabled(confirmText != confirmKeyword || isClearing)
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    // MARK: - 清空完成

    private var completedSection: some View {
        VStack(spacing: AppConstants.Spacing.xl) {
            Spacer().frame(height: 60)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.theme.received)

            Text("数据已清空")
                .font(.title2.bold())
                .foregroundStyle(Color.theme.textPrimary)

            Text("所有数据已被永久删除")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)

            Button {
                dismiss()
            } label: {
                Text("返回")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.Spacing.md)
                    .background(Color.theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
            }
            .padding(.top, AppConstants.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 执行清空

    private func performClearData() {
        isClearing = true
        HapticManager.shared.warningNotification()

        // 短暂延迟给用户视觉反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // 1. 删除所有 SwiftData 模型数据
                try modelContext.delete(model: GiftRecord.self)
                try modelContext.delete(model: GiftBook.self)
                try modelContext.delete(model: Contact.self)
                try modelContext.delete(model: EventReminder.self)
                try modelContext.delete(model: GiftEvent.self)
                try modelContext.save()

                // 2. 取消所有本地通知
                NotificationService.shared.cancelAll()

                // 3. 重新初始化内置事件模板
                SeedDataService.seedBuiltInEvents(context: modelContext)

                HapticManager.shared.successNotification()

                withAnimation(AppConstants.Animation.defaultSpring) {
                    isClearing = false
                    clearCompleted = true
                }
            } catch {
                isClearing = false
                HapticManager.shared.errorNotification()
                print("清空数据失败: \(error)")
            }
        }
    }
}
