//
//  EventListView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI
import SwiftData

/// 事件提醒列表主视图
struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EventReminder.eventDate, order: .forward)
    private var allEvents: [EventReminder]
    @State private var viewModel = EventViewModel()
    @State private var showingAddEvent = false
    @State private var showingStatistics = false
    @State private var selectedEvent: EventReminder?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部操作栏
            headerSection

            ScrollView {
                VStack(spacing: AppConstants.Spacing.lg) {
                    // 搜索栏
                    searchBar

                    // 筛选标签
                    filterSection

                    // 事件列表
                    eventListSection
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.bottom, AppConstants.Spacing.xxxl)
            }
        }
        .lsjPageBackground()
        .navigationTitle("事件提醒")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Button {
                        showingStatistics = true
                    } label: {
                        Image(systemName: "chart.pie")
                            .foregroundStyle(Color.theme.primary)
                    }
                    .debounced()

                    Button {
                        showingAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.theme.primary)
                    }
                    .debounced()
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            EventFormView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingStatistics) {
            NavigationStack {
                EventStatisticsView(events: allEvents)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
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

    // MARK: - 顶部摘要

    private var headerSection: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            summaryItem(
                count: allEvents.filter { !$0.isCompleted && $0.eventDate >= Date() }.count,
                label: "待处理",
                color: Color.theme.primary
            )
            summaryItem(
                count: allEvents.filter { $0.isToday }.count,
                label: "今天",
                color: Color.theme.warning
            )
            summaryItem(
                count: allEvents.filter { $0.isOverdue }.count,
                label: "已过期",
                color: Color.theme.sent
            )
            summaryItem(
                count: allEvents.filter { $0.isCompleted }.count,
                label: "已完成",
                color: Color.theme.received
            )
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.md)
    }

    private func summaryItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
    }

    // MARK: - 搜索栏

    private var searchBar: some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.theme.textSecondary)
            TextField("搜索事件", text: $viewModel.searchQuery)
                .font(.body)
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
        }
        .padding(AppConstants.Spacing.md)
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
    }

    // MARK: - 筛选标签

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                // 状态筛选
                ForEach(EventFilterType.allCases, id: \.self) { filter in
                    Button {
                        HapticManager.shared.selection()
                        viewModel.selectedFilter = filter
                    } label: {
                        LSJTag(
                            text: filter.rawValue,
                            color: Color.theme.primary,
                            isSelected: viewModel.selectedFilter == filter
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 20)

                // 类别筛选
                Button {
                    HapticManager.shared.selection()
                    viewModel.selectedCategory = nil
                } label: {
                    LSJTag(
                        text: "所有类别",
                        color: Color.theme.info,
                        isSelected: viewModel.selectedCategory == nil
                    )
                }
                .buttonStyle(.plain)

                ForEach(EventCategory.allCases.filter { $0 != .other }, id: \.self) { category in
                    Button {
                        HapticManager.shared.selection()
                        viewModel.selectedCategory = category
                    } label: {
                        LSJTag(
                            text: category.displayName,
                            color: Color.theme.info,
                            isSelected: viewModel.selectedCategory == category,
                            icon: category.icon
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 事件列表

    private var eventListSection: some View {
        let groups = viewModel.groupedEvents(from: allEvents)

        return Group {
            if groups.isEmpty {
                LSJEmptyStateView(
                    icon: "bell.slash",
                    title: "暂无事件",
                    subtitle: "点击右上角 + 创建第一个事件提醒",
                    actionTitle: "创建事件"
                ) {
                    showingAddEvent = true
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: AppConstants.Spacing.lg) {
                    ForEach(groups, id: \.title) { group in
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                            Text(group.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.theme.textSecondary)

                            ForEach(group.events) { event in
                                EventCard(event: event) {
                                    viewModel.toggleComplete(event, context: modelContext)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedEvent = event
                                }
                                .contextMenu {
                                    Button {
                                        viewModel.toggleComplete(event, context: modelContext)
                                    } label: {
                                        Label(
                                            event.isCompleted ? "标记未完成" : "标记完成",
                                            systemImage: event.isCompleted ? "circle" : "checkmark.circle"
                                        )
                                    }

                                    Button(role: .destructive) {
                                        viewModel.deleteEvent(event, context: modelContext)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteEvent(event, context: modelContext)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        viewModel.toggleComplete(event, context: modelContext)
                                    } label: {
                                        Label(
                                            event.isCompleted ? "未完成" : "完成",
                                            systemImage: event.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(Color.theme.received)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
