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

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 金额大字
                amountHeader

                // 详情信息
                detailSection

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
                let amount = record.amount
                let direction = record.direction
                let contact = record.contact
                let book = record.book
                modelContext.delete(record)
                contact?.updateCacheForRemovedRecord(amount: amount, direction: direction)
                book?.updateCacheForRemovedRecord(amount: amount, direction: direction)
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
                newContact.updateCacheForAddedRecord(amount: record.amount, direction: record.direction)
                try? modelContext.save()
                // 重新加载往来历史
                loadContactHistory()
            }
        }
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
                detailRow("事件", value: record.eventName, icon: record.giftEventCategory.icon)
                Divider().foregroundStyle(Color.theme.divider)
                detailRow("日期", value: record.eventDate.chineseFullDate, icon: "calendar")
                Divider().foregroundStyle(Color.theme.divider)
                detailRow("账本", value: record.book?.name ?? "未分类", icon: "book.closed.fill")
                Divider().foregroundStyle(Color.theme.divider)
                detailRow("类型", value: record.giftRecordType.displayName, icon: record.giftRecordType.icon)

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
    @State private var amount: String = ""
    @State private var direction: GiftDirection = .sent
    @State private var eventName: String = ""
    @State private var selectedEventCategory: EventCategory = .wedding
    @State private var eventDate: Date = Date()
    @State private var note: String = ""
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
                    TextField("事件名称", text: $eventName)

                    Picker("事件类型", selection: $selectedEventCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }

                    DatePicker("日期", selection: $eventDate, displayedComponents: .date)
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
                selectedEventCategory = record.giftEventCategory
                eventDate = record.eventDate
                note = record.note
            }
        }
    }

    private func saveChanges() {
        guard let parsedAmount = Double(amount), parsedAmount > 0 else { return }

        let amountChanged = record.amount != parsedAmount
        let directionChanged = record.direction != direction.rawValue

        record.amount = parsedAmount
        record.direction = direction.rawValue
        record.eventName = eventName
        record.eventCategory = selectedEventCategory.rawValue
        record.eventDate = eventDate
        record.note = note
        record.updatedAt = Date()

        // 如果金额或方向变化，重算关联缓存
        if amountChanged || directionChanged {
            record.contact?.recalculateCachedAggregates()
            record.book?.recalculateCachedAggregates()
        }

        try? modelContext.save()
        HapticManager.shared.successNotification()
        dismiss()
    }
}
