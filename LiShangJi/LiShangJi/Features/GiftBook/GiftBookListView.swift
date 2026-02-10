//
//  GiftBookListView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 账本列表页 - 卡片网格
struct GiftBookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @State private var viewModel = GiftBookViewModel()
    @State private var showingCreateSheet = false
    @State private var editingBook: GiftBook?
    @State private var bookToDelete: GiftBook?
    @State private var showingDeleteConfirmation = false
    @State private var exportShareItem: ExportShareItem?
    @State private var showExportError = false
    @State private var showPurchaseView = false
    @Query(filter: #Predicate<GiftBook> { !$0.isArchived },
           sort: [SortDescriptor(\GiftBook.sortOrder), SortDescriptor(\GiftBook.createdAt, order: .reverse)])
    private var books: [GiftBook]

    private var canCreateBook: Bool {
        PremiumManager.shared.isPremium || books.count < PremiumManager.FreeLimit.maxGiftBooks
    }

    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.Spacing.lg),
        GridItem(.flexible(), spacing: AppConstants.Spacing.lg)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 页面标题
                HStack(alignment: .bottom) {
                    Text("账本")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                }
                .padding(.top, AppConstants.Spacing.sm)
                .padding(.horizontal, AppConstants.Spacing.lg)

                if books.isEmpty {
                    LSJEmptyStateView(
                        icon: "book.closed",
                        title: "还没有账本",
                        subtitle: "创建你的第一个人情账本吧",
                        actionTitle: "创建账本"
                    ) {
                        showingCreateSheet = true
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: AppConstants.Spacing.lg) {
                        ForEach(books, id: \.id) { book in
                            NavigationLink(value: BookNavigationID(id: book.id)) {
                                bookCard(book)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("编辑", systemImage: "pencil") {
                                    editingBook = book
                                }
                                Button("导出 CSV", systemImage: "square.and.arrow.up") {
                                    exportBook(book)
                                }
                                Button("归档", systemImage: "archivebox") {
                                    viewModel.archiveBook(book, context: modelContext)
                                }
                                Button("删除", systemImage: "trash", role: .destructive) {
                                    bookToDelete = book
                                    showingDeleteConfirmation = true
                                }
                            }
                        }

                        // 新建账本卡片
                        Button {
                            if canCreateBook {
                                showingCreateSheet = true
                            } else {
                                showPurchaseView = true
                            }
                        } label: {
                            VStack(spacing: AppConstants.Spacing.md) {
                                Image(systemName: canCreateBook ? "plus" : "lock.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.theme.primary.opacity(0.6))
                                Text(canCreateBook ? "新建账本" : "升级解锁更多账本")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 120)
                            .background(Color.theme.card.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.Radius.md)
                                    .strokeBorder(Color.theme.divider, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            )
                        }
                        .buttonStyle(.plain)
                        .debounced()
                        .accessibilityIdentifier("create_book_button")
                    }
                    .padding(.horizontal, AppConstants.Spacing.lg)

                    // 已归档区域
                    if !viewModel.archivedBooks.isEmpty {
                        archivedSection
                    }
                }
            }
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            viewModel.loadBooks(context: modelContext)
        }
        .navigationDestination(for: BookNavigationID.self) { navID in
            GiftBookDetailView(bookID: navID.id)
        }
        .sheet(isPresented: $showingCreateSheet) {
            GiftBookFormView()
        }
        .sheet(item: $editingBook) { book in
            GiftBookFormView(editingBook: book)
        }
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView()
        }
        .onAppear {
            viewModel.loadBooks(context: modelContext)
        }
        .confirmationDialog(
            "确认删除",
            isPresented: $showingDeleteConfirmation,
            presenting: bookToDelete
        ) { book in
            Button("删除「\(book.name)」及其所有记录", role: .destructive) {
                viewModel.deleteBook(book, context: modelContext)
                bookToDelete = nil
            }
            Button("取消", role: .cancel) {
                bookToDelete = nil
            }
        } message: { book in
            Text("删除账本「\(book.name)」将同时删除其中的 \(book.recordCount) 条记录，此操作不可撤销。")
        }
        .alert("出错了", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
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
                router.selectedBookForEntry = nil
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

    // MARK: - 账本卡片

    private func bookCard(_ book: GiftBook) -> some View {
        LSJColoredCard(colorHex: book.colorHex) {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Image(systemName: book.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: book.colorHex) ?? Color.theme.primary)

                Text(book.name)
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text("收 \(book.totalReceived.currencyString)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.theme.received)
                    Text("送 \(book.totalSent.currencyString)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.theme.sent)
                }

                Text("共 \(book.recordCount) 笔")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 120)
        }
    }

    // MARK: - 导出

    private func exportBook(_ book: GiftBook) {
        do {
            let url = try ExportService.shared.exportBookToCSV(book: book)
            exportShareItem = ExportShareItem(url: url)
            HapticManager.shared.successNotification()
        } catch {
            showExportError = true
            HapticManager.shared.errorNotification()
        }
    }

    // MARK: - 已归档区

    private var archivedSection: some View {
        DisclosureGroup {
            ForEach(viewModel.archivedBooks, id: \.id) { book in
                HStack {
                    Image(systemName: book.icon)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text(book.name)
                        .foregroundStyle(Color.theme.textSecondary)
                    Spacer()
                    Text("\(book.recordCount) 笔")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .padding(.vertical, AppConstants.Spacing.xs)
            }
        } label: {
            Text("已归档 (\(viewModel.archivedBooks.count))")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
    }
}
