//
//  EventStatisticsViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import Foundation
import SwiftData

/// 事件类别统计数据
struct EventCategoryStat: Identifiable {
    let id = UUID()
    let category: EventCategory
    let count: Int
    let completedCount: Int
}

/// 事件月度统计数据
struct EventMonthlyTrend: Identifiable {
    let id = UUID()
    let month: String
    let totalCount: Int
    let completedCount: Int
}

/// 事件统计 ViewModel
@Observable
class EventStatisticsViewModel {
    var totalCount: Int = 0
    var completedCount: Int = 0
    var pendingCount: Int = 0
    var overdueCount: Int = 0
    var completionRate: Double = 0.0
    var categoryStats: [EventCategoryStat] = []
    var monthlyTrends: [EventMonthlyTrend] = []
    var upcomingEvents: [EventReminder] = []
    var errorMessage: String?

    private let repository = EventReminderRepository()

    /// 加载统计数据
    func loadData(from events: [EventReminder]) {
        totalCount = events.count
        completedCount = events.filter { $0.isCompleted }.count
        overdueCount = events.filter { $0.isOverdue }.count
        pendingCount = totalCount - completedCount
        completionRate = totalCount > 0 ? Double(completedCount) / Double(totalCount) * 100 : 0

        loadCategoryStats(events: events)
        loadMonthlyTrends(events: events)
        loadUpcomingEvents(events: events)
    }

    // MARK: - 按类别统计

    private func loadCategoryStats(events: [EventReminder]) {
        let grouped = Dictionary(grouping: events) { $0.eventCategory }
        categoryStats = grouped.map { key, value in
            let category = EventCategory(rawValue: key) ?? .other
            let completed = value.filter { $0.isCompleted }.count
            return EventCategoryStat(category: category, count: value.count, completedCount: completed)
        }
        .sorted { $0.count > $1.count }
    }

    // MARK: - 按月份统计趋势

    private func loadMonthlyTrends(events: [EventReminder]) {
        let calendar = Calendar.current
        var trends: [EventMonthlyTrend] = []

        // 最近 6 个月
        for i in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let components = calendar.dateComponents([.year, .month], from: monthDate)
            guard let year = components.year, let month = components.month else { continue }

            let monthStr = "\(month)月"

            let monthEvents = events.filter { event in
                let rc = calendar.dateComponents([.year, .month], from: event.eventDate)
                return rc.year == year && rc.month == month
            }

            let total = monthEvents.count
            let completed = monthEvents.filter { $0.isCompleted }.count

            trends.append(EventMonthlyTrend(
                month: monthStr,
                totalCount: total,
                completedCount: completed
            ))
        }

        monthlyTrends = trends
    }

    // MARK: - 即将到来的事件

    private func loadUpcomingEvents(events: [EventReminder]) {
        upcomingEvents = events
            .filter { !$0.isCompleted && $0.eventDate >= Date() }
            .sorted { $0.eventDate < $1.eventDate }
            .prefix(5)
            .map { $0 }
    }
}
