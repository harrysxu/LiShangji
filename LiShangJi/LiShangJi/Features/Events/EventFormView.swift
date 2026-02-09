//
//  EventFormView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI
import SwiftData

/// 事件创建/编辑表单
struct EventFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EventFormViewModel()
    @State private var showingContactPicker = false

    /// 如果传入 event 则为编辑模式
    var editingEvent: EventReminder?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 标题
                    titleSection

                    // 事件类别
                    categorySection

                    // 日期时间
                    dateSection

                    // 提醒设置
                    reminderSection

                    // 关联联系人
                    contactsSection

                    // 备注
                    noteSection
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.bottom, AppConstants.Spacing.xxxl)
            }
            .lsjPageBackground()
            .navigationTitle(viewModel.isEditing ? "编辑事件" : "新建事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                    .debounced()
                }
            }
            .onAppear {
                if let event = editingEvent {
                    viewModel.configure(with: event)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedContacts: $viewModel.selectedContacts)
            }
            .alert("出错了", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - 标题输入

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            sectionLabel("事件标题", isRequired: true)
            LSJTextField(
                label: "标题",
                icon: "pencil",
                text: $viewModel.title,
                placeholder: "输入事件标题，如「张三婚礼」",
                isRequired: true
            )
        }
    }

    // MARK: - 事件类别选择

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            sectionLabel("事件类别")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppConstants.Spacing.sm) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Button {
                            HapticManager.shared.selection()
                            viewModel.selectedCategory = category
                        } label: {
                            LSJTag(
                                text: category.displayName,
                                color: Color.theme.primary,
                                isSelected: viewModel.selectedCategory == category,
                                icon: category.icon
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 日期时间

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            sectionLabel("日期时间")

            LSJCard {
                VStack(spacing: AppConstants.Spacing.md) {
                    Toggle(isOn: $viewModel.isAllDay.animation(.easeInOut(duration: 0.2))) {
                        HStack(spacing: AppConstants.Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundStyle(Color.theme.primary)
                            Text("全天事件")
                                .font(.body)
                                .foregroundStyle(Color.theme.textPrimary)
                        }
                    }
                    .tint(Color.theme.primary)

                    Divider()
                        .foregroundStyle(Color.theme.divider)

                    // 始终使用同一个日期选择器，避免切换全天时闪动
                    DatePicker(
                        "事件日期",
                        selection: $viewModel.eventDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.theme.primary)

                    // 非全天时显示时间选择
                    if !viewModel.isAllDay {
                        Divider()
                            .foregroundStyle(Color.theme.divider)

                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.theme.primary)
                            Text("时间")
                                .font(.body)
                                .foregroundStyle(Color.theme.textPrimary)
                            Spacer()
                            DatePicker(
                                "",
                                selection: $viewModel.eventDate,
                                displayedComponents: [.hourAndMinute]
                            )
                            .labelsHidden()
                            .tint(Color.theme.primary)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    // MARK: - 提醒设置

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            sectionLabel("提醒设置")

            LSJCard {
                VStack(spacing: 0) {
                    ForEach(ReminderOption.allCases, id: \.self) { option in
                        Button {
                            HapticManager.shared.selection()
                            viewModel.reminderOption = option
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .font(.body)
                                    .foregroundStyle(Color.theme.textPrimary)
                                Spacer()
                                if viewModel.reminderOption == option {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.theme.primary)
                                }
                            }
                            .padding(.vertical, AppConstants.Spacing.md)
                        }

                        if option != ReminderOption.allCases.last {
                            Divider()
                                .foregroundStyle(Color.theme.divider)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 关联联系人

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack {
                sectionLabel("关联联系人")
                Spacer()
                Button {
                    showingContactPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("选择")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.primary)
                }
            }

            if viewModel.selectedContacts.isEmpty {
                LSJCard {
                    HStack {
                        Image(systemName: "person.2.slash")
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                        Text("未关联联系人")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                        Spacer()
                        Button("去选择") {
                            showingContactPicker = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.primary)
                    }
                }
            } else {
                LSJCard {
                    VStack(spacing: 0) {
                        ForEach(viewModel.selectedContacts) { contact in
                            HStack(spacing: AppConstants.Spacing.md) {
                                Image(systemName: contact.avatarSystemName)
                                    .font(.body)
                                    .foregroundStyle(Color.theme.primary)
                                    .frame(width: 28, height: 28)
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

                                Button {
                                    viewModel.removeContact(contact)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                                }
                            }
                            .padding(.vertical, AppConstants.Spacing.xs)

                            if contact.id != viewModel.selectedContacts.last?.id {
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
            sectionLabel("备注")
            LSJCard {
                TextField("添加备注...", text: $viewModel.note, axis: .vertical)
                    .font(.body)
                    .lineLimit(3...6)
                    .foregroundStyle(Color.theme.textPrimary)
            }
        }
    }

    // MARK: - 辅助

    private func sectionLabel(_ text: String, isRequired: Bool = false) -> some View {
        HStack(spacing: 2) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.theme.textSecondary)
            if isRequired {
                Text("*")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.primary)
            }
        }
    }

    private func saveEvent() {
        HapticManager.shared.mediumImpact()
        if viewModel.save(context: modelContext) {
            HapticManager.shared.successNotification()
            dismiss()
        } else {
            HapticManager.shared.errorNotification()
        }
    }
}
