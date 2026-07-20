//
//  RecordEntryView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 手动录入 Sheet
struct RecordEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel = RecordViewModel()
    @State private var showDatePicker = false
    @State private var showToast = false
    @State private var showContactPicker = false
    @State private var shouldContinueAfterSave = false

    var preselectedBook: GiftBook?

    @Query(sort: \GiftBook.sortOrder) private var books: [GiftBook]
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @Query(filter: #Predicate<CategoryItem> { $0.isVisible == true }, sort: \CategoryItem.sortOrder)
    private var categories: [CategoryItem]

    @State private var showCategoryManage = false

    /// iPad 使用左右分栏布局
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            Group {
                if isRegularWidth {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            .lsjPageBackground()
            .navigationTitle("新增记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                viewModel.selectedBook = preselectedBook ?? books.first
            }
            .toast(isPresented: $showToast, message: "记录保存成功")
            .alert("保存失败", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - iPhone 布局（上下结构）

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.lg) {
                    directionPicker
                    recordTypePicker
                    amountDisplay
                    formFields
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.top, AppConstants.Spacing.md)
                .padding(.bottom, AppConstants.Spacing.md)
            }

            continueSaveBar
            AmountKeypadView(amount: $viewModel.amount) {
                save()
            }
        }
    }

    // MARK: - iPad 布局（左右分栏）

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // 左侧：表单区域
            ScrollView {
                VStack(spacing: AppConstants.Spacing.lg) {
                    directionPicker
                    recordTypePicker
                    amountDisplay
                    formFields
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.top, AppConstants.Spacing.md)
                .padding(.bottom, AppConstants.Spacing.md)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // 右侧：键盘区域
            VStack(spacing: 0) {
                Spacer()
                continueSaveBar
                    .frame(maxWidth: 360)
                AmountKeypadView(amount: $viewModel.amount) {
                    save()
                }
                .frame(maxWidth: 360)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var continueSaveBar: some View {
        Button {
            saveAndContinue()
        } label: {
            HStack(spacing: AppConstants.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                Text("保存并继续")
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.Spacing.sm)
            .background(Color.theme.primary.opacity(0.1))
            .foregroundStyle(Color.theme.primary)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.parsedAmount <= 0 || viewModel.contactName.trimmingCharacters(in: .whitespaces).isEmpty)
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    // MARK: - 收到/送出切换

    private var directionPicker: some View {
        HStack(spacing: 0) {
            ForEach(GiftDirection.allCases, id: \.self) { dir in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.direction = dir
                    }
                } label: {
                    Text(dir.displayName)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewModel.direction == dir
                            ? (dir == .received ? Color.theme.received : Color.theme.sent)
                            : Color.theme.card)
                        .foregroundStyle(viewModel.direction == dir ? .white : Color.theme.textSecondary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Radius.sm)
                .strokeBorder(Color.theme.divider, lineWidth: 0.5)
        )
        .accessibilityIdentifier("direction_picker")
    }

    // MARK: - 记录类型切换

    private var recordTypePicker: some View {
        Picker("记录类型", selection: $viewModel.recordType) {
            ForEach(RecordType.allCases, id: \.self) { type in
                Label(type.displayName, systemImage: type.icon).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.theme.primary)
        .onChange(of: viewModel.recordType) { _, newType in
            if newType == .loan {
                viewModel.includeInGiftStats = false
            } else if !viewModel.includeInGiftStats {
                viewModel.includeInGiftStats = newType.countsInGiftBalanceByDefault
            }
        }
    }

    // MARK: - 金额显示

    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("¥")
                .font(.title.bold())
                .foregroundStyle(Color.theme.textSecondary)
            Text(viewModel.amount.isEmpty ? "0" : viewModel.amount)
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.theme.textPrimary)
                .contentTransition(.numericText())
                .animation(.snappy, value: viewModel.amount)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.md)
        .accessibilityIdentifier("amount_display")
    }

    // MARK: - 表单字段

    private var formFields: some View {
        VStack(spacing: 1) {
            // 联系人
            contactField

            Divider().foregroundStyle(Color.theme.divider)

            // 事件类型
            eventCategoryField

            Divider().foregroundStyle(Color.theme.divider)

            // 类型扩展字段
            typeSpecificField

            Divider().foregroundStyle(Color.theme.divider)

            // 日期
            dateField

            Divider().foregroundStyle(Color.theme.divider)

            // 账本选择
            bookField

            Divider().foregroundStyle(Color.theme.divider)

            // 备注
            noteField
        }
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
    }

    // MARK: - 类型扩展字段

    @ViewBuilder
    private var typeSpecificField: some View {
        switch viewModel.recordType {
        case .gift:
            EmptyView()
        case .item:
            itemOrFavorFields(title: "礼品名称", placeholder: "如烟酒茶、首饰、伴手礼")
        case .favor:
            itemOrFavorFields(title: "人情事项", placeholder: "如帮忙办事、照顾接送")
        case .loan:
            loanFields
        }
    }

    private func itemOrFavorFields(title: String, placeholder: String) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: viewModel.recordType.icon)
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    TextField(placeholder, text: $viewModel.itemName)
                        .font(.body)
                }
            }
            .padding(AppConstants.Spacing.md)

            Divider().foregroundStyle(Color.theme.divider)

            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: "number")
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 6) {
                    Text("估算金额")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    TextField("选填，用于统计", text: $viewModel.estimatedAmount)
                        .keyboardType(.decimalPad)
                        .font(.body)
                }
                Toggle("", isOn: $viewModel.includeInGiftStats)
                    .labelsHidden()
                    .tint(Color.theme.primary)
            }
            .padding(AppConstants.Spacing.md)
        }
    }

    private var loanFields: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 24)
                Text("到期日")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Spacer()
                DatePicker("", selection: $viewModel.loanDueDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color.theme.primary)
            }
            .padding(AppConstants.Spacing.md)

            Divider().foregroundStyle(Color.theme.divider)

            Toggle(isOn: $viewModel.isLoanSettled) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.theme.primary)
                        .frame(width: 24)
                    Text("已结清")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
            .tint(Color.theme.primary)
            .padding(AppConstants.Spacing.md)
        }
    }

    // MARK: - 联系人字段

    private var contactField: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: "person.fill")
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("联系人")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)

                    if let contact = viewModel.selectedContact {
                        // 已选择联系人：显示标签
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: contact.avatarSystemName)
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.primary)
                                Text(contact.name)
                                    .font(.body)
                                    .foregroundStyle(Color.theme.textPrimary)
                                Button {
                                    viewModel.clearSelectedContact()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.textSecondary.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.theme.primary.opacity(0.1))
                            .clipShape(Capsule())

                            Spacer()

                            Text("差额: \(contact.balance.balanceString)")
                                .font(.caption)
                                .foregroundStyle(contact.balance >= 0 ? Color.theme.received : Color.theme.sent)
                        }
                    } else {
                        // 未选择联系人：显示输入框
                        TextField("输入姓名", text: $viewModel.contactName)
                            .font(.body)
                            .accessibilityIdentifier("contact_name_field")
                            .onChange(of: viewModel.contactName) { _, newValue in
                                viewModel.searchContacts(query: newValue, context: modelContext)
                            }
                    }
                }

                // 通讯录选择按钮
                if viewModel.selectedContact == nil {
                    Button {
                        showContactPicker = true
                    } label: {
                        Image(systemName: "person.crop.rectangle.stack")
                            .font(.title3)
                            .foregroundStyle(Color.theme.primary)
                    }
                    .accessibilityIdentifier("contact_picker_button")
                }
            }
            .padding(AppConstants.Spacing.md)

            // 联系人建议列表
            if viewModel.selectedContact == nil && !viewModel.contactSuggestions.isEmpty {
                Divider()
                ForEach(viewModel.contactSuggestions, id: \.id) { contact in
                    Button {
                        viewModel.selectContact(contact)
                    } label: {
                        HStack {
                            Image(systemName: contact.avatarSystemName)
                                .font(.caption)
                                .foregroundStyle(Color.theme.primary)
                            Text(contact.name)
                                .foregroundStyle(Color.theme.textPrimary)
                            Text(contact.relationType.displayName)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                            Spacer()
                            Text("差额: \(contact.balance.balanceString)")
                                .font(.caption)
                                .foregroundStyle(contact.balance >= 0 ? Color.theme.received : Color.theme.sent)
                        }
                        .padding(.horizontal, AppConstants.Spacing.md)
                        .padding(.vertical, AppConstants.Spacing.sm)
                    }
                }
            }
        }
        .sheet(isPresented: $showContactPicker) {
            RecordContactPickerView { contact in
                viewModel.selectContact(contact)
                showContactPicker = false
            }
        }
    }

    // MARK: - 事件类型

    private var eventCategoryField: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 24)
                Text("事件类型")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding(.horizontal, AppConstants.Spacing.md)
            .padding(.top, AppConstants.Spacing.md)

            FlowLayout(spacing: AppConstants.Spacing.sm) {
                ForEach(categories, id: \.name) { category in
                    LSJTag(
                        text: category.name,
                        color: Color.theme.primary,
                        isSelected: viewModel.selectedCategoryName == category.name,
                        icon: category.icon
                    )
                    .onTapGesture {
                        HapticManager.shared.selection()
                        viewModel.selectedCategoryName = category.name
                    }
                }

                // 管理按钮
                Button {
                    showCategoryManage = true
                } label: {
                    LSJTag(
                        text: "管理",
                        color: Color.theme.textSecondary,
                        isSelected: false,
                        icon: "gearshape"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppConstants.Spacing.md)
            .padding(.bottom, AppConstants.Spacing.md)
            .sheet(isPresented: $showCategoryManage) {
                NavigationStack {
                    CategoryManageView()
                }
            }
        }
    }

    // MARK: - 日期

    private var dateField: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "calendar")
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)

            Text("日期")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)

            Spacer()

            DatePicker("", selection: $viewModel.eventDate, displayedComponents: .date)
                .labelsHidden()
                .tint(Color.theme.primary)
        }
        .padding(AppConstants.Spacing.md)
    }

    // MARK: - 账本选择

    private var bookField: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "book.closed.fill")
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)

            Text("账本")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)

            Spacer()

            if books.isEmpty {
                Text("无账本")
                    .font(.body)
                    .foregroundStyle(Color.theme.textSecondary)
            } else {
                Picker("", selection: $viewModel.selectedBook) {
                    Text("不选择").tag(nil as GiftBook?)
                    ForEach(books, id: \.id) { book in
                        Text(book.name).tag(book as GiftBook?)
                    }
                }
                .tint(Color.theme.textPrimary)
            }
        }
        .padding(AppConstants.Spacing.md)
    }

    // MARK: - 备注

    private var noteField: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "note.text")
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("备注")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                TextField("选填", text: $viewModel.note)
                    .font(.body)
            }
        }
        .padding(AppConstants.Spacing.md)
    }

    // MARK: - 保存

    private func save() {
        if viewModel.saveRecord(context: modelContext) {
            showToast = true
            if shouldContinueAfterSave {
                viewModel.resetForNextEntry()
                shouldContinueAfterSave = false
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }

    private func saveAndContinue() {
        shouldContinueAfterSave = true
        save()
    }
}
