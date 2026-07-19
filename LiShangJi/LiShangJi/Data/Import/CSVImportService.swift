import Foundation
import SwiftData

struct CSVImportRow: Identifiable {
    let id = UUID()
    let line: Int
    let name: String
    let relation: String
    let amount: Double
    let direction: GiftDirection
    let category: String
    let eventName: String
    let date: Date
    let note: String
    let bookName: String
    var error: String?
    var isDuplicate = false
}

struct CSVImportPreview {
    var rows: [CSVImportRow]
    var validRows: [CSVImportRow] { rows.filter { $0.error == nil } }
    var errorRows: [CSVImportRow] { rows.filter { $0.error != nil } }
    var duplicateRows: [CSVImportRow] { rows.filter(\.isDuplicate) }
}

enum CSVImportError: LocalizedError {
    case unreadable
    case missingHeaders([String])

    var errorDescription: String? {
        switch self {
        case .unreadable: return "无法读取 CSV，请使用 UTF-8 或 UTF-8 BOM 编码"
        case .missingHeaders(let fields): return "缺少必要列：\(fields.joined(separator: "、"))"
        }
    }
}

@MainActor
struct CSVImportService {
    func preview(url: URL, context: ModelContext) throws -> CSVImportPreview {
        let data = try Data(contentsOf: url)
        guard var text = String(data: data, encoding: .utf8) else { throw CSVImportError.unreadable }
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        let table = parse(text)
        guard let rawHeaders = table.first else { throw CSVImportError.unreadable }
        let headers = Dictionary(uniqueKeysWithValues: rawHeaders.enumerated().map { (normalizeHeader($0.element), $0.offset) })

        let nameIndex = index(for: ["姓名", "联系人", "name"], headers: headers)
        let amountIndex = index(for: ["金额", "amount"], headers: headers)
        let directionIndex = index(for: ["收/送", "方向", "direction"], headers: headers)
        var missing: [String] = []
        if nameIndex == nil { missing.append("姓名") }; if amountIndex == nil { missing.append("金额") }; if directionIndex == nil { missing.append("收/送") }
        guard missing.isEmpty else { throw CSVImportError.missingHeaders(missing) }

        let existing = try context.fetch(FetchDescriptor<GiftRecord>())
        let fingerprints = Set(existing.map { fingerprint(name: $0.displayName, amount: $0.amount, direction: $0.giftDirection, date: $0.eventDate, book: $0.book?.name ?? "") })
        var rows: [CSVImportRow] = []
        for (offset, columns) in table.dropFirst().enumerated() where columns.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            let line = offset + 2
            let name = value(columns, nameIndex).trimmingCharacters(in: .whitespacesAndNewlines)
            let amountText = value(columns, amountIndex).replacingOccurrences(of: "¥", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
            let amount = Double(amountText) ?? 0
            let directionText = value(columns, directionIndex).lowercased()
            let direction: GiftDirection = ["收到", "收", "received", "in"].contains(directionText) ? .received : .sent
            let category = value(columns, index(for: ["事件类型", "类别", "category"], headers: headers)).nonEmpty ?? "其他"
            let eventName = value(columns, index(for: ["事件名称", "事件", "event"], headers: headers)).nonEmpty ?? "\(name)\(category)"
            let dateText = value(columns, index(for: ["日期", "date"], headers: headers))
            let date = parseDate(dateText) ?? Date()
            let relation = value(columns, index(for: ["关系", "relation"], headers: headers))
            let note = value(columns, index(for: ["备注", "note"], headers: headers))
            let book = value(columns, index(for: ["账本", "book"], headers: headers))
            var error: String?
            if name.isEmpty { error = "姓名为空" } else if amount <= 0 || !amount.isFinite { error = "金额格式无效" } else if !dateText.isEmpty && parseDate(dateText) == nil { error = "日期格式无法识别" }
            let duplicate = fingerprints.contains(fingerprint(name: name, amount: amount, direction: direction, date: date, book: book))
            rows.append(.init(line: line, name: name, relation: relation, amount: amount, direction: direction, category: category, eventName: eventName, date: date, note: note, bookName: book, error: error, isDuplicate: duplicate))
        }
        return CSVImportPreview(rows: rows)
    }

    func importRows(_ rows: [CSVImportRow], includeDuplicates: Bool, defaultBook: GiftBook?, context: ModelContext) throws -> Int {
        let contacts = try context.fetch(FetchDescriptor<Contact>())
        let books = try context.fetch(FetchDescriptor<GiftBook>())
        let drafts = rows.filter { $0.error == nil && (includeDuplicates || !$0.isDuplicate) }.map { row in
            let contact = contacts.first { Contact.normalize($0.name) == Contact.normalize(row.name) }
            let book = books.first { $0.name == row.bookName } ?? defaultBook
            return RecordDraft(amount: row.amount, direction: row.direction, contactName: row.name, eventName: row.eventName, eventCategory: row.category, eventDate: row.date, note: row.note, sourceCode: "import", contact: contact, book: book)
        }
        try RecordCommandService().createBatch(drafts, context: context)
        return drafts.count
    }

    private func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []; var row: [String] = []; var field = ""; var quoted = false; var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == "\"" {
                let next = text.index(after: index)
                if quoted && next < text.endIndex && text[next] == "\"" { field.append("\""); index = next } else { quoted.toggle() }
            } else if character == "," && !quoted { row.append(field); field = "" }
            else if (character == "\n" || character == "\r") && !quoted {
                if character == "\r" { let next = text.index(after: index); if next < text.endIndex && text[next] == "\n" { index = next } }
                row.append(field); rows.append(row); row = []; field = ""
            } else { field.append(character) }
            index = text.index(after: index)
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }

    private func normalizeHeader(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    private func index(for names: [String], headers: [String: Int]) -> Int? { names.compactMap { headers[normalizeHeader($0)] }.first }
    private func value(_ columns: [String], _ index: Int?) -> String { guard let index, columns.indices.contains(index) else { return "" }; return columns[index] }
    private func parseDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return Date() }
        for format in ["yyyy年M月d日", "yyyy-MM-dd", "yyyy/M/d", "yyyy.MM.dd"] {
            let formatter = DateFormatter(); formatter.locale = Locale(identifier: "zh_CN"); formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
    private func fingerprint(name: String, amount: Double, direction: GiftDirection, date: Date, book: String) -> String {
        "\(Contact.normalize(name))|\(GiftRecord.minorUnits(from: amount))|\(direction.rawValue)|\(Calendar.current.startOfDay(for: date).timeIntervalSince1970)|\(book)"
    }
}

private extension String { var nonEmpty: String? { isEmpty ? nil : self } }
