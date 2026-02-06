//
//  HomeView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 首页 - 人情仪表盘
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @State private var viewModel = HomeViewModel()
    @State private var showingAllRecords = false
    @Query(sort: \GiftRecord.createdAt, order: .reverse)
    private var allRecords: [GiftRecord]

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 收支概览卡片
                DashboardCardView(
                    totalReceived: viewModel.totalReceived,
                    totalSent: viewModel.totalSent
                )

                // 快捷操作
                quickActions

                // 最近记录
                recentRecordsSection
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            viewModel.loadData(context: modelContext)
        }
        .onAppear {
            viewModel.loadData(context: modelContext)
        }
        .onChange(of: allRecords.count) {
            viewModel.loadData(context: modelContext)
        }
        .navigationDestination(isPresented: $showingAllRecords) {
            RecordListView(records: allRecords, title: "全部记录")
        }
        .overlay(alignment: .bottomTrailing) {
            fabButton
        }
        .alert("出错了", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 快捷操作区

    private var quickActions: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            QuickEntryButton(
                icon: "square.and.pencil",
                title: "记一笔",
                color: Color.theme.primary
            ) {
                router.showingRecordEntry = true
            }

            QuickEntryButton(
                icon: "camera.viewfinder",
                title: "扫一扫",
                color: Color.theme.info
            ) {
                router.showingOCRScanner = true
            }

            QuickEntryButton(
                icon: "mic.fill",
                title: "说一说",
                color: Color.theme.warning
            ) {
                router.showingVoiceInput = true
            }
        }
    }

    // MARK: - 最近记录区

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text("最近记录")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Spacer()
                if !viewModel.recentRecords.isEmpty {
                    Button("查看全部") {
                        showingAllRecords = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.primary)
                }
            }

            if viewModel.recentRecords.isEmpty {
                LSJEmptyStateView(
                    icon: "book.closed",
                    title: "开始记录你的第一笔人情",
                    subtitle: AppConstants.Brand.slogan,
                    actionTitle: "记录第一笔"
                ) {
                    router.showingRecordEntry = true
                }
                .frame(maxWidth: .infinity)
            } else {
                LSJCard {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.recentRecords, id: \.id) { record in
                            RecentRecordRow(record: record)
                            if record.id != viewModel.recentRecords.last?.id {
                                Divider()
                                    .foregroundStyle(Color.theme.divider)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 悬浮按钮

    private var fabButton: some View {
        Button {
            HapticManager.shared.mediumImpact()
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
        .accessibilityIdentifier("fab_add_record")
        .padding(.trailing, AppConstants.Spacing.xl)
        .padding(.bottom, AppConstants.Spacing.xl)
    }
}
