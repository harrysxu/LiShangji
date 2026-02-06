//
//  GiftBookDetailView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 账本详情页 - 记录列表（按月分组）
struct GiftBookDetailView: View {
    let book: GiftBook
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @State private var filterDirection: GiftDirection? = nil
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var exportFileURL: URL?
    @State private var showExportError = false

    private var records: [GiftRecord] {
        let allRecords = book.records ?? []
        if let filter = filterDirection {
            return allRecords
                .filter { $0.direction == filter.rawValue }
                .sorted { $0.eventDate > $1.eventDate }
        }
        return allRecords.sorted { $0.eventDate > $1.eventDate }
    }

    /// 按月分组
    private var groupedRecords: [(String, [GiftRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            let components = calendar.dateComponents([.year, .month], from: record.eventDate)
            return "\(components.year ?? 2026)年\(components.month ?? 1)月"
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.lg) {
                // 汇总信息
                summaryHeader

                // 筛选栏
                filterBar

                // 记录列表
                if records.isEmpty {
                    LSJEmptyStateView(
                        icon: "tray",
                        title: "暂无记录",
                        subtitle: "点击下方按钮添加第一笔记录",
                        actionTitle: "添加记录"
                    ) {
                        router.selectedBookForEntry = book
                        router.showingRecordEntry = true
                    }
                } else {
                    ForEach(groupedRecords, id: \.0) { month, monthRecords in
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                            Text(month)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.theme.textSecondary)
                                .padding(.horizontal, AppConstants.Spacing.lg)

                            LSJCard {
                                LazyVStack(spacing: 0) {
                                    ForEach(monthRecords, id: \.id) { record in
                                        NavigationLink(value: record.id) {
                                            recordRow(record)
                                        }
                                        .buttonStyle(.plain)

                                        if record.id != monthRecords.last?.id {
                                            Divider()
                                                .foregroundStyle(Color.theme.divider)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppConstants.Spacing.lg)
                        }
                    }
                }
            }
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .navigationTitle(book.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("导出 CSV", systemImage: "square.and.arrow.up") {
                        exportBookCSV()
                    }
                    Button("编辑账本", systemImage: "pencil") {
                        showingEditSheet = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .navigationDestination(for: UUID.self) { recordID in
            if let record = records.first(where: { $0.id == recordID }) {
                RecordDetailView(record: record)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            GiftBookFormView(editingBook: book)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("导出失败", isPresented: $showExportError) {
            Button("确定") {}
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                HapticManager.shared.mediumImpact()
                router.selectedBookForEntry = book
                router.showingRecordEntry = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.theme.primary)
                    .clipShape(Circle())
                    .shadow(color: Color.theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, AppConstants.Spacing.xl)
            .padding(.bottom, AppConstants.Spacing.xl)
        }
    }

    // MARK: - 导出

    private func exportBookCSV() {
        do {
            let url = try ExportService.shared.exportBookToCSV(book: book)
            exportFileURL = url
            showingShareSheet = true
            HapticManager.shared.successNotification()
        } catch {
            showExportError = true
            HapticManager.shared.errorNotification()
        }
    }

    // MARK: - 汇总头部

    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("总收到")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Text(book.totalReceived.currencyString)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(Color.theme.received)
            }

            Spacer()

            Rectangle()
                .fill(Color.theme.divider)
                .frame(width: 1, height: 40)

            Spacer()

            VStack(alignment: .trailing) {
                Text("总送出")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Text(book.totalSent.currencyString)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(Color.theme.sent)
            }
        }
        .padding(AppConstants.Spacing.lg)
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    // MARK: - 筛选栏

    private var filterBar: some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            filterButton("全部", isSelected: filterDirection == nil) {
                filterDirection = nil
            }
            filterButton("收到", isSelected: filterDirection == .received) {
                filterDirection = .received
            }
            filterButton("送出", isSelected: filterDirection == .sent) {
                filterDirection = .sent
            }
            Spacer()
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
    }

    private func filterButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.theme.primary : Color.theme.card)
                .foregroundStyle(isSelected ? .white : Color.theme.textSecondary)
                .clipShape(Capsule())
        }
    }

    // MARK: - 记录行

    private func recordRow(_ record: GiftRecord) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.contact?.name ?? "未知")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                HStack(spacing: AppConstants.Spacing.xs) {
                    Text(record.eventDate.chineseMonthDay)
                    if let relation = record.contact?.relationType.displayName {
                        Text("·")
                        Text(relation)
                    }
                    Text("·")
                    Text(record.giftDirection.displayName)
                }
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            Text(record.amount.currencyString)
                .font(.body.bold().monospacedDigit())
                .foregroundStyle(record.isReceived ? Color.theme.received : Color.theme.sent)
        }
        .padding(.vertical, AppConstants.Spacing.sm)
    }
}
