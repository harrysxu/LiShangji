//
//  StatisticsViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 时间范围筛选
enum StatisticsTimeFilter: Equatable {
    case allTime
    case year(Int)

    var displayName: String {
        switch self {
        case .allTime: return "全部"
        case .year(let y): return "\(y)年"
        }
    }
}

/// 月度收支数据
struct MonthlyTrend: Identifiable {
    let id = UUID()
    let month: String
    let monthDate: Date
    let amount: Double
    let direction: String // "收到" / "送出"
}

/// 关系分组统计
struct RelationGroupStat: Identifiable {
    let id = UUID()
    let relation: String
    let totalAmount: Double
    let recordCount: Int
    let color: String
}

/// 统计 ViewModel
@Observable
class StatisticsViewModel {
    var totalReceived: Double = 0
    var totalSent: Double = 0
    var recordCount: Int = 0
    var errorMessage: String?
    var monthlyTrends: [MonthlyTrend] = []
    var relationStats: [RelationGroupStat] = []
    var topContacts: [(name: String, received: Double, sent: Double)] = []
    var isLoading: Bool = false

    /// 时间筛选
    var timeFilter: StatisticsTimeFilter = .allTime
    /// 可选年份列表（从记录中提取）
    var availableYears: [Int] = []

    var balance: Double {
        totalReceived - totalSent
    }

    private let recordRepository = GiftRecordRepository()

    /// 加载统计数据（使用 predicate 按年份过滤，避免全量加载）
    func loadData(context: ModelContext) {
        do {
            // 仅在首次或"全部"模式下提取可选年份（轻量查询）
            if availableYears.isEmpty {
                let allRecords = try recordRepository.fetchAll(context: context)
                let calendar = Calendar.current
                let years = Set(allRecords.map { calendar.component(.year, from: $0.eventDate) })
                availableYears = years.sorted(by: >)
            }

            // 使用 predicate 按年份过滤，避免加载全部记录
            let filteredRecords = try fetchFilteredRecords(context: context)

            recordCount = filteredRecords.count

            let receivedValue = GiftDirection.received.rawValue
            let sentValue = GiftDirection.sent.rawValue

            totalReceived = filteredRecords
                .filter { $0.direction == receivedValue }
                .reduce(0) { $0 + $1.amount }

            totalSent = filteredRecords
                .filter { $0.direction == sentValue }
                .reduce(0) { $0 + $1.amount }

            loadMonthlyTrends(records: filteredRecords)
            loadRelationStats(records: filteredRecords)
            loadTopContacts(records: filteredRecords)

            errorMessage = nil
        } catch {
            errorMessage = "加载统计失败: \(error.localizedDescription)"
        }
    }

    /// 按时间范围过滤查询记录（使用数据库 predicate）
    private func fetchFilteredRecords(context: ModelContext) throws -> [GiftRecord] {
        switch timeFilter {
        case .allTime:
            return try recordRepository.fetchAll(context: context)
        case .year(let year):
            let calendar = Calendar.current
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            guard let startDate = calendar.date(from: startComponents) else {
                return []
            }
            var endComponents = DateComponents()
            endComponents.year = year + 1
            endComponents.month = 1
            endComponents.day = 1
            guard let endDate = calendar.date(from: endComponents) else {
                return []
            }
            return try recordRepository.fetchByDateRange(from: startDate, to: endDate, context: context)
        }
    }

    /// 计算月度收支趋势（最近12个月或指定年份的12个月）
    private func loadMonthlyTrends(records: [GiftRecord]) {
        let calendar = Calendar.current
        var trends: [MonthlyTrend] = []

        // 预先按 (year, month) 分组，避免对每个月都遍历全部记录
        let groupedByMonth = Dictionary(grouping: records) { record -> String in
            let c = calendar.dateComponents([.year, .month], from: record.eventDate)
            return "\(c.year ?? 0)-\(c.month ?? 0)"
        }

        let receivedValue = GiftDirection.received.rawValue
        let sentValue = GiftDirection.sent.rawValue

        switch timeFilter {
        case .allTime:
            for i in (0..<12).reversed() {
                guard let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
                let components = calendar.dateComponents([.year, .month], from: monthDate)
                guard let year = components.year, let month = components.month else { continue }

                let monthStr = "\(month)月"
                let key = "\(year)-\(month)"
                let monthRecords = groupedByMonth[key] ?? []

                let received = monthRecords
                    .filter { $0.direction == receivedValue }
                    .reduce(0.0) { $0 + $1.amount }
                let sent = monthRecords
                    .filter { $0.direction == sentValue }
                    .reduce(0.0) { $0 + $1.amount }

                if received > 0 || sent > 0 || i < 6 {
                    trends.append(MonthlyTrend(month: monthStr, monthDate: monthDate, amount: received, direction: "收到"))
                    trends.append(MonthlyTrend(month: monthStr, monthDate: monthDate, amount: sent, direction: "送出"))
                }
            }

        case .year(let year):
            for month in 1...12 {
                var components = DateComponents()
                components.year = year
                components.month = month
                guard let monthDate = calendar.date(from: components) else { continue }

                let monthStr = "\(month)月"
                let key = "\(year)-\(month)"
                let monthRecords = groupedByMonth[key] ?? []

                let received = monthRecords
                    .filter { $0.direction == receivedValue }
                    .reduce(0.0) { $0 + $1.amount }
                let sent = monthRecords
                    .filter { $0.direction == sentValue }
                    .reduce(0.0) { $0 + $1.amount }

                if received > 0 || sent > 0 {
                    trends.append(MonthlyTrend(month: monthStr, monthDate: monthDate, amount: received, direction: "收到"))
                    trends.append(MonthlyTrend(month: monthStr, monthDate: monthDate, amount: sent, direction: "送出"))
                }
            }
        }

        monthlyTrends = trends
    }

    /// 按关系类型分组统计
    private func loadRelationStats(records: [GiftRecord]) {
        let grouped = Dictionary(grouping: records) { record -> String in
            if let contact = record.contact {
                return contact.relationType.displayName
            }
            return "未分类"
        }

        let colors = ["#C04851", "#4A9B7F", "#6B7280", "#D4915E", "#8B7EC8", "#3B82F6", "#EC4899", "#10B981"]

        relationStats = grouped.enumerated().map { index, item in
            RelationGroupStat(
                relation: item.key,
                totalAmount: item.value.reduce(0) { $0 + $1.amount },
                recordCount: item.value.count,
                color: colors[index % colors.count]
            )
        }
        .sorted { $0.totalAmount > $1.totalAmount }
    }

    /// 往来金额 Top 联系人
    private func loadTopContacts(records: [GiftRecord]) {
        let recordsWithContact = records.filter { $0.contact != nil }
        let grouped = Dictionary(grouping: recordsWithContact) { (record: GiftRecord) -> String in
            record.contact?.name ?? "未知"
        }

        let receivedValue = GiftDirection.received.rawValue
        let sentValue = GiftDirection.sent.rawValue

        let mapped: [(name: String, received: Double, sent: Double)] = grouped.map { item in
            let name = item.key
            let contactRecords = item.value
            let received = contactRecords
                .filter { $0.direction == receivedValue }
                .reduce(0.0) { $0 + $1.amount }
            let sent = contactRecords
                .filter { $0.direction == sentValue }
                .reduce(0.0) { $0 + $1.amount }
            return (name: name, received: received, sent: sent)
        }

        let sorted = mapped.sorted { lhs, rhs in
            (lhs.received + lhs.sent) > (rhs.received + rhs.sent)
        }

        topContacts = Array(sorted.prefix(10))
    }
}
