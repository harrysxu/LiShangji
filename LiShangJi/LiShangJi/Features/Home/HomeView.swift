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
    @State private var showingEventList = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 页面标题
                HStack(alignment: .bottom) {
                    Text("首页")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                }
                .padding(.top, AppConstants.Spacing.sm)

                // 收支概览卡片
                DashboardCardView(
                    totalReceived: viewModel.totalReceived,
                    totalSent: viewModel.totalSent
                )

                // 快捷操作
                quickActions

                // 即将到来的事件
                upcomingEventsSection

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
        .navigationDestination(isPresented: $showingAllRecords) {
            AllRecordsListView()
        }
        .navigationDestination(isPresented: $showingEventList) {
            EventListView()
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

    // MARK: - 即将到来的事件

    private var upcomingEventsSection: some View {
        Group {
            if !viewModel.upcomingEvents.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text("即将到来的事件")
                            .font(.headline)
                            .foregroundStyle(Color.theme.textPrimary)
                        Spacer()
                        Button("查看全部") {
                            showingEventList = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.primary)
                        .debounced()
                    }

                    LSJCard {
                        VStack(spacing: 0) {
                            ForEach(viewModel.upcomingEvents) { event in
                                HStack(spacing: AppConstants.Spacing.md) {
                                    Image(systemName: event.category.icon)
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.primary)
                                        .frame(width: 28, height: 28)
                                        .background(Color.theme.primary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(event.title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color.theme.textPrimary)
                                            .lineLimit(1)
                                        Text(eventDateText(event))
                                            .font(.caption)
                                            .foregroundStyle(Color.theme.textSecondary)
                                    }

                                    Spacer()

                                    let days = event.daysUntilEvent
                                    Text(days == 0 ? "今天" : "\(days)天后")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(days <= 3 ? Color.theme.primary.opacity(0.15) : Color.theme.warning.opacity(0.15))
                                        .foregroundStyle(days <= 3 ? Color.theme.primary : Color.theme.warning)
                                        .clipShape(Capsule())
                                }
                                .padding(.vertical, AppConstants.Spacing.sm)

                                if event.id != viewModel.upcomingEvents.last?.id {
                                    Divider()
                                        .foregroundStyle(Color.theme.divider)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func eventDateText(_ event: EventReminder) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: event.eventDate)
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
                    .debounced()
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
        .debounced()
        .accessibilityIdentifier("fab_add_record")
        .padding(.trailing, AppConstants.Spacing.xl)
        .padding(.bottom, AppConstants.Spacing.xl)
    }
}
