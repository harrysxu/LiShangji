//
//  HomeViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 首页 ViewModel
@Observable
class HomeViewModel {
    var totalReceived: Double = 0
    var totalSent: Double = 0
    var recentRecords: [GiftRecord] = []
    var upcomingEvents: [EventReminder] = []
    var totalRecordCount: Int = 0
    var errorMessage: String?

    var balance: Double {
        totalReceived - totalSent
    }

    private let recordRepository = GiftRecordRepository()
    private let eventReminderRepository = EventReminderRepository()

    /// 加载首页数据
    func loadData(context: ModelContext) {
        do {
            // 获取本月数据
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

            let monthRecords = try recordRepository.fetchByDateRange(from: startOfMonth, to: startOfNextMonth, context: context)

            totalReceived = monthRecords
                .filter { $0.direction == GiftDirection.received.rawValue }
                .reduce(0) { $0 + $1.giftStatsAmount }

            totalSent = monthRecords
                .filter { $0.direction == GiftDirection.sent.rawValue }
                .reduce(0) { $0 + $1.giftStatsAmount }

            // 获取最近记录（限制10条）
            recentRecords = try recordRepository.fetchRecent(limit: 10, context: context)

            // 获取待办与提醒（过期/今天优先，限制3条）
            upcomingEvents = try fetchPendingEvents(limit: 3, context: context)

            // 获取总记录数（用于判断是否需要刷新）
            totalRecordCount = try fetchRecordCount(context: context)

            errorMessage = nil
        } catch {
            errorMessage = "加载数据失败: \(error.localizedDescription)"
        }
    }

    /// 获取待办与提醒（过期/今天优先）
    private func fetchPendingEvents(limit: Int, context: ModelContext) throws -> [EventReminder] {
        let predicate = #Predicate<EventReminder> { event in
            event.isCompleted == false
        }
        let descriptor = FetchDescriptor<EventReminder>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .forward)]
        )
        let events = try context.fetch(descriptor)
        return Array(events.sorted { lhs, rhs in
            let lhsDay = Calendar.current.startOfDay(for: lhs.eventDate)
            let rhsDay = Calendar.current.startOfDay(for: rhs.eventDate)
            return lhsDay < rhsDay
        }.prefix(limit))
    }

    /// 获取记录总数（轻量查询）
    private func fetchRecordCount(context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<GiftRecord>()
        return try context.fetchCount(descriptor)
    }
}
