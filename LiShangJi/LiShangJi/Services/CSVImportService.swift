//
//  CSVImportService.swift
//  LiShangJi
//
//  CSV 导入解析、预览和执行服务
//

import Foundation
import SwiftData

struct CSVImportPreview {
    var rows: [CSVImportRow]
    var importableCount: Int { rows.filter(\.canImport).count }
    var duplicateCount: Int { rows.filter(\.isDuplicate).count }
    var invalidCount: Int { rows.filter { !$0.errors.isEmpty }.count }
}

struct CSVImportRow: Identifiable {
    let id = UUID()
    let lineNumber: Int
    var recordID: UUID?
    var contactName: String
    var relation: String
    var amount: Double
    var direction: String
    var recordType: String
    var eventCategory: String
    var eventName: String
    var eventDate: Date
    var note: String
    var bookName: String
    var source: String
    var itemName: String
    var estimatedAmount: Double
    var includeInGiftStats: Bool
    var isDuplicate: Bool
    var errors: [String]

    var canImport: Bool {
        errors.isEmpty && !isDuplicate
    }
}

enum CSVImportError: LocalizedError {
    case emptyFile
    case invalidEncoding

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "CSV 文件为空"
        case .invalidEncoding:
            return "无法读取 CSV 文件编码"
        }
    }
}

final class CSVImportService {
    static let shared = CSVImportService()
    private init() {}

    func previewImport(from url: URL, context: ModelContext) throws -> CSVImportPreview {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16) else {
            throw CSVImportError.invalidEncoding
        }
        return try previewImport(csvText: text, context: context)
    }

    func previewImport(csvText: String, context: ModelContext) throws -> CSVImportPreview {
        let table = parseCSV(csvText)
        guard table.count > 1 else { throw CSVImportError.emptyFile }

        let headers = table[0].map(normalizeHeader)
        let existingRecords = try context.fetch(FetchDescriptor<GiftRecord>())
        var rows: [CSVImportRow] = []

        for (offset, values) in table.dropFirst().enumerated() where !values.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            let lineNumber = offset + 2
            let dictionary = Dictionary(uniqueKeysWithValues: headers.enumerated().map { index, key in
                (key, index < values.count ? values[index].trimmingCharacters(in: .whitespacesAndNewlines) : "")
            })
            rows.append(makeRow(lineNumber: lineNumber, fields: dictionary, existingRecords: existingRecords))
        }

        return CSVImportPreview(rows: rows)
    }

    @discardableResult
    func performImport(preview: CSVImportPreview, context: ModelContext, defaultBook: GiftBook? = nil) throws -> Int {
        _ = try BackupService.shared.createSnapshot(context: context, reason: "CSV 导入前自动备份")

        let contactRepository = ContactRepository()
        let recordRepository = GiftRecordRepository()
        let existingBooks = try context.fetch(FetchDescriptor<GiftBook>())
        var importedCount = 0

        for row in preview.rows where row.canImport {
            var contact = try findContact(named: row.contactName, context: context)
            if contact == nil {
                contact = try contactRepository.create(
                    name: row.contactName,
                    relation: relationRawValue(from: row.relation),
                    phone: "",
                    context: context
                )
            }

            let book = existingBooks.first { $0.name == row.bookName } ?? defaultBook

            let record = try recordRepository.create(
                amount: row.amount,
                direction: row.direction,
                recordType: row.recordType,
                eventName: row.eventName,
                eventCategory: row.eventCategory,
                eventDate: row.eventDate,
                note: row.note,
                contactName: row.contactName,
                source: row.source.isEmpty ? "import" : row.source,
                itemName: row.itemName,
                estimatedAmount: row.estimatedAmount,
                includeInGiftStats: row.recordType == RecordType.loan.rawValue ? false : row.includeInGiftStats,
                isLoanSettled: false,
                loanDueDate: row.eventDate,
                book: book,
                contact: contact,
                context: context
            )
            if let recordID = row.recordID {
                record.id = recordID
            }
            importedCount += 1
        }

        try context.save()
        return importedCount
    }

    private func makeRow(lineNumber: Int, fields: [String: String], existingRecords: [GiftRecord]) -> CSVImportRow {
        var errors: [String] = []
        let recordID = UUID(uuidString: firstValue(fields, keys: ["记录id", "id", "recordid"]))
        let contactName = firstValue(fields, keys: ["姓名", "联系人", "contactname", "name"])
        if contactName.isEmpty { errors.append("缺少姓名") }

        let amountText = firstValue(fields, keys: ["金额", "amount"])
        let amount = parseAmount(amountText)
        if amount <= 0 { errors.append("金额无效") }

        let direction = parseDirection(firstValue(fields, keys: ["收/送", "方向", "direction"]))
        let recordType = parseRecordType(firstValue(fields, keys: ["记录类型", "类型", "recordtype"]))
        let eventCategory = firstValue(fields, keys: ["事件类型", "分类", "eventcategory"])
        let eventName = firstValue(fields, keys: ["事件名称", "事件", "eventname"])
        let dateText = firstValue(fields, keys: ["日期", "事件日期", "date", "eventdate"])
        let parsedDate = parseDate(dateText)
        if parsedDate == nil { errors.append("日期无效") }

        let row = CSVImportRow(
            lineNumber: lineNumber,
            recordID: recordID,
            contactName: contactName,
            relation: firstValue(fields, keys: ["关系", "relation"]),
            amount: amount,
            direction: direction,
            recordType: recordType,
            eventCategory: eventCategory.isEmpty ? "其他" : eventCategory,
            eventName: eventName.isEmpty ? "\(contactName)\(eventCategory.isEmpty ? "人情" : eventCategory)" : eventName,
            eventDate: parsedDate ?? Date(),
            note: firstValue(fields, keys: ["备注", "note"]),
            bookName: firstValue(fields, keys: ["账本", "book"]),
            source: "import",
            itemName: firstValue(fields, keys: ["礼品/人情名称", "礼品名称", "事项", "itemname"]),
            estimatedAmount: parseAmount(firstValue(fields, keys: ["估算金额", "estimatedamount"])),
            includeInGiftStats: parseBool(firstValue(fields, keys: ["计入统计", "includeingiftstats"]), defaultValue: recordType != RecordType.loan.rawValue),
            isDuplicate: false,
            errors: errors
        )

        var mutableRow = row
        mutableRow.isDuplicate = isDuplicate(row: row, existingRecords: existingRecords)
        return mutableRow
    }

    private func isDuplicate(row: CSVImportRow, existingRecords: [GiftRecord]) -> Bool {
        if let recordID = row.recordID, existingRecords.contains(where: { $0.id == recordID }) {
            return true
        }
        return existingRecords.contains { record in
            record.displayName == row.contactName
                && abs(record.amount - row.amount) < 0.01
                && record.direction == row.direction
                && Calendar.current.isDate(record.eventDate, inSameDayAs: row.eventDate)
                && record.eventName == row.eventName
                && (record.book?.name ?? "") == row.bookName
        }
    }

    private func firstValue(_ fields: [String: String], keys: [String]) -> String {
        for key in keys {
            if let value = fields[normalizeHeader(key)], !value.isEmpty {
                return value
            }
        }
        return ""
    }

    private func normalizeHeader(_ value: String) -> String {
        value.replacingOccurrences(of: "\u{FEFF}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
    }

    private func parseAmount(_ value: String) -> Double {
        let cleaned = value
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "圆", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? ChineseNumberParser.parse(cleaned) ?? 0
    }

    private func parseDirection(_ value: String) -> String {
        let normalized = value.lowercased()
        if normalized.contains("收") || normalized.contains("received") {
            return GiftDirection.received.rawValue
        }
        return GiftDirection.sent.rawValue
    }

    private func parseRecordType(_ value: String) -> String {
        if value.contains("礼品") { return RecordType.item.rawValue }
        if value.contains("人情") { return RecordType.favor.rawValue }
        if value.contains("借") { return RecordType.loan.rawValue }
        return RecordType(rawValue: value)?.rawValue ?? RecordType.gift.rawValue
    }

    private func parseDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        let formats = ["yyyy-MM-dd", "yyyy/M/d", "yyyy年M月d日", "yyyy.MM.dd"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private func parseBool(_ value: String, defaultValue: Bool) -> Bool {
        guard !value.isEmpty else { return defaultValue }
        return ["是", "true", "1", "yes"].contains(value.lowercased())
    }

    private func relationRawValue(from displayName: String) -> String {
        RelationType.allCases.first { $0.displayName == displayName || $0.rawValue == displayName }?.rawValue ?? RelationType.other.rawValue
    }

    private func findContact(named name: String, context: ModelContext) throws -> Contact? {
        let allContacts = try context.fetch(FetchDescriptor<Contact>())
        return allContacts.first { $0.name == name }
    }

    private func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var iterator = text.makeIterator()

        while let char = iterator.next() {
            if char == "\"" {
                if isQuoted, let next = iterator.next() {
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        isQuoted = false
                        if next == "," {
                            row.append(field)
                            field = ""
                        } else if next == "\n" {
                            row.append(field)
                            rows.append(row)
                            row = []
                            field = ""
                        } else if next != "\r" {
                            field.append(next)
                        }
                    }
                } else {
                    isQuoted.toggle()
                }
            } else if char == "," && !isQuoted {
                row.append(field)
                field = ""
            } else if char == "\n" && !isQuoted {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else if char != "\r" {
                field.append(char)
            }
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}
