//
//  CalendarViewModel.swift
//  LiShangJi
//
//  Created on 2026/2/9.
//

import Foundation
import SwiftData

/// 日历视图模式
enum EventViewMode: String, CaseIterable {
    case list = "列表"
    case calendar = "日历"
}

/// 日历视图 ViewModel
@Observable
class CalendarViewModel {
    /// 当前显示月份
    var currentMonth: Date = Date()

    /// 用户选中的日期
    var selectedDate: Date? = Date()

    /// 选中日期对应的事件
    var eventsForSelectedDate: [EventReminder] = []

    /// 选中日期对应的节日列表
    var festivalsForSelectedDate: [(name: String, lunarDate: String)] = []

    /// 当月有事件的日期 key 集合（格式 "yyyy-MM-dd"）
    var eventDateKeys: Set<String> = []

    /// 当月节日映射：dateKey -> 节日名称
    var festivalDateMap: [String: String] = [:]

    private let calendar = Calendar.current
    private let lunarService = LunarCalendarService.shared

    // MARK: - 加载当月数据

    /// 根据全部事件列表，计算当月有事件的日期集合以及节日映射
    func loadMonth(events: [EventReminder]) {
        loadEventDateKeys(events: events)
        loadFestivalDateMap()

        // 同步刷新选中日期的事件
        if let date = selectedDate {
            selectDate(date, events: events)
        }
    }

    /// 选择一个日期，更新当日事件和节日信息
    func selectDate(_ date: Date, events: [EventReminder]) {
        selectedDate = date

        // 筛选选中日期的事件
        eventsForSelectedDate = events.filter { event in
            calendar.isDate(event.eventDate, inSameDayAs: date)
        }.sorted { $0.eventDate < $1.eventDate }

        // 查询选中日期的节日
        festivalsForSelectedDate = []
        if let festivalName = lunarService.festivalName(for: date) {
            let lunarDate = lunarService.lunarDateString(from: date)
            festivalsForSelectedDate.append((name: festivalName, lunarDate: lunarDate))
        }
    }

    // MARK: - 月份切换

    /// 切换月份。offset = -1 上月, 1 下月, 0 回到今天所在月
    func changeMonth(by offset: Int) {
        if offset == 0 {
            currentMonth = Date()
            selectedDate = Date()
        } else {
            if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
                currentMonth = newMonth
                // 切换月份后自动选中当月第一天（如果是当月则选今天）
                if calendar.isDate(newMonth, equalTo: Date(), toGranularity: .month) {
                    selectedDate = Date()
                } else {
                    let components = calendar.dateComponents([.year, .month], from: newMonth)
                    selectedDate = calendar.date(from: components)
                }
            }
        }
    }

    /// 回到今天
    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
    }

    // MARK: - Private

    /// 计算当月中有事件的日期 key 集合
    private func loadEventDateKeys(events: [EventReminder]) {
        let monthStart = firstDayOfMonth(currentMonth)
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return }

        var keys = Set<String>()
        for event in events {
            if event.eventDate >= monthStart && event.eventDate < monthEnd {
                keys.insert(CalendarGridView.dateKey(for: event.eventDate))
            }
        }
        eventDateKeys = keys
    }

    /// 计算当月的节日映射
    private func loadFestivalDateMap() {
        let monthStart = firstDayOfMonth(currentMonth)
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31

        var map: [String: String] = [:]
        for dayOffset in 0..<range.count {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }
            if let festivalName = lunarService.festivalName(for: date) {
                let key = CalendarGridView.dateKey(for: date)
                map[key] = festivalName
            }
        }
        festivalDateMap = map
    }

    /// 获取指定月份的第一天
    private func firstDayOfMonth(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}
