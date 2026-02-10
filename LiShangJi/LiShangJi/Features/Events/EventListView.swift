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
    @State private var calendarVM = CalendarViewModel()
    @State private var viewMode: EventViewMode = .list
    @State private var showingAddEvent = false
    @State private var showingStatistics = false
    @State private var selectedEvent: EventReminder?
    @State private var showPurchaseView = false
    @AppStorage("lunarSectionExpanded") private var lunarSectionExpanded = true

    // 农历节日快速创建
    @State private var festivalPrefillTitle: String?
    @State private var festivalPrefillDate: Date?
    @State private var festivalPrefillCategory: EventCategory?
    @State private var showingFestivalForm = false

    private let lunarService = LunarCalendarService.shared

    private var canAddEvent: Bool {
        PremiumManager.shared.isPremium || allEvents.count < PremiumManager.FreeLimit.maxEventReminders
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部操作栏
            headerSection

            // 列表/日历 切换
            viewModePicker

            ScrollView {
                VStack(spacing: AppConstants.Spacing.lg) {
                    if viewMode == .calendar {
                        // 日历模式
                        calendarSection
                    } else {
                        // 列表模式
                        listSection
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.bottom, AppConstants.Spacing.xxxl)
            }
        }
        .lsjPageBackground()
        .navigationTitle("事件与节日")
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
                        if canAddEvent {
                            showingAddEvent = true
                        } else {
                            showPurchaseView = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.theme.primary)
                    }
                    .debounced()
                }
            }
        }
        .onChange(of: allEvents.count) {
            if viewMode == .calendar {
                calendarVM.loadMonth(events: allEvents)
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            EventFormView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingFestivalForm) {
            EventFormView(
                prefillTitle: festivalPrefillTitle,
                prefillDate: festivalPrefillDate,
                prefillCategory: festivalPrefillCategory
            )
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
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView()
        }
    }

    // MARK: - 视图模式切换

    private var viewModePicker: some View {
        Picker("视图模式", selection: $viewMode) {
            ForEach(EventViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, AppConstants.Spacing.sm)
        .onChange(of: viewMode) {
            if viewMode == .calendar {
                calendarVM.loadMonth(events: allEvents)
            }
        }
    }

    // MARK: - 列表模式

    private var listSection: some View {
        Group {
            // 农历与节日卡片
            lunarFestivalSection

            // 搜索栏
            searchBar

            // 筛选标签
            filterSection

            // 事件列表
            eventListSection
        }
    }

    // MARK: - 日历模式

    private var calendarSection: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // 日历网格
            CalendarGridView(
                currentMonth: calendarVM.currentMonth,
                selectedDate: calendarVM.selectedDate,
                eventDateKeys: calendarVM.eventDateKeys,
                festivalDateMap: calendarVM.festivalDateMap,
                onSelectDate: { date in
                    withAnimation(AppConstants.Animation.defaultSpring) {
                        calendarVM.selectDate(date, events: allEvents)
                    }
                },
                onChangeMonth: { offset in
                    withAnimation(AppConstants.Animation.defaultSpring) {
                        calendarVM.changeMonth(by: offset)
                        calendarVM.loadMonth(events: allEvents)
                    }
                }
            )

            // 选中日期的标题
            if let selectedDate = calendarVM.selectedDate {
                selectedDateHeader(for: selectedDate)
            }

            // 选中日期的节日
            if !calendarVM.festivalsForSelectedDate.isEmpty {
                calendarFestivalSection
            }

            // 选中日期的事件
            calendarEventSection
        }
    }

    /// 选中日期标题栏
    private func selectedDateHeader(for date: Date) -> some View {
        let lunar = lunarService.solarToLunar(date: date)
        let isToday = Calendar.current.isDateInToday(date)

        return HStack(spacing: AppConstants.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppConstants.Spacing.sm) {
                    Text(date.chineseFullDate)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)
                    if isToday {
                        Text("今天")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.theme.primary)
                            .clipShape(Capsule())
                    }
                }
                Text("农历\(lunar.monthName)月\(lunar.dayName)")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            Spacer()

            // 快速添加事件按钮
            Button {
                HapticManager.shared.selection()
                festivalPrefillDate = date
                festivalPrefillTitle = nil
                festivalPrefillCategory = nil
                showingFestivalForm = true
            } label: {
                Label("添加", systemImage: "plus")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.theme.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }

    /// 日历模式 - 选中日期的节日
    private var calendarFestivalSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("节日")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.theme.textSecondary)

            LSJCard {
                VStack(spacing: 0) {
                    ForEach(Array(calendarVM.festivalsForSelectedDate.enumerated()), id: \.offset) { index, festival in
                        HStack(spacing: AppConstants.Spacing.md) {
                            Image(systemName: festivalIcon(for: festival.name))
                                .font(.body)
                                .foregroundStyle(Color.theme.warning)
                                .frame(width: 32, height: 32)
                                .background(Color.theme.warning.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(festival.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("农历 \(festival.lunarDate)")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }

                            Spacer()

                            // 快速创建提醒
                            Button {
                                HapticManager.shared.selection()
                                festivalPrefillTitle = festival.name
                                festivalPrefillDate = calendarVM.selectedDate
                                festivalPrefillCategory = festivalCategory(for: festival.name)
                                showingFestivalForm = true
                            } label: {
                                Text("创建提醒")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.theme.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.theme.primary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, AppConstants.Spacing.xs)

                        if index < calendarVM.festivalsForSelectedDate.count - 1 {
                            Divider().foregroundStyle(Color.theme.divider)
                        }
                    }
                }
            }
        }
    }

    /// 日历模式 - 选中日期的事件列表
    private var calendarEventSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            Text("事件")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.theme.textSecondary)

            if calendarVM.eventsForSelectedDate.isEmpty && calendarVM.festivalsForSelectedDate.isEmpty {
                LSJCard {
                    VStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.3))
                        Text("当天无事件")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.Spacing.xl)
                }
            } else if calendarVM.eventsForSelectedDate.isEmpty {
                LSJCard {
                    VStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.3))
                        Text("暂无事件提醒")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.Spacing.lg)
                }
            } else {
                ForEach(calendarVM.eventsForSelectedDate) { event in
                    EventCard(event: event) {
                        viewModel.toggleComplete(event, context: modelContext)
                        calendarVM.selectDate(calendarVM.selectedDate ?? Date(), events: allEvents)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
                    .contextMenu {
                        Button {
                            viewModel.toggleComplete(event, context: modelContext)
                            calendarVM.selectDate(calendarVM.selectedDate ?? Date(), events: allEvents)
                        } label: {
                            Label(
                                event.isCompleted ? "标记未完成" : "标记完成",
                                systemImage: event.isCompleted ? "circle" : "checkmark.circle"
                            )
                        }

                        Button(role: .destructive) {
                            viewModel.deleteEvent(event, context: modelContext)
                            calendarVM.loadMonth(events: allEvents)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
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

    // MARK: - 农历与节日卡片

    private var lunarFestivalSection: some View {
        let todayLunar = lunarService.solarToLunar(date: Date())
        let festivals = upcomingFestivals

        return VStack(spacing: 0) {
            // 今日农历 + 折叠按钮
            Button {
                withAnimation(AppConstants.Animation.defaultSpring) {
                    lunarSectionExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppConstants.Spacing.sm) {
                    Image(systemName: "moon.stars.fill")
                        .font(.body)
                        .foregroundStyle(Color.theme.primary)

                    Text("农历\(todayLunar.monthName)月\(todayLunar.dayName)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.textPrimary)

                    Text("·")
                        .foregroundStyle(Color.theme.textSecondary)

                    Text("\(todayLunar.yearGanZhi)\(todayLunar.shengXiao)年")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)

                    if let festival = lunarService.festivalName(for: Date()) {
                        Text("· \(festival)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.theme.warning)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.theme.textSecondary)
                        .rotationEffect(.degrees(lunarSectionExpanded ? 0 : -90))
                }
                .padding(AppConstants.Spacing.md)
                .background(Color.theme.card)
                .clipShape(RoundedRectangle(cornerRadius: lunarSectionExpanded ? AppConstants.Radius.sm : AppConstants.Radius.sm))
            }
            .buttonStyle(.plain)

            // 展开后的节日列表
            if lunarSectionExpanded && !festivals.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(festivals.prefix(3).enumerated()), id: \.offset) { index, festival in
                        HStack(spacing: AppConstants.Spacing.md) {
                            Image(systemName: festivalIcon(for: festival.name))
                                .font(.body)
                                .foregroundStyle(Color.theme.warning)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(festival.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("农历 \(festival.lunarDate)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }

                            Spacer()

                            Text(festival.date.chineseMonthDay)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)

                            Text(daysUntilText(festival.date))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.theme.primary)
                                .frame(width: 48, alignment: .trailing)

                            // 快速创建提醒按钮
                            Button {
                                HapticManager.shared.selection()
                                festivalPrefillTitle = festival.name
                                festivalPrefillDate = festival.date
                                festivalPrefillCategory = festivalCategory(for: festival.name)
                                showingFestivalForm = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(Color.theme.primary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, AppConstants.Spacing.md)
                        .padding(.vertical, AppConstants.Spacing.sm)

                        if index < min(festivals.count, 3) - 1 {
                            Divider()
                                .foregroundStyle(Color.theme.divider)
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color.theme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                .padding(.top, 1)
            }
        }
    }

    // MARK: - 农历辅助方法

    /// 获取未来 90 天内的节日列表
    private var upcomingFestivals: [(name: String, date: Date, lunarDate: String)] {
        let calendar = Calendar.current
        var festivals: [(name: String, date: Date, lunarDate: String)] = []

        for dayOffset in 1..<90 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            if let festivalName = lunarService.festivalName(for: date) {
                let lunar = lunarService.lunarDateString(from: date)
                festivals.append((name: festivalName, date: date, lunarDate: lunar))
            }
        }

        return festivals
    }

    /// 节日名称映射到事件类别
    private func festivalCategory(for festivalName: String) -> EventCategory {
        switch festivalName {
        case "春节": return .springFestival
        case "中秋节": return .midAutumn
        case "端午节": return .dragonBoat
        default: return .other
        }
    }

    /// 节日图标
    private func festivalIcon(for festivalName: String) -> String {
        switch festivalName {
        case "春节", "小年": return "fireworks"
        case "元宵节": return "moon.haze.fill"
        case "端午节": return "sailboat.fill"
        case "七夕节": return "heart.fill"
        case "中秋节": return "moon.fill"
        case "重阳节": return "leaf.fill"
        case "腊八节": return "cup.and.saucer.fill"
        default: return "star.fill"
        }
    }

    /// 距离日期的文本描述
    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days == 0 { return "今天" }
        if days == 1 { return "明天" }
        if days == 2 { return "后天" }
        return "\(days)天后"
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
                    if canAddEvent {
                        showingAddEvent = true
                    } else {
                        showPurchaseView = true
                    }
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
