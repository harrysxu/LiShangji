//
//  CalendarGridView.swift
//  LiShangJi
//
//  Created on 2026/2/9.
//

import SwiftUI

/// 月历网格组件
/// 展示一个月的日历视图，包含公历日期、农历信息、节日高亮和事件标记
struct CalendarGridView: View {
    let currentMonth: Date
    let selectedDate: Date?
    /// 有事件的日期 key（格式 "yyyy-MM-dd"）
    let eventDateKeys: Set<String>
    /// 日期 key -> 节日名称 映射
    let festivalDateMap: [String: String]

    var onSelectDate: ((Date) -> Void)?
    var onChangeMonth: ((Int) -> Void)?

    private let calendar = Calendar.current
    private let lunarService = LunarCalendarService.shared
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 月份导航头部
            monthHeader

            // 星期表头
            weekdayHeader

            // 日期网格
            dateGrid
        }
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - 月份导航

    private var monthHeader: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Button {
                HapticManager.shared.selection()
                onChangeMonth?(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthYearString)
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)

                // 农历年信息
                let lunarInfo = lunarService.solarToLunar(date: firstDayOfMonth)
                Text("\(lunarInfo.yearGanZhi)\(lunarInfo.shengXiao)年")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()

            // 如果不在当月，显示"今天"按钮
            if !isCurrentMonth {
                Button {
                    HapticManager.shared.selection()
                    onChangeMonth?(0) // 0 表示回到今天
                } label: {
                    Text("今天")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.theme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.theme.primary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Button {
                HapticManager.shared.selection()
                onChangeMonth?(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, AppConstants.Spacing.md)
        .padding(.vertical, AppConstants.Spacing.sm)
    }

    // MARK: - 星期表头

    private var weekdayHeader: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(
                            day == "日" || day == "六"
                                ? Color.theme.sent.opacity(0.8)
                                : Color.theme.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.Spacing.xs)
                }
            }
            .padding(.horizontal, AppConstants.Spacing.xs)

            Divider().foregroundStyle(Color.theme.divider)
        }
    }

    // MARK: - 日期网格

    private var dateGrid: some View {
        let days = generateDays()

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let date = day {
                    dayCellView(for: date)
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            onSelectDate?(date)
                        }
                } else {
                    // 空白占位
                    Color.clear
                        .frame(height: 58)
                }
            }
        }
        .padding(.horizontal, AppConstants.Spacing.xs)
        .padding(.bottom, AppConstants.Spacing.sm)
    }

    // MARK: - 单日单元格

    private func dayCellView(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let dateKey = Self.dateKey(for: date)
        let hasEvent = eventDateKeys.contains(dateKey)
        let festivalName = festivalDateMap[dateKey]
        let isWeekend = calendar.component(.weekday, from: date) == 1 || calendar.component(.weekday, from: date) == 7

        // 农历信息
        let lunar = lunarService.solarToLunar(date: date)
        let lunarText = festivalName ?? lunar.dayName

        return VStack(spacing: 1) {
            // 公历日期
            Text("\(day)")
                .font(.system(size: 16, weight: isToday || isSelected ? .bold : .regular, design: .rounded))
                .foregroundStyle(dayTextColor(isToday: isToday, isSelected: isSelected, isWeekend: isWeekend))

            // 农历 / 节日
            Text(lunarText)
                .font(.system(size: 8))
                .foregroundStyle(
                    festivalName != nil
                        ? Color.theme.warning
                        : (isSelected ? Color.theme.primary : Color.theme.textSecondary)
                )
                .lineLimit(1)

            // 事件标记圆点
            if hasEvent {
                Circle()
                    .fill(Color.theme.primary)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(
            Group {
                if isToday && isSelected {
                    Circle()
                        .fill(Color.theme.primary)
                        .frame(width: 44, height: 44)
                } else if isToday {
                    Circle()
                        .fill(Color.theme.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                } else if isSelected {
                    Circle()
                        .fill(Color.theme.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                }
            }
        )
    }

    // MARK: - 辅助方法

    private func dayTextColor(isToday: Bool, isSelected: Bool, isWeekend: Bool) -> Color {
        if isToday && isSelected {
            return .white
        } else if isToday {
            return Color.theme.primary
        } else if isSelected {
            return Color.theme.primary
        } else if isWeekend {
            return Color.theme.sent.opacity(0.8)
        }
        return Color.theme.textPrimary
    }

    /// 当前月的第一天
    private var firstDayOfMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        return calendar.date(from: components) ?? currentMonth
    }

    /// 是否当月
    private var isCurrentMonth: Bool {
        calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }

    /// 年月字符串
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    /// 生成当月的日期数组，前面用 nil 填充空白
    private func generateDays() -> [Date?] {
        let first = firstDayOfMonth
        let weekday = calendar.component(.weekday, from: first) // 1=周日
        let range = calendar.range(of: .day, in: .month, for: first) ?? 1..<31
        let daysCount = range.count

        // 前置空白
        var days: [Date?] = Array(repeating: nil, count: weekday - 1)

        // 填充日期
        for day in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: day, to: first) {
                days.append(date)
            }
        }

        return days
    }

    /// 将 Date 转为 "yyyy-MM-dd" 格式的 key
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
