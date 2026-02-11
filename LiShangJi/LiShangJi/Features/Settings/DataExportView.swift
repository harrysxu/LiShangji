//
//  DataExportView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI
import SwiftData

/// 导出数据类型
enum ExportDataType: String, CaseIterable, Identifiable {
    case records = "records"
    case contacts = "contacts"
    case events = "events"
    case statistics = "statistics"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .records: return "记录数据"
        case .contacts: return "联系人"
        case .events: return "提醒事件"
        case .statistics: return "统计数据"
        }
    }

    var icon: String {
        switch self {
        case .records: return "doc.text.fill"
        case .contacts: return "person.2.fill"
        case .events: return "bell.badge.fill"
        case .statistics: return "chart.bar.fill"
        }
    }

    var description: String {
        switch self {
        case .records: return "导出礼金往来记录，支持按账本和时间筛选"
        case .contacts: return "导出所有联系人及其往来汇总"
        case .events: return "导出提醒事件，支持按时间筛选"
        case .statistics: return "导出月度汇总、关系分布和往来排行"
        }
    }
}

/// 导出数据页面
struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GiftBook.sortOrder) private var allBooks: [GiftBook]

    @State private var exportType: ExportDataType = .records
    @State private var selectedBookIDs: Set<UUID> = []
    @State private var selectAllBooks = true
    @State private var useTimeFilter = false
    @State private var startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()

    @State private var isExporting = false
    @State private var exportShareItem: ExportShareItem?
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var dataCount: Int = 0

    var body: some View {
        List {
            // 导出类型选择
            exportTypeSection

            // 筛选条件（按类型显示不同选项）
            if exportType == .records {
                bookSelectionSection
            }

            if exportType != .contacts {
                timeFilterSection
            }

            // 导出预览
            exportPreviewSection

            // 导出按钮
            exportActionSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
        .navigationTitle("导出数据")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportShareItem) { item in
            ShareSheet(items: [item.url])
        }
        .alert("导出失败", isPresented: $showExportError) {
            Button("确定") {}
        } message: {
            Text(exportErrorMessage)
        }
        .onAppear {
            initializeBookSelection()
            updateDataCount()
        }
        .onChange(of: exportType) { _, _ in
            updateDataCount()
        }
        .onChange(of: selectedBookIDs) { _, _ in
            updateDataCount()
        }
        .onChange(of: selectAllBooks) { _, newValue in
            if newValue {
                selectedBookIDs = Set(allBooks.map(\.id))
            } else if selectedBookIDs.count == allBooks.count {
                // 从全选切换到取消全选
                selectedBookIDs.removeAll()
            }
            updateDataCount()
        }
        .onChange(of: useTimeFilter) { _, _ in
            updateDataCount()
        }
        .onChange(of: startDate) { _, _ in
            updateDataCount()
        }
        .onChange(of: endDate) { _, _ in
            updateDataCount()
        }
    }

    // MARK: - 导出类型选择

    private var exportTypeSection: some View {
        Section {
            ForEach(ExportDataType.allCases) { type in
                Button {
                    withAnimation(AppConstants.Animation.defaultSpring) {
                        exportType = type
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: type.icon)
                            .font(.body)
                            .foregroundStyle(exportType == type ? Color.theme.primary : Color.theme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background((exportType == type ? Color.theme.primary : Color.theme.textSecondary).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.body)
                                .foregroundStyle(Color.theme.textPrimary)
                            Text(type.description)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }

                        Spacer()

                        if exportType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.theme.primary)
                                .font(.title3)
                        }
                    }
                }
            }
        } header: {
            Text("导出类型")
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 账本选择（仅记录类型）

    private var bookSelectionSection: some View {
        Section {
            Toggle(isOn: $selectAllBooks) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "books.vertical.fill")
                        .font(.body)
                        .foregroundStyle(Color.theme.primary)
                        .frame(width: 28, height: 28)
                        .background(Color.theme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("全部账本")
                        .font(.body)
                        .foregroundStyle(Color.theme.textPrimary)
                }
            }
            .tint(Color.theme.primary)

            if !selectAllBooks {
                ForEach(allBooks) { book in
                    Button {
                        toggleBook(book)
                    } label: {
                        HStack(spacing: AppConstants.Spacing.md) {
                            Image(systemName: book.icon)
                                .font(.body)
                                .foregroundStyle(Color(hex: book.colorHex) ?? Color.theme.primary)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.name)
                                    .font(.body)
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("\(book.recordCount) 条记录")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: selectedBookIDs.contains(book.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedBookIDs.contains(book.id) ? Color.theme.primary : Color.theme.textSecondary.opacity(0.4))
                                .font(.title3)
                        }
                    }
                }
            }
        } header: {
            Text("选择账本")
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 时间范围筛选

    private var timeFilterSection: some View {
        Section {
            Toggle(isOn: $useTimeFilter) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "calendar")
                        .font(.body)
                        .foregroundStyle(Color.theme.warning)
                        .frame(width: 28, height: 28)
                        .background(Color.theme.warning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("自定义时间范围")
                        .font(.body)
                        .foregroundStyle(Color.theme.textPrimary)
                }
            }
            .tint(Color.theme.primary)

            if useTimeFilter {
                DatePicker(
                    "开始日期",
                    selection: $startDate,
                    in: ...endDate,
                    displayedComponents: .date
                )
                .foregroundStyle(Color.theme.textPrimary)
                .tint(Color.theme.primary)

                DatePicker(
                    "结束日期",
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: .date
                )
                .foregroundStyle(Color.theme.textPrimary)
                .tint(Color.theme.primary)
            }
        } header: {
            Text("时间范围")
        } footer: {
            if !useTimeFilter {
                Text("关闭后将导出全部时间范围的数据")
            }
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 导出预览

    private var exportPreviewSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.theme.info)
                VStack(alignment: .leading, spacing: 2) {
                    Text("预计导出")
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text(previewText)
                        .font(.headline)
                        .foregroundStyle(Color.theme.textPrimary)
                }
                Spacer()
            }
        } header: {
            Text("导出预览")
        }
        .listRowBackground(Color.theme.card)
    }

    private var previewText: String {
        switch exportType {
        case .records:
            return "\(dataCount) 条记录"
        case .contacts:
            return "\(dataCount) 位联系人"
        case .events:
            return "\(dataCount) 个事件"
        case .statistics:
            return "统计报表（基于 \(dataCount) 条记录）"
        }
    }

    // MARK: - 导出按钮

    private var exportActionSection: some View {
        Section {
            Button {
                performExport()
            } label: {
                HStack {
                    Spacer()
                    if isExporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出 CSV 文件")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, AppConstants.Spacing.sm)
            }
            .disabled(isExporting || dataCount == 0)
            .debounced()
            .listRowBackground(
                (isExporting || dataCount == 0)
                    ? Color.theme.primary.opacity(0.4)
                    : Color.theme.primary
            )
        } footer: {
            Text("导出格式为 CSV，可用 Excel、Numbers 等软件打开")
        }
    }

    // MARK: - 操作

    private func initializeBookSelection() {
        selectedBookIDs = Set(allBooks.map(\.id))
    }

    private func toggleBook(_ book: GiftBook) {
        if selectedBookIDs.contains(book.id) {
            selectedBookIDs.remove(book.id)
        } else {
            selectedBookIDs.insert(book.id)
        }
        // 同步全选状态
        selectAllBooks = selectedBookIDs.count == allBooks.count
        HapticManager.shared.selection()
    }

    private func updateDataCount() {
        let effectiveStartDate = useTimeFilter ? startDate : nil
        let effectiveEndDate = useTimeFilter ? endDate : nil

        switch exportType {
        case .records:
            let effectiveBookIDs = selectAllBooks ? nil : selectedBookIDs
            dataCount = ExportService.shared.countFilteredRecords(
                context: modelContext,
                bookIDs: effectiveBookIDs,
                startDate: effectiveStartDate,
                endDate: effectiveEndDate
            )
        case .contacts:
            dataCount = ExportService.shared.countContacts(context: modelContext)
        case .events:
            dataCount = ExportService.shared.countFilteredEventReminders(
                context: modelContext,
                startDate: effectiveStartDate,
                endDate: effectiveEndDate
            )
        case .statistics:
            dataCount = ExportService.shared.countFilteredRecords(
                context: modelContext,
                bookIDs: nil,
                startDate: effectiveStartDate,
                endDate: effectiveEndDate
            )
        }
    }

    private func performExport() {
        isExporting = true
        let effectiveStartDate = useTimeFilter ? startDate : nil
        let effectiveEndDate = useTimeFilter ? endDate : nil

        do {
            let url: URL

            switch exportType {
            case .records:
                let effectiveBookIDs = selectAllBooks ? nil : selectedBookIDs
                url = try ExportService.shared.exportFilteredRecordsToCSV(
                    context: modelContext,
                    bookIDs: effectiveBookIDs,
                    startDate: effectiveStartDate,
                    endDate: effectiveEndDate
                )
            case .contacts:
                url = try ExportService.shared.exportContactsToCSV(context: modelContext)
            case .events:
                url = try ExportService.shared.exportEventRemindersToCSV(
                    context: modelContext,
                    startDate: effectiveStartDate,
                    endDate: effectiveEndDate
                )
            case .statistics:
                url = try ExportService.shared.exportStatisticsToCSV(
                    context: modelContext,
                    startDate: effectiveStartDate,
                    endDate: effectiveEndDate
                )
            }

            exportShareItem = ExportShareItem(url: url)
            HapticManager.shared.successNotification()
        } catch {
            exportErrorMessage = error.localizedDescription
            showExportError = true
            HapticManager.shared.errorNotification()
        }

        isExporting = false
    }
}
