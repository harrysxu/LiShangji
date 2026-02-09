//
//  EventDetailView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI
import SwiftData

/// 事件详情视图
struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let event: EventReminder
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private let repository = EventReminderRepository()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 事件头部
                    headerSection

                    // 事件信息卡片
                    infoSection

                    // 提醒设置
                    reminderInfoSection

                    // 关联联系人
                    contactsSection

                    // 备注
                    if !event.note.isEmpty {
                        noteSection
                    }

                    // 操作按钮
                    actionSection
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.top, AppConstants.Spacing.md)
                .padding(.bottom, AppConstants.Spacing.xxxl)
            }
            .lsjPageBackground()
            .navigationTitle("事件详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("编辑") {
                        showingEditSheet = true
                    }
                    .foregroundStyle(Color.theme.primary)
                    .debounced()
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EventFormView(editingEvent: event)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    deleteEvent()
                }
            } message: {
                Text("删除后无法恢复，确定要删除这个事件吗？")
            }
        }
    }

    // MARK: - 事件头部

    private var headerSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            // 类别图标
            Image(systemName: event.category.icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.theme.primary)
                .frame(width: 80, height: 80)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(Circle())

            // 标题
            Text(event.title)
                .font(.title2.bold())
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)

            // 类别标签
            LSJTag(
                text: event.category.displayName,
                color: Color.theme.primary,
                isSelected: true,
                icon: event.category.icon
            )

            // 状态
            HStack(spacing: AppConstants.Spacing.sm) {
                if event.isCompleted {
                    Label("已完成", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.received)
                } else if event.isOverdue {
                    Label("已过期", systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.sent)
                } else if event.isToday {
                    Label("今天", systemImage: "calendar.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.primary)
                } else {
                    let days = event.daysUntilEvent
                    Label("还有 \(days) 天", systemImage: "clock")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.warning)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppConstants.Spacing.lg)
    }

    // MARK: - 事件信息

    private var infoSection: some View {
        LSJCard {
            VStack(spacing: AppConstants.Spacing.md) {
                infoRow(icon: "calendar", label: "事件日期", value: formattedEventDate)
                Divider().foregroundStyle(Color.theme.divider)
                infoRow(icon: "clock", label: "全天事件", value: event.isAllDay ? "是" : "否")
                Divider().foregroundStyle(Color.theme.divider)
                infoRow(icon: "tag", label: "事件类别", value: event.category.displayName)
                Divider().foregroundStyle(Color.theme.divider)
                infoRow(icon: "calendar.badge.clock", label: "创建时间", value: formattedCreatedDate)
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textPrimary)
        }
    }

    // MARK: - 提醒信息

    private var reminderInfoSection: some View {
        LSJCard {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: event.reminder == .none ? "bell.slash" : "bell.fill")
                    .foregroundStyle(event.reminder == .none ? Color.theme.textSecondary : Color.theme.warning)
                    .frame(width: 24)
                Text("提醒")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                Spacer()
                Text(event.reminder.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textPrimary)
            }
        }
    }

    // MARK: - 关联联系人

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("关联联系人")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.theme.textSecondary)

            let contacts = event.contacts ?? []
            if contacts.isEmpty {
                LSJCard {
                    HStack {
                        Image(systemName: "person.2.slash")
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                        Text("未关联联系人")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                        Spacer()
                    }
                }
            } else {
                LSJCard {
                    VStack(spacing: 0) {
                        ForEach(contacts) { contact in
                            HStack(spacing: AppConstants.Spacing.md) {
                                Image(systemName: contact.avatarSystemName)
                                    .font(.body)
                                    .foregroundStyle(Color.theme.primary)
                                    .frame(width: 32, height: 32)
                                    .background(Color.theme.primary.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(contact.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.theme.textPrimary)
                                    Text(contact.relationType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.textSecondary)
                                }

                                Spacer()

                                if !contact.phone.isEmpty {
                                    Text(contact.phone)
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.textSecondary)
                                }
                            }
                            .padding(.vertical, AppConstants.Spacing.xs)

                            if contact.id != contacts.last?.id {
                                Divider()
                                    .foregroundStyle(Color.theme.divider)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 备注

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("备注")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.theme.textSecondary)
            LSJCard {
                Text(event.note)
                    .font(.body)
                    .foregroundStyle(Color.theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 操作按钮

    private var actionSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            LSJButton(
                title: event.isCompleted ? "标记为未完成" : "标记为已完成",
                style: .primary,
                icon: event.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
            ) {
                toggleComplete()
            }

            LSJButton(
                title: "删除事件",
                style: .secondary,
                icon: "trash"
            ) {
                showingDeleteAlert = true
            }
        }
    }

    // MARK: - 操作

    private func toggleComplete() {
        do {
            try repository.toggleComplete(event, context: modelContext)
            if event.isCompleted {
                NotificationService.shared.cancelEventReminder(eventID: event.id)
            } else {
                NotificationService.shared.rescheduleEventReminder(event: event)
            }
            HapticManager.shared.successNotification()
        } catch {
            HapticManager.shared.errorNotification()
        }
    }

    private func deleteEvent() {
        do {
            NotificationService.shared.cancelEventReminder(eventID: event.id)
            try repository.delete(event, context: modelContext)
            HapticManager.shared.successNotification()
            dismiss()
        } catch {
            HapticManager.shared.errorNotification()
        }
    }

    // MARK: - 格式化

    private var formattedEventDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        if event.isAllDay {
            formatter.dateFormat = "yyyy年M月d日"
        } else {
            formatter.dateFormat = "yyyy年M月d日 HH:mm"
        }
        return formatter.string(from: event.eventDate)
    }

    private var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: event.createdAt)
    }
}
