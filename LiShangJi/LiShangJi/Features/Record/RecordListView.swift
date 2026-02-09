//
//  RecordListView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 通用记录列表视图
struct RecordListView: View {
    let records: [GiftRecord]
    let title: String

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(records, id: \.id) { record in
                NavigationLink(value: RecordNavigationID(id: record.id)) {
                    recordRow(record)
                }
                .listRowBackground(Color.theme.card)
            }
            .onDelete(perform: deleteRecords)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .lsjPageBackground()
        .navigationTitle(title)
        .navigationDestination(for: RecordNavigationID.self) { navID in
            if let record = records.first(where: { $0.id == navID.id }) {
                RecordDetailView(record: record)
            }
        }
    }

    private func recordRow(_ record: GiftRecord) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Circle()
                .fill(record.isReceived ? Color.theme.received : Color.theme.sent)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.contact?.name ?? "未知")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Text("\(record.giftDirection.displayName) · \(record.eventName)")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.amount.currencyString)
                    .font(.body.bold().monospacedDigit())
                    .foregroundStyle(record.isReceived ? Color.theme.received : Color.theme.sent)
                Text(record.eventDate.chineseMonthDay)
                    .font(.caption2)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            let record = records[index]
            let amount = record.amount
            let direction = record.direction
            let contact = record.contact
            let book = record.book
            modelContext.delete(record)
            contact?.updateCacheForRemovedRecord(amount: amount, direction: direction)
            book?.updateCacheForRemovedRecord(amount: amount, direction: direction)
        }
        try? modelContext.save()
        HapticManager.shared.warningNotification()
    }
}

// MARK: - 全部记录列表（分页加载，避免一次加载全部数据）

struct AllRecordsListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var loadedRecords: [GiftRecord] = []
    @State private var hasMore = true
    private let pageSize = 50

    var body: some View {
        List {
            ForEach(loadedRecords, id: \.id) { record in
                NavigationLink(value: RecordNavigationID(id: record.id)) {
                    recordRow(record)
                }
                .listRowBackground(Color.theme.card)
            }
            .onDelete(perform: deleteRecords)

            // 加载更多
            if hasMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .onAppear {
                            loadMore()
                        }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .lsjPageBackground()
        .navigationTitle("全部记录")
        .navigationDestination(for: RecordNavigationID.self) { navID in
            if let record = loadedRecords.first(where: { $0.id == navID.id }) {
                RecordDetailView(record: record)
            }
        }
        .onAppear {
            if loadedRecords.isEmpty {
                loadMore()
            }
        }
    }

    private func loadMore() {
        do {
            var descriptor = FetchDescriptor<GiftRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchOffset = loadedRecords.count
            descriptor.fetchLimit = pageSize
            let newRecords = try modelContext.fetch(descriptor)
            loadedRecords.append(contentsOf: newRecords)
            hasMore = newRecords.count == pageSize
        } catch {
            hasMore = false
        }
    }

    private func recordRow(_ record: GiftRecord) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Circle()
                .fill(record.isReceived ? Color.theme.received : Color.theme.sent)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.contact?.name ?? "未知")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Text("\(record.giftDirection.displayName) · \(record.eventName)")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.amount.currencyString)
                    .font(.body.bold().monospacedDigit())
                    .foregroundStyle(record.isReceived ? Color.theme.received : Color.theme.sent)
                Text(record.eventDate.chineseMonthDay)
                    .font(.caption2)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            let record = loadedRecords[index]
            let amount = record.amount
            let direction = record.direction
            let contact = record.contact
            let book = record.book
            modelContext.delete(record)
            contact?.updateCacheForRemovedRecord(amount: amount, direction: direction)
            book?.updateCacheForRemovedRecord(amount: amount, direction: direction)
        }
        loadedRecords.remove(atOffsets: offsets)
        try? modelContext.save()
        HapticManager.shared.warningNotification()
    }
}
