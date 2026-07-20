//
//  BackupService.swift
//  LiShangJi
//
//  本地 JSON 快照备份与恢复服务
//

import Foundation
import SwiftData

struct BackupSnapshot: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let reason: String
    var books: [BookBackup]
    var contacts: [ContactBackup]
    var records: [RecordBackup]
    var events: [EventBackup]
    var categories: [CategoryBackup]
}

struct BookBackup: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let note: String
    let isArchived: Bool
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
}

struct ContactBackup: Codable {
    let id: UUID
    let name: String
    let phone: String
    let relation: String
    let group: String
    let note: String
    let avatarSystemName: String
    let lunarBirthday: String
    let solarBirthday: Date
    let hasBirthday: Bool
    let systemContactID: String
    let createdAt: Date
    let updatedAt: Date
}

struct RecordBackup: Codable {
    let id: UUID
    let amount: Double
    let direction: String
    let recordType: String
    let eventName: String
    let eventCategory: String
    let eventDate: Date
    let note: String
    let contactName: String
    let source: String
    let isLoanSettled: Bool
    let loanDueDate: Date
    let itemName: String
    let estimatedAmount: Double
    let includeInGiftStats: Bool
    let settledAt: Date?
    let bookID: UUID?
    let contactID: UUID?
    let createdAt: Date
    let updatedAt: Date
}

struct EventBackup: Codable {
    let id: UUID
    let title: String
    let note: String
    let eventCategory: String
    let eventDate: Date
    let reminderOption: String
    let reminderDate: Date?
    let isCompleted: Bool
    let isAllDay: Bool
    let contactIDs: [UUID]
    let createdAt: Date
    let updatedAt: Date
}

struct CategoryBackup: Codable {
    let id: UUID
    let name: String
    let icon: String
    let isBuiltIn: Bool
    let isVisible: Bool
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
}

enum BackupRestoreMode {
    case replace
    case merge
}

final class BackupService {
    static let shared = BackupService()
    private init() {}

    private let maxAutomaticSnapshots = 10

    private var backupDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Backups", isDirectory: true)
    }

    func createSnapshot(context: ModelContext, reason: String) throws -> URL {
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let snapshot = try buildSnapshot(context: context, reason: reason)
        let url = backupDirectory.appendingPathComponent("auto_\(snapshot.createdAt.backupFileStamp)_\(snapshot.id.uuidString).json")
        let data = try JSONEncoder.lsjBackupEncoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
        pruneAutomaticSnapshots()
        return url
    }

    func createManualSnapshot(context: ModelContext, name: String) throws -> URL {
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let snapshot = try buildSnapshot(context: context, reason: name.isEmpty ? "手动备份" : name)
        let safeName = sanitizeFileName(name.isEmpty ? "手动备份" : name)
        let url = backupDirectory.appendingPathComponent("manual_\(snapshot.createdAt.backupFileStamp)_\(safeName)_\(snapshot.id.uuidString).json")
        let data = try JSONEncoder.lsjBackupEncoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
        return url
    }

    func listSnapshots() -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return urls
            .filter { $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                ((try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) >
                ((try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast)
            }
    }

    func loadSnapshot(from url: URL) throws -> BackupSnapshot {
        let data = try Data(contentsOf: url)
        return try JSONDecoder.lsjBackupDecoder.decode(BackupSnapshot.self, from: data)
    }

    func restoreSnapshot(from url: URL, mode: BackupRestoreMode, context: ModelContext) throws {
        let snapshot = try loadSnapshot(from: url)
        _ = try createSnapshot(context: context, reason: "恢复前自动备份")
        switch mode {
        case .replace:
            try clearAllData(context: context)
            try insertSnapshot(snapshot, context: context)
        case .merge:
            try mergeSnapshot(snapshot, context: context)
        }
    }

    private func buildSnapshot(context: ModelContext, reason: String) throws -> BackupSnapshot {
        let books = try context.fetch(FetchDescriptor<GiftBook>())
        let contacts = try context.fetch(FetchDescriptor<Contact>())
        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        let events = try context.fetch(FetchDescriptor<EventReminder>())
        let categories = try context.fetch(FetchDescriptor<CategoryItem>())

        return BackupSnapshot(
            id: UUID(),
            createdAt: Date(),
            reason: reason,
            books: books.map {
                BookBackup(id: $0.id, name: $0.name, icon: $0.icon, colorHex: $0.colorHex, note: $0.note, isArchived: $0.isArchived, sortOrder: $0.sortOrder, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            contacts: contacts.map {
                ContactBackup(id: $0.id, name: $0.name, phone: $0.phone, relation: $0.relation, group: $0.group, note: $0.note, avatarSystemName: $0.avatarSystemName, lunarBirthday: $0.lunarBirthday, solarBirthday: $0.solarBirthday, hasBirthday: $0.hasBirthday, systemContactID: $0.systemContactID, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            records: records.map {
                RecordBackup(id: $0.id, amount: $0.amount, direction: $0.direction, recordType: $0.recordType, eventName: $0.eventName, eventCategory: $0.eventCategory, eventDate: $0.eventDate, note: $0.note, contactName: $0.contactName, source: $0.source, isLoanSettled: $0.isLoanSettled, loanDueDate: $0.loanDueDate, itemName: $0.itemName, estimatedAmount: $0.estimatedAmount, includeInGiftStats: $0.includeInGiftStats, settledAt: $0.settledAt, bookID: $0.book?.id, contactID: $0.contact?.id, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            events: events.map {
                EventBackup(id: $0.id, title: $0.title, note: $0.note, eventCategory: $0.eventCategory, eventDate: $0.eventDate, reminderOption: $0.reminderOption, reminderDate: $0.reminderDate, isCompleted: $0.isCompleted, isAllDay: $0.isAllDay, contactIDs: ($0.contacts ?? []).map(\.id), createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            categories: categories.map {
                CategoryBackup(id: $0.id, name: $0.name, icon: $0.icon, isBuiltIn: $0.isBuiltIn, isVisible: $0.isVisible, sortOrder: $0.sortOrder, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            }
        )
    }

    private func clearAllData(context: ModelContext) throws {
        for record in try context.fetch(FetchDescriptor<GiftRecord>()) { context.delete(record) }
        for event in try context.fetch(FetchDescriptor<EventReminder>()) { context.delete(event) }
        for contact in try context.fetch(FetchDescriptor<Contact>()) { context.delete(contact) }
        for book in try context.fetch(FetchDescriptor<GiftBook>()) { context.delete(book) }
        for category in try context.fetch(FetchDescriptor<CategoryItem>()) { context.delete(category) }
        try context.save()
    }

    private func insertSnapshot(_ snapshot: BackupSnapshot, context: ModelContext) throws {
        var bookMap: [UUID: GiftBook] = [:]
        var contactMap: [UUID: Contact] = [:]

        for backup in snapshot.books {
            let book = GiftBook(name: backup.name, icon: backup.icon, colorHex: backup.colorHex)
            book.id = backup.id
            book.note = backup.note
            book.isArchived = backup.isArchived
            book.sortOrder = backup.sortOrder
            book.createdAt = backup.createdAt
            book.updatedAt = backup.updatedAt
            context.insert(book)
            bookMap[backup.id] = book
        }

        for backup in snapshot.contacts {
            let contact = Contact(name: backup.name, relation: backup.relation)
            contact.id = backup.id
            contact.phone = backup.phone
            contact.group = backup.group
            contact.note = backup.note
            contact.avatarSystemName = backup.avatarSystemName
            contact.lunarBirthday = backup.lunarBirthday
            contact.solarBirthday = backup.solarBirthday
            contact.hasBirthday = backup.hasBirthday
            contact.systemContactID = backup.systemContactID
            contact.createdAt = backup.createdAt
            contact.updatedAt = backup.updatedAt
            context.insert(contact)
            contactMap[backup.id] = contact
        }

        for backup in snapshot.categories {
            let category = CategoryItem(name: backup.name, icon: backup.icon, isBuiltIn: backup.isBuiltIn, sortOrder: backup.sortOrder)
            category.id = backup.id
            category.isVisible = backup.isVisible
            category.createdAt = backup.createdAt
            category.updatedAt = backup.updatedAt
            context.insert(category)
        }

        for backup in snapshot.records {
            let record = GiftRecord(amount: backup.amount, direction: backup.direction, eventName: backup.eventName)
            apply(backup, to: record, bookMap: bookMap, contactMap: contactMap)
            context.insert(record)
        }

        for backup in snapshot.events {
            let event = EventReminder(title: backup.title, eventCategory: backup.eventCategory, eventDate: backup.eventDate)
            event.id = backup.id
            event.note = backup.note
            event.reminderOption = backup.reminderOption
            event.reminderDate = backup.reminderDate
            event.isCompleted = backup.isCompleted
            event.isAllDay = backup.isAllDay
            event.createdAt = backup.createdAt
            event.updatedAt = backup.updatedAt
            event.contacts = backup.contactIDs.compactMap { contactMap[$0] }
            context.insert(event)
        }

        try context.save()
        try recalculateAggregates(context: context)
    }

    private func mergeSnapshot(_ snapshot: BackupSnapshot, context: ModelContext) throws {
        let existingBookIDs = Set(try context.fetch(FetchDescriptor<GiftBook>()).map(\.id))
        let existingContactIDs = Set(try context.fetch(FetchDescriptor<Contact>()).map(\.id))
        let existingRecordIDs = Set(try context.fetch(FetchDescriptor<GiftRecord>()).map(\.id))
        let existingEventIDs = Set(try context.fetch(FetchDescriptor<EventReminder>()).map(\.id))
        let existingCategoryNames = Set(try context.fetch(FetchDescriptor<CategoryItem>()).map(\.name))

        var bookMap = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<GiftBook>()).map { ($0.id, $0) })
        var contactMap = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<Contact>()).map { ($0.id, $0) })

        for backup in snapshot.books where !existingBookIDs.contains(backup.id) {
            let book = GiftBook(name: backup.name, icon: backup.icon, colorHex: backup.colorHex)
            book.id = backup.id
            book.note = backup.note
            book.isArchived = backup.isArchived
            book.sortOrder = backup.sortOrder
            context.insert(book)
            bookMap[backup.id] = book
        }

        for backup in snapshot.contacts where !existingContactIDs.contains(backup.id) {
            let contact = Contact(name: backup.name, relation: backup.relation)
            contact.id = backup.id
            contact.phone = backup.phone
            contact.note = backup.note
            context.insert(contact)
            contactMap[backup.id] = contact
        }

        for backup in snapshot.categories where !existingCategoryNames.contains(backup.name) {
            context.insert(CategoryItem(name: backup.name, icon: backup.icon, isBuiltIn: backup.isBuiltIn, sortOrder: backup.sortOrder))
        }

        for backup in snapshot.records where !existingRecordIDs.contains(backup.id) {
            let record = GiftRecord(amount: backup.amount, direction: backup.direction, eventName: backup.eventName)
            apply(backup, to: record, bookMap: bookMap, contactMap: contactMap)
            context.insert(record)
        }

        for backup in snapshot.events where !existingEventIDs.contains(backup.id) {
            let event = EventReminder(title: backup.title, eventCategory: backup.eventCategory, eventDate: backup.eventDate)
            event.id = backup.id
            event.note = backup.note
            event.reminderOption = backup.reminderOption
            event.reminderDate = backup.reminderDate
            event.contacts = backup.contactIDs.compactMap { contactMap[$0] }
            context.insert(event)
        }

        try context.save()
        try recalculateAggregates(context: context)
    }

    private func apply(_ backup: RecordBackup, to record: GiftRecord, bookMap: [UUID: GiftBook], contactMap: [UUID: Contact]) {
        record.id = backup.id
        record.recordType = backup.recordType
        record.eventCategory = backup.eventCategory
        record.eventDate = backup.eventDate
        record.note = backup.note
        record.contactName = backup.contactName
        record.source = backup.source
        record.isLoanSettled = backup.isLoanSettled
        record.loanDueDate = backup.loanDueDate
        record.itemName = backup.itemName
        record.estimatedAmount = backup.estimatedAmount
        record.includeInGiftStats = backup.includeInGiftStats
        record.settledAt = backup.settledAt
        record.createdAt = backup.createdAt
        record.updatedAt = backup.updatedAt
        if let bookID = backup.bookID { record.book = bookMap[bookID] }
        if let contactID = backup.contactID { record.contact = contactMap[contactID] }
    }

    private func recalculateAggregates(context: ModelContext) throws {
        for contact in try context.fetch(FetchDescriptor<Contact>()) {
            contact.recalculateCachedAggregates()
        }
        for book in try context.fetch(FetchDescriptor<GiftBook>()) {
            book.recalculateCachedAggregates()
        }
        try context.save()
    }

    private func pruneAutomaticSnapshots() {
        let automatic = listSnapshots().filter { $0.lastPathComponent.hasPrefix("auto_") }
        guard automatic.count > maxAutomaticSnapshots else { return }
        for url in automatic.dropFirst(maxAutomaticSnapshots) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func sanitizeFileName(_ value: String) -> String {
        value.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension JSONEncoder {
    static var lsjBackupEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var lsjBackupDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension Date {
    var backupFileStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: self)
    }
}
