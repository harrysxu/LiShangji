//
//  GlobalSearchView.swift
//  LiShangJi
//
//  全局搜索
//

import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results = GlobalSearchResult(records: [], contacts: [], books: [], events: [])
    @State private var errorMessage: String?

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                emptyPrompt
            } else {
                recordsSection
                contactsSection
                booksSection
                eventsSection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
        .navigationTitle("搜索")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "姓名、金额、事件、备注")
        .onChange(of: query) { _, _ in
            performSearch()
        }
        .alert("搜索失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var emptyPrompt: some View {
        Section {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(Color.theme.primary)
                Text("快速查找人情记录")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Text("可搜索姓名、金额、事件、账本、联系人和提醒。")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .padding(.vertical, AppConstants.Spacing.sm)
        }
        .listRowBackground(Color.theme.card)
    }

    private var recordsSection: some View {
        Section("记录 \(results.records.count)") {
            if results.records.isEmpty {
                emptyRow("没有匹配记录")
            } else {
                ForEach(results.records, id: \.id) { record in
                    NavigationLink {
                        RecordDetailView(record: record)
                    } label: {
                        HStack(spacing: AppConstants.Spacing.md) {
                            Image(systemName: record.giftRecordType.icon)
                                .foregroundStyle(record.isReceived ? Color.theme.received : Color.theme.sent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.displayName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("\(record.eventName) · \(record.eventDate.chineseMonthDay)")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            Spacer()
                            Text(record.amount.currencyString)
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(record.isReceived ? Color.theme.received : Color.theme.sent)
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.theme.card)
    }

    private var contactsSection: some View {
        Section("联系人 \(results.contacts.count)") {
            if results.contacts.isEmpty {
                emptyRow("没有匹配联系人")
            } else {
                ForEach(results.contacts, id: \.id) { contact in
                    NavigationLink {
                        ContactDetailView(contact: contact)
                    } label: {
                        HStack(spacing: AppConstants.Spacing.md) {
                            Image(systemName: contact.avatarSystemName)
                                .foregroundStyle(Color.theme.primary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("\(contact.relationType.displayName) · 差额 \(contact.balance.balanceString)")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.theme.card)
    }

    private var booksSection: some View {
        Section("账本 \(results.books.count)") {
            if results.books.isEmpty {
                emptyRow("没有匹配账本")
            } else {
                ForEach(results.books, id: \.id) { book in
                    NavigationLink(value: BookNavigationID(id: book.id)) {
                        HStack(spacing: AppConstants.Spacing.md) {
                            Image(systemName: book.icon)
                                .foregroundStyle(Color(hex: book.colorHex) ?? Color.theme.primary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("\(book.recordCount) 条记录")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.theme.card)
    }

    private var eventsSection: some View {
        Section("提醒 \(results.events.count)") {
            if results.events.isEmpty {
                emptyRow("没有匹配提醒")
            } else {
                ForEach(results.events, id: \.id) { event in
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: CategoryItem.iconForName(event.eventCategory))
                            .foregroundStyle(event.isOverdue ? Color.theme.sent : Color.theme.warning)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.theme.textPrimary)
                            Text("\(event.eventDate.chineseFullDate) · \(event.contactNames)")
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.theme.card)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color.theme.textSecondary)
    }

    private func performSearch() {
        do {
            results = try SearchFilterService.shared.globalSearch(query: query, context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
