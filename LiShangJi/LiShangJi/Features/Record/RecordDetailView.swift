//
//  RecordDetailView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 记录详情页
struct RecordDetailView: View {
    let record: GiftRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingCreateContactSheet = false
    @State private var contactHistory: [GiftRecord] = []
    @State private var showReminderToast = false
    @State private var reminderToastMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 金额大字
                amountHeader

                // 详情信息
                detailSection

                if record.isReceived, let contact = record.contact {
                    returnReminderSection(contact: contact)
                }

                // 往来历史
                if let contact = record.contact, !contactHistory.isEmpty {
                    historySection(contact: contact)
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.top, AppConstants.Spacing.md)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadContactHistory()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("编辑", systemImage: "pencil") {
                        showingEditSheet = true
                    }
                    Button("删除", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            RecordEditView(record: record)
        }
        .confirmationDialog("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("删除此记录", role: .destructive) {
                // 删除前更新缓存
                let contact = record.contact
                let book = record.book
                _ = try? BackupService.shared.createSnapshot(context: modelContext, reason: "删除记录前自动备份")
                contact?.updateCacheForRemovedRecord(record)
                book?.updateCacheForRemovedRecord(record)
                modelContext.delete(record)
                try? modelContext.save()
                HapticManager.shared.warningNotification()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后不可恢复，确认删除这条 \(record.amount.currencyString) 的记录吗？")
        }
        .sheet(isPresented: $showingCreateContactSheet) {
            ContactFormView(initialName: record.contactName) { newContact in
                // 关联到当前记录
                record.contact = newContact
                record.updatedAt = Date()
                // 更新联系人缓存
                newContact.updateCacheForAddedRecord(record)
                try? modelContext.save()
                // 重新加载往来历史
                loadContactHistory()
            }
        }
        .toast(isPresented: $showReminderToast, message: reminderToastMessage, type: .success)
    }

    // MARK: - 加载往来历史

    private func loadContactHistory() {
        guard let contact = record.contact else {
            contactHistory = []
            return
        }
        contactHistory = (contact.records ?? []).sorted { $0.eventDate < $1.eventDate }
    }

    // MARK: - 金额头部

    private var amountHeader: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            LSJTag(
                text: record.giftDirection.displayName,
                color: record.isReceived ? Color.theme.received : Color.theme.sent,
                isSelected: true
            )

            Text(record.amount.currencyString)
                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.xl)
    }

    // MARK: - 详情信息

    private var detailSection: some View {
        LSJCard {
            VStack(spacing: 0) {
                // 联系人行
                if let contact = record.contact {
                    detailRow("联系人", value: contact.name, icon: "person.fill")
                    Divider().foregroundStyle(Color.theme.divider)
                    detailRow("关系", value: contact.relationType.displayName, icon: "person.2.fill")
                } else {
                    // 无联系人：显示 contactName + 创建联系人按钮
                    contactNameRow
                }
                Divider().foregroundStyle(Color.theme.divider)
                detailRow("事件", value: record.eventName, icon: CategoryItem.iconForName(record.eventCategory))
                Divider().foregroundStyle(Color.theme.divider)
                detailRow("日期", value: record.eventDate.chineseFullDate, icon: "calendar")
                Divider().foregroundStyle(Color.theme.divider)
                detailRow("账本", value: record.book?.name ?? "未分类", icon: "book.closed.fill")
                Divider().foregroundStyle(Color.theme.divider)
                detailRow("类型", value: record.giftRecordType.displayName, icon: record.giftRecordType.icon)

                if record.giftRecordType == .item || record.giftRecordType == .favor {
                    if !record.itemName.isEmpty {
                        Divider().foregroundStyle(Color.theme.divider)
                        detailRow(record.giftRecordType == .item ? "礼品" : "事项", value: record.itemName, icon: record.giftRecordType.icon)
                    }
                    Divider().foregroundStyle(Color.theme.divider)
                    detailRow("估算金额", value: record.giftStatsAmount.currencyString, icon: "number")
                    Divider().foregroundStyle(Color.theme.divider)
                    detailRow("计入统计", value: record.includeInGiftStats ? "是" : "否", icon: "chart.bar")
                }

                if record.giftRecordType == .loan {
                    Divider().foregroundStyle(Color.theme.divider)
                    detailRow("到期日", value: record.loanDueDate.chineseFullDate, icon: "calendar.badge.clock")
                    Divider().foregroundStyle(Color.theme.divider)
                    detailRow("结清状态", value: record.isLoanSettled ? "已结清" : "未结清", icon: record.isLoanSettled ? "checkmark.circle" : "clock")
                }

                if !record.note.isEmpty {
                    Divider().foregroundStyle(Color.theme.divider)
                    detailRow("备注", value: record.note, icon: "note.text")
                }

                Divider().foregroundStyle(Color.theme.divider)
                detailRow("录入方式", value: sourceDisplayName, icon: "pencil.circle")
            }
        }
    }

    // MARK: - 无联系人时的联系人行

    private var contactNameRow: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: "person.fill")
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)
            Text("联系人")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
            Spacer()
            Text(record.contactName.isEmpty ? "未知" : record.contactName)
                .font(.body)
                .foregroundStyle(Color.theme.textPrimary)
            if !record.contactName.isEmpty {
                Button {
                    showingCreateContactSheet = true
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "person.badge.plus")
                            .font(.caption)
                        Text("创建")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppConstants.Spacing.sm)
    }

    private func detailRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Color.theme.textPrimary)
        }
        .padding(.vertical, AppConstants.Spacing.sm)
    }

    private var sourceDisplayName: String {
        record.sourceDisplayName
    }

    private func returnReminderSection(contact: Contact) -> some View {
        let suggestion = ReturnSuggestionService.shared.suggestion(for: contact)
        return LSJCard {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(Color.theme.warning)
                    Text("回礼提醒")
                        .font(.headline)
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                    if let amount = suggestion.suggestedAmount {
                        Text(amount.currencyString)
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(Color.theme.warning)
                    }
                }

                Text(suggestion.message)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)

                Button {
                    createReturnReminder(contact: contact, suggestion: suggestion)
                } label: {
                    Label("创建回礼提醒", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.theme.primary)
            }
        }
    }

    private func createReturnReminder(contact: Contact, suggestion: ReturnSuggestion) {
        let eventDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let event = EventReminder(title: "给\(contact.name)回礼", eventCategory: record.eventCategory, eventDate: eventDate)
        let amountText = suggestion.suggestedAmount.map { "建议金额：\($0.currencyString)。" } ?? ""
        event.note = "\(amountText)来自记录：\(record.eventName)"
        event.reminderOption = ReminderOption.oneDay.rawValue
        event.reminderDate = event.reminder.reminderDate(for: event.eventDate)
        event.contacts = [contact]
        modelContext.insert(event)
        try? modelContext.save()
        reminderToastMessage = "已创建回礼提醒"
        HapticManager.shared.successNotification()
        withAnimation {
            showReminderToast = true
        }
    }

    // MARK: - 往来历史

    // MARK: - 往来历史

    private func historySection(contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text("与\(contact.name)的往来历史")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Spacer()
            }

            LSJCard {
                VStack(spacing: 0) {
                    ForEach(contactHistory, id: \.id) { historyRecord in
                        HStack(spacing: AppConstants.Spacing.md) {
                            // 时间线
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(historyRecord.id == record.id
                                        ? Color.theme.primary
                                        : Color.theme.textSecondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }

                            // 信息
                            VStack(alignment: .leading, spacing: 2) {
                                Text(historyRecord.eventDate.chineseFullDate)
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                                Text("\(historyRecord.giftDirection.displayName) · \(historyRecord.eventName)")
                                    .font(.subheadline)
                                    .foregroundStyle(historyRecord.id == record.id
                                        ? Color.theme.textPrimary
                                        : Color.theme.textSecondary)
                            }

                            Spacer()

                            Text(historyRecord.amount.currencyString)
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(historyRecord.isReceived ? Color.theme.received : Color.theme.sent)
                        }
                        .padding(.vertical, AppConstants.Spacing.sm)

                        if historyRecord.id != contactHistory.last?.id {
                            Divider().foregroundStyle(Color.theme.divider)
                        }
                    }

                    // 累计差额
                    Divider().foregroundStyle(Color.theme.divider)
                    HStack {
                        Spacer()
                        Text("累计差额: \(contact.balance.balanceString)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(contact.balance >= 0 ? Color.theme.received : Color.theme.sent)
                        Spacer()
                    }
                    .padding(.vertical, AppConstants.Spacing.sm)
                }
            }
        }
    }
}

// MARK: - 记录编辑 Sheet

struct RecordEditView: View {
    let record: GiftRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<GiftBook> { !$0.isArchived }, sort: \GiftBook.sortOrder)
    private var books: [GiftBook]
    @State private var amount: String = ""
    @State private var direction: GiftDirection = .sent
    @State private var eventName: String = ""
    @Query(filter: #Predicate<CategoryItem> { $0.isVisible == true }, sort: \CategoryItem.sortOrder)
    private var categories: [CategoryItem]
    @State private var selectedCategoryName: String = "婚礼"
    @State private var eventDate: Date = Date()
    @State private var note: String = ""
    @State private var selectedBook: GiftBook?
    @State private var recordType: RecordType = .gift
    @State private var itemName: String = ""
    @State private var estimatedAmount: String = ""
    @State private var includeInGiftStats: Bool = true
    @State private var loanDueDate: Date = Date()
    @State private var isLoanSettled: Bool = false
    @State private var showToast = false

    var body: some View {
        NavigationStack {
            Form {
                Section("金额与方向") {
                    Picker("方向", selection: $direction) {
                        ForEach(GiftDirection.allCases, id: \.self) { dir in
                            Text(dir.displayName).tag(dir)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("¥")
                            .font(.title2.bold())
                            .foregroundStyle(Color.theme.textSecondary)
                        TextField("金额", text: $amount)
                            .font(.title2.bold().monospacedDigit())
                            .keyboardType(.decimalPad)
                    }
                }

                Section("事件信息") {
                    Picker("记录类型", selection: $recordType) {
                        ForEach(RecordType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }

                    TextField("事件名称", text: $eventName)

                    Picker("事件类型", selection: $selectedCategoryName) {
                        ForEach(categories, id: \.name) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category.name)
                        }
                    }

                    DatePicker("日期", selection: $eventDate, displayedComponents: .date)
                }

                if recordType == .item || recordType == .favor {
                    Section(recordType == .item ? "礼品信息" : "人情信息") {
                        TextField(recordType == .item ? "礼品名称" : "人情事项", text: $itemName)
                        TextField("估算金额", text: $estimatedAmount)
                            .keyboardType(.decimalPad)
                        Toggle("计入人情统计", isOn: $includeInGiftStats)
                    }
                }

                if recordType == .loan {
                    Section("借贷信息") {
                        DatePicker("到期日", selection: $loanDueDate, displayedComponents: .date)
                        Toggle("已结清", isOn: $isLoanSettled)
                    }
                }

                Section("账本") {
                    if books.isEmpty {
                        Text("无账本")
                            .foregroundStyle(Color.theme.textSecondary)
                    } else {
                        Picker("账本", selection: $selectedBook) {
                            Text("不选择").tag(nil as GiftBook?)
                            ForEach(books, id: \.id) { book in
                                Text(book.name).tag(book as GiftBook?)
                            }
                        }
                    }
                }

                Section("备注") {
                    TextField("备注（选填）", text: $note)
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(amount.isEmpty || (Double(amount) ?? 0) <= 0)
                    .fontWeight(.semibold)
                    .debounced()
                }
            }
            .onAppear {
                amount = record.amount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(record.amount))
                    : String(record.amount)
                direction = record.giftDirection
                eventName = record.eventName
                selectedCategoryName = record.eventCategory
                eventDate = record.eventDate
                note = record.note
                selectedBook = record.book
                recordType = record.giftRecordType
                itemName = record.itemName
                estimatedAmount = record.estimatedAmount.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(record.estimatedAmount))
                    : String(record.estimatedAmount)
                includeInGiftStats = record.includeInGiftStats
                loanDueDate = record.loanDueDate
                isLoanSettled = record.isLoanSettled
            }
        }
    }

    private func saveChanges() {
        guard let parsedAmount = Double(amount), parsedAmount > 0 else { return }

        let amountChanged = record.amount != parsedAmount
        let directionChanged = record.direction != direction.rawValue
        let bookChanged = record.book?.id != selectedBook?.id
        let typeChanged = record.recordType != recordType.rawValue
        let estimatedAmountChanged = abs(record.estimatedAmount - (Double(estimatedAmount) ?? 0)) > 0.01
        let includeStatsChanged = record.includeInGiftStats != (recordType == .loan ? false : includeInGiftStats)
        let loanSettledChanged = record.isLoanSettled != isLoanSettled

        // 如果账本发生变化，先从旧账本移除缓存
        let oldBook = record.book

        record.amount = parsedAmount
        record.direction = direction.rawValue
        record.recordType = recordType.rawValue
        record.eventName = eventName
        record.eventCategory = selectedCategoryName
        record.eventDate = eventDate
        record.note = note
        record.book = selectedBook
        record.itemName = itemName
        record.estimatedAmount = Double(estimatedAmount) ?? 0
        record.includeInGiftStats = recordType == .loan ? false : includeInGiftStats
        record.loanDueDate = loanDueDate
        record.isLoanSettled = isLoanSettled
        record.settledAt = isLoanSettled ? (record.settledAt ?? Date()) : nil
        record.updatedAt = Date()

        // 如果金额、方向或类型变化，重算联系人缓存
        if amountChanged || directionChanged || typeChanged || estimatedAmountChanged || includeStatsChanged || loanSettledChanged {
            record.contact?.recalculateCachedAggregates()
        }

        // 如果账本、金额、方向或类型发生变化，重算相关账本缓存
        if bookChanged {
            oldBook?.recalculateCachedAggregates()
            selectedBook?.recalculateCachedAggregates()
        } else if amountChanged || directionChanged || typeChanged || estimatedAmountChanged || includeStatsChanged || loanSettledChanged {
            record.book?.recalculateCachedAggregates()
        }

        try? modelContext.save()
        HapticManager.shared.successNotification()
        dismiss()
    }
}
