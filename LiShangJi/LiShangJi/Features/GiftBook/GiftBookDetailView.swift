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
    let bookID: UUID
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @State private var filterDirection: GiftDirection? = nil
    @State private var showingEditSheet = false
    @State private var exportShareItem: ExportShareItem?
    @State private var showExportError = false

    // 用 @Query 自动获取该账本的所有记录，SwiftData 负责生命周期管理
    @Query private var allRecords: [GiftRecord]

    init(bookID: UUID) {
        self.bookID = bookID
        _allRecords = Query(
            filter: #Predicate<GiftRecord> { record in
                record.book?.id == bookID
            },
            sort: [SortDescriptor(\GiftRecord.eventDate, order: .reverse)]
        )
    }

    // MARK: - 从 ModelContext 获取 book 对象

    private var book: GiftBook? {
        let id = bookID
        let descriptor = FetchDescriptor<GiftBook>(
            predicate: #Predicate<GiftBook> { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - 过滤 & 分组（纯内存计算属性）

    private var filteredRecords: [GiftRecord] {
        if let filter = filterDirection {
            return allRecords.filter { $0.direction == filter.rawValue }
        }
        return allRecords
    }

    private var groupedRecords: [(String, [GiftRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record in
            let components = calendar.dateComponents([.year, .month], from: record.eventDate)
            return "\(components.year ?? 2026)年\(components.month ?? 1)月"
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        Group {
            if let book {
                bookDetailContent(book)
            } else {
                ContentUnavailableView("账本不存在", systemImage: "book.closed",
                                       description: Text("该账本可能已被删除"))
            }
        }
    }

    // MARK: - 主内容

    @ViewBuilder
    private func bookDetailContent(_ book: GiftBook) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // 汇总信息
                summaryHeader(book)

                // 筛选栏
                filterBar

                // 记录列表
                if filteredRecords.isEmpty {
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
                        Section {
                            ForEach(Array(monthRecords.enumerated()), id: \.element.id) { index, record in
                                VStack(spacing: 0) {
                                    NavigationLink(value: RecordNavigationID(id: record.id)) {
                                        recordRow(record)
                                    }
                                    .buttonStyle(.plain)

                                    if index < monthRecords.count - 1 {
                                        Divider()
                                            .foregroundStyle(Color.theme.divider)
                                            .padding(.leading, AppConstants.Spacing.xl)
                                    }
                                }
                                .background(Color.theme.card)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: index == 0 ? AppConstants.Radius.md : 0,
                                        bottomLeadingRadius: index == monthRecords.count - 1 ? AppConstants.Radius.md : 0,
                                        bottomTrailingRadius: index == monthRecords.count - 1 ? AppConstants.Radius.md : 0,
                                        topTrailingRadius: index == 0 ? AppConstants.Radius.md : 0
                                    )
                                )
                                .padding(.horizontal, AppConstants.Spacing.lg)
                            }
                        } header: {
                            Text(month)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.theme.textSecondary)
                                .padding(.horizontal, AppConstants.Spacing.lg)
                                .padding(.vertical, AppConstants.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.theme.background)
                        }
                    }
                }
            }
            .padding(.top, AppConstants.Spacing.md)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .navigationTitle(book.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("导出 CSV", systemImage: "square.and.arrow.up") {
                        exportBookCSV(book)
                    }
                    Button("编辑账本", systemImage: "pencil") {
                        showingEditSheet = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .navigationDestination(for: RecordNavigationID.self) { navID in
            if let record = allRecords.first(where: { $0.id == navID.id }) {
                RecordDetailView(record: record)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            GiftBookFormView(editingBook: book)
        }
        .sheet(item: $exportShareItem) { item in
            ShareSheet(items: [item.url])
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
            .debounced()
            .padding(.trailing, AppConstants.Spacing.xl)
            .padding(.bottom, AppConstants.Spacing.xl)
        }
    }

    // MARK: - 导出

    private func exportBookCSV(_ book: GiftBook) {
        do {
            let url = try ExportService.shared.exportBookToCSV(book: book)
            exportShareItem = ExportShareItem(url: url)
            HapticManager.shared.successNotification()
        } catch {
            showExportError = true
            HapticManager.shared.errorNotification()
        }
    }

    // MARK: - 汇总头部

    private func summaryHeader(_ book: GiftBook) -> some View {
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
                Text(record.displayName)
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
        .padding(.horizontal, AppConstants.Spacing.lg)
    }
}
