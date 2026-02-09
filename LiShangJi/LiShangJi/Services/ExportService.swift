//
//  ExportService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData
import UIKit

/// 数据导出服务 - 支持 CSV 导出
class ExportService {
    static let shared = ExportService()
    private init() {}

    // MARK: - 导出账本为 CSV

    /// 导出单个账本为 CSV 文件
    func exportBookToCSV(book: GiftBook) throws -> URL {
        let records = (book.records ?? []).sorted { $0.eventDate > $1.eventDate }
        return try exportRecordsToCSV(records: records, fileName: book.name)
    }

    /// 导出全部记录为 CSV 文件
    func exportAllToCSV(context: ModelContext) throws -> URL {
        let descriptor = FetchDescriptor<GiftRecord>(
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        let records = try context.fetch(descriptor)
        return try exportRecordsToCSV(records: records, fileName: "礼尚记全部数据")
    }

    /// 导出记录为 CSV
    private func exportRecordsToCSV(records: [GiftRecord], fileName: String) throws -> URL {
        // BOM 标识 + CSV 表头
        var csv = "\u{FEFF}序号,姓名,关系,金额,收/送,事件类型,事件名称,日期,备注,账本\n"

        for (index, record) in records.enumerated() {
            let direction = record.isReceived ? "收到" : "送出"
            let name = escapeCSV(record.contact?.name ?? "未知")
            let relation = escapeCSV(record.contact?.relationType.displayName ?? "")
            let eventCategory = escapeCSV(record.giftEventCategory.displayName)
            let eventName = escapeCSV(record.eventName)
            let dateStr = record.eventDate.chineseFullDate
            let note = escapeCSV(record.note)
            let bookName = escapeCSV(record.book?.name ?? "")

            csv += "\(index + 1),\(name),\(relation),\(record.amount),\(direction),"
            csv += "\(eventCategory),\(eventName),\(dateStr),\(note),\(bookName)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let sanitizedName = fileName.replacingOccurrences(of: "/", with: "_")
        let fileURL = tempDir.appendingPathComponent("\(sanitizedName)_\(dateString()).csv")
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - 导出联系人为 CSV

    func exportContactsToCSV(context: ModelContext) throws -> URL {
        let descriptor = FetchDescriptor<Contact>(
            sortBy: [SortDescriptor(\.name)]
        )
        let contacts = try context.fetch(descriptor)

        var csv = "\u{FEFF}姓名,关系,电话,总收到,总送出,差额,往来笔数,备注\n"

        for contact in contacts {
            let name = escapeCSV(contact.name)
            let relation = escapeCSV(contact.relationType.displayName)
            let phone = escapeCSV(contact.phone)
            let note = escapeCSV(contact.note)

            csv += "\(name),\(relation),\(phone),\(contact.totalReceived),\(contact.totalSent),"
            csv += "\(contact.balance),\(contact.recordCount),\(note)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("礼尚记联系人_\(dateString()).csv")
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - 按条件筛选导出记录

    /// 按账本和时间范围筛选导出记录为 CSV
    func exportFilteredRecordsToCSV(
        context: ModelContext,
        bookIDs: Set<UUID>?,
        startDate: Date?,
        endDate: Date?
    ) throws -> URL {
        let descriptor = FetchDescriptor<GiftRecord>(
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        var records = try context.fetch(descriptor)

        // 按账本筛选
        if let bookIDs, !bookIDs.isEmpty {
            records = records.filter { record in
                guard let bookID = record.book?.id else { return false }
                return bookIDs.contains(bookID)
            }
        }

        // 按时间范围筛选
        if let startDate {
            records = records.filter { $0.eventDate >= startDate }
        }
        if let endDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
            records = records.filter { $0.eventDate < endOfDay }
        }

        return try exportRecordsToCSV(records: records, fileName: "礼尚记记录数据")
    }

    // MARK: - 导出提醒事件为 CSV

    /// 导出提醒事件为 CSV，支持时间范围筛选
    func exportEventRemindersToCSV(
        context: ModelContext,
        startDate: Date?,
        endDate: Date?
    ) throws -> URL {
        let descriptor = FetchDescriptor<EventReminder>(
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        var events = try context.fetch(descriptor)

        // 按时间范围筛选
        if let startDate {
            events = events.filter { $0.eventDate >= startDate }
        }
        if let endDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
            events = events.filter { $0.eventDate < endOfDay }
        }

        var csv = "\u{FEFF}序号,标题,事件类别,事件日期,提醒选项,提醒时间,关联联系人,状态,备注\n"

        for (index, event) in events.enumerated() {
            let title = escapeCSV(event.title)
            let category = escapeCSV(event.category.displayName)
            let eventDateStr = event.eventDate.chineseFullDate
            let reminderOptionStr = escapeCSV(event.reminder.displayName)
            let reminderDateStr = event.reminderDate?.chineseFullDate ?? "无"
            let contactNames = escapeCSV(event.contactNames)
            let status: String
            if event.isCompleted {
                status = "已完成"
            } else if event.isOverdue {
                status = "已过期"
            } else {
                status = "待处理"
            }
            let note = escapeCSV(event.note)

            csv += "\(index + 1),\(title),\(category),\(eventDateStr),\(reminderOptionStr),"
            csv += "\(reminderDateStr),\(contactNames),\(status),\(note)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("礼尚记提醒事件_\(dateString()).csv")
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - 导出统计数据为 CSV

    /// 导出统计数据为 CSV（月度汇总 + 关系分布 + Top联系人）
    func exportStatisticsToCSV(
        context: ModelContext,
        startDate: Date?,
        endDate: Date?
    ) throws -> URL {
        let descriptor = FetchDescriptor<GiftRecord>(
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        var allRecords = try context.fetch(descriptor)

        // 按时间范围筛选
        if let startDate {
            allRecords = allRecords.filter { $0.eventDate >= startDate }
        }
        if let endDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
            allRecords = allRecords.filter { $0.eventDate < endOfDay }
        }

        let receivedValue = GiftDirection.received.rawValue
        let sentValue = GiftDirection.sent.rawValue

        let totalReceived = allRecords.filter { $0.direction == receivedValue }.reduce(0.0) { $0 + $1.amount }
        let totalSent = allRecords.filter { $0.direction == sentValue }.reduce(0.0) { $0 + $1.amount }

        var csv = "\u{FEFF}"

        // Part 1: 总览
        csv += "=== 总览 ===\n"
        csv += "总收到,总送出,差额,总笔数\n"
        csv += "\(totalReceived),\(totalSent),\(totalReceived - totalSent),\(allRecords.count)\n\n"

        // Part 2: 月度收支汇总
        csv += "=== 月度收支汇总 ===\n"
        csv += "月份,收到金额,送出金额,差额,笔数\n"

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allRecords) { record -> String in
            let components = calendar.dateComponents([.year, .month], from: record.eventDate)
            return "\(components.year ?? 0)年\(components.month ?? 0)月"
        }

        // 按日期排序
        let sortedMonths = grouped.keys.sorted { a, b in
            // 简单按字符串排序，格式 "YYYY年M月" 可以自然排序
            a < b
        }

        for month in sortedMonths {
            guard let monthRecords = grouped[month] else { continue }
            let received = monthRecords.filter { $0.direction == receivedValue }.reduce(0.0) { $0 + $1.amount }
            let sent = monthRecords.filter { $0.direction == sentValue }.reduce(0.0) { $0 + $1.amount }
            csv += "\(month),\(received),\(sent),\(received - sent),\(monthRecords.count)\n"
        }

        // Part 3: 关系分布
        csv += "\n=== 关系分布 ===\n"
        csv += "关系类型,总金额,笔数\n"

        let relationGrouped = Dictionary(grouping: allRecords) { record -> String in
            record.contact?.relationType.displayName ?? "未分类"
        }
        let sortedRelations = relationGrouped.sorted { $0.value.reduce(0.0) { $0 + $1.amount } > $1.value.reduce(0.0) { $0 + $1.amount } }

        for (relation, records) in sortedRelations {
            let total = records.reduce(0.0) { $0 + $1.amount }
            csv += "\(escapeCSV(relation)),\(total),\(records.count)\n"
        }

        // Part 4: 往来排行 Top 联系人
        csv += "\n=== 往来排行（Top 20）===\n"
        csv += "排名,姓名,收到金额,送出金额,总金额,差额\n"

        let contactGrouped = Dictionary(grouping: allRecords.filter { $0.contact != nil }) { record -> String in
            record.contact?.name ?? "未知"
        }
        let topContacts = contactGrouped
            .map { (name: $0.key, records: $0.value) }
            .sorted { $0.records.reduce(0.0) { $0 + $1.amount } > $1.records.reduce(0.0) { $0 + $1.amount } }
            .prefix(20)

        for (index, item) in topContacts.enumerated() {
            let received = item.records.filter { $0.direction == receivedValue }.reduce(0.0) { $0 + $1.amount }
            let sent = item.records.filter { $0.direction == sentValue }.reduce(0.0) { $0 + $1.amount }
            csv += "\(index + 1),\(escapeCSV(item.name)),\(received),\(sent),\(received + sent),\(received - sent)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("礼尚记统计数据_\(dateString()).csv")
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - 数据计数（用于导出预览）

    /// 获取符合条件的记录数
    func countFilteredRecords(context: ModelContext, bookIDs: Set<UUID>?, startDate: Date?, endDate: Date?) -> Int {
        do {
            let descriptor = FetchDescriptor<GiftRecord>()
            var records = try context.fetch(descriptor)

            if let bookIDs, !bookIDs.isEmpty {
                records = records.filter { record in
                    guard let bookID = record.book?.id else { return false }
                    return bookIDs.contains(bookID)
                }
            }
            if let startDate {
                records = records.filter { $0.eventDate >= startDate }
            }
            if let endDate {
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
                records = records.filter { $0.eventDate < endOfDay }
            }
            return records.count
        } catch {
            return 0
        }
    }

    /// 获取符合条件的提醒事件数
    func countFilteredEventReminders(context: ModelContext, startDate: Date?, endDate: Date?) -> Int {
        do {
            let descriptor = FetchDescriptor<EventReminder>()
            var events = try context.fetch(descriptor)

            if let startDate {
                events = events.filter { $0.eventDate >= startDate }
            }
            if let endDate {
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
                events = events.filter { $0.eventDate < endOfDay }
            }
            return events.count
        } catch {
            return 0
        }
    }

    /// 获取联系人总数
    func countContacts(context: ModelContext) -> Int {
        do {
            let descriptor = FetchDescriptor<Contact>()
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    // MARK: - 辅助方法

    /// CSV 转义
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    /// 日期字符串
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}
