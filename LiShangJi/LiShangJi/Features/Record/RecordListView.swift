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
                NavigationLink(value: record.id) {
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
        .navigationDestination(for: UUID.self) { recordID in
            if let record = records.first(where: { $0.id == recordID }) {
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
            modelContext.delete(records[index])
        }
        try? modelContext.save()
        HapticManager.shared.warningNotification()
    }
}
