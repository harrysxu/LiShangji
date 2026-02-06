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
