import CryptoKit
import Foundation
import SwiftData

struct BackupManifest: Codable {
    let format: String
    let formatVersion: Int
    let schemaVersion: Int
    let appVersion: String
    let createdAt: Date
    let recordCounts: [String: Int]
}

struct BackupPayload: Codable {
    struct Book: Codable { let id: UUID; let name, icon, colorHex, note: String; let createdAt, updatedAt: Date; let isArchived: Bool; let sortOrder: Int }
    struct ContactItem: Codable { let id: UUID; let name, phone, relation, group, note, avatarSystemName: String; let createdAt, updatedAt: Date; let lunarBirthday: String; let solarBirthday: Date; let hasBirthday: Bool; let systemContactID, familySideCode: String }
    struct Alias: Codable { let id, contactID: UUID; let name: String; let createdAt: Date }
    struct Record: Codable {
        let id: UUID; let amount: Double; let direction, recordType, eventName, eventCategory: String
        let eventDate: Date; let note, contactName, source: String; let ocrImageData: Data?
        let isLoanSettled: Bool; let loanDueDate: Date; let createdAt, updatedAt: Date
        let bookID, contactID, categoryID, linkedRecordID: UUID?
        let currencyCode, categoryNameSnapshot, contactNameSnapshot, familySideCode, reciprocityStatusCode: String
    }
    struct Reminder: Codable {
        let id: UUID; let title, note, eventCategory: String; let eventDate: Date; let reminderOption: String
        let reminderDate: Date?; let isCompleted, isAllDay: Bool; let createdAt, updatedAt: Date
        let contactIDs: [UUID]; let linkedRecordID: UUID?; let completionActionCode: String
    }
    struct Event: Codable { let id: UUID; let name, category, icon: String; let isBuiltIn: Bool; let sortOrder: Int; let createdAt: Date }
    struct Category: Codable { let id: UUID; let name, icon: String; let isBuiltIn, isVisible: Bool; let sortOrder: Int; let createdAt, updatedAt: Date; let code: String? }

    let books: [Book]
    let contacts: [ContactItem]
    let aliases: [Alias]
    let records: [Record]
    let reminders: [Reminder]
    let events: [Event]
    let categories: [Category]
    let settings: [String: String]
}

private struct BackupEnvelope: Codable {
    let manifest: BackupManifest
    let payload: BackupPayload
    let payloadSHA256: String
}

struct BackupPreview {
    let manifest: BackupManifest
    let payload: BackupPayload
}

enum RestoreMode { case merge, replace }

enum BackupError: LocalizedError {
    case unsupportedFormat
    case checksumMismatch

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "这不是受支持的礼小记备份文件"
        case .checksumMismatch: return "备份校验失败，文件可能已损坏或被修改"
        }
    }
}

@MainActor
final class BackupService {
    static let shared = BackupService()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func createBackup(context: ModelContext, directory: URL? = nil) throws -> URL {
        let payload = try makePayload(context: context)
        let payloadData = try encoder.encode(payload)
        let manifest = BackupManifest(
            format: "com.lixiaoji.backup", formatVersion: 1, schemaVersion: 2,
            appVersion: AppConstants.Brand.version, createdAt: Date(),
            recordCounts: ["books": payload.books.count, "contacts": payload.contacts.count, "records": payload.records.count, "reminders": payload.reminders.count]
        )
        let envelope = BackupEnvelope(manifest: manifest, payload: payload, payloadSHA256: SHA256.hash(data: payloadData).hexString)
        let destination = directory ?? FileManager.default.temporaryDirectory
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let formatter = DateFormatter(); formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = destination.appendingPathComponent("礼小记备份-\(formatter.string(from: Date())).lsxbackup")
        try encoder.encode(envelope).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    func preview(url: URL) throws -> BackupPreview {
        let data = try Data(contentsOf: url)
        let envelope = try decoder.decode(BackupEnvelope.self, from: data)
        guard envelope.manifest.format == "com.lixiaoji.backup", envelope.manifest.formatVersion == 1 else { throw BackupError.unsupportedFormat }
        let checksum = SHA256.hash(data: try encoder.encode(envelope.payload)).hexString
        guard checksum == envelope.payloadSHA256 else { throw BackupError.checksumMismatch }
        return BackupPreview(manifest: envelope.manifest, payload: envelope.payload)
    }

    func restore(_ preview: BackupPreview, mode: RestoreMode, context: ModelContext) throws {
        _ = try createBackup(context: context, directory: AppModelContainerFactory.recoveryDirectory())
        do {
            if mode == .replace { try deleteAll(context: context) }
            try insert(preview.payload, mode: mode, context: context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func makePayload(context: ModelContext) throws -> BackupPayload {
        let books: [BackupPayload.Book] = try context.fetch(FetchDescriptor<GiftBook>()).map { .init(id: $0.id, name: $0.name, icon: $0.icon, colorHex: $0.colorHex, note: $0.note, createdAt: $0.createdAt, updatedAt: $0.updatedAt, isArchived: $0.isArchived, sortOrder: $0.sortOrder) }
        let contacts: [BackupPayload.ContactItem] = try context.fetch(FetchDescriptor<Contact>()).map { .init(id: $0.id, name: $0.name, phone: $0.phone, relation: $0.relation, group: $0.group, note: $0.note, avatarSystemName: $0.avatarSystemName, createdAt: $0.createdAt, updatedAt: $0.updatedAt, lunarBirthday: $0.lunarBirthday, solarBirthday: $0.solarBirthday, hasBirthday: $0.hasBirthday, systemContactID: $0.systemContactID, familySideCode: $0.familySideCode) }
        let aliases: [BackupPayload.Alias] = try context.fetch(FetchDescriptor<ContactAlias>()).compactMap { alias in alias.contact.map { .init(id: alias.id, contactID: $0.id, name: alias.name, createdAt: alias.createdAt) } }
        let records = try context.fetch(FetchDescriptor<GiftRecord>()).map { record in
            BackupPayload.Record(id: record.id, amount: record.amount, direction: record.direction, recordType: record.recordType, eventName: record.eventName, eventCategory: record.eventCategory, eventDate: record.eventDate, note: record.note, contactName: record.contactName, source: record.source, ocrImageData: record.ocrImageData.isEmpty ? nil : record.ocrImageData, isLoanSettled: record.isLoanSettled, loanDueDate: record.loanDueDate, createdAt: record.createdAt, updatedAt: record.updatedAt, bookID: record.book?.id, contactID: record.contact?.id, categoryID: record.categoryID, linkedRecordID: record.linkedRecordID, currencyCode: record.currencyCode, categoryNameSnapshot: record.categoryNameSnapshot, contactNameSnapshot: record.contactNameSnapshot, familySideCode: record.familySideCode, reciprocityStatusCode: record.reciprocityStatusCode)
        }
        let reminders: [BackupPayload.Reminder] = try context.fetch(FetchDescriptor<EventReminder>()).map { .init(id: $0.id, title: $0.title, note: $0.note, eventCategory: $0.eventCategory, eventDate: $0.eventDate, reminderOption: $0.reminderOption, reminderDate: $0.reminderDate, isCompleted: $0.isCompleted, isAllDay: $0.isAllDay, createdAt: $0.createdAt, updatedAt: $0.updatedAt, contactIDs: ($0.contacts ?? []).map(\.id), linkedRecordID: $0.linkedRecordID, completionActionCode: $0.completionActionCode) }
        let events: [BackupPayload.Event] = try context.fetch(FetchDescriptor<GiftEvent>()).map { .init(id: $0.id, name: $0.name, category: $0.category, icon: $0.icon, isBuiltIn: $0.isBuiltIn, sortOrder: $0.sortOrder, createdAt: $0.createdAt) }
        let categories: [BackupPayload.Category] = try context.fetch(FetchDescriptor<CategoryItem>()).map { .init(id: $0.id, name: $0.name, icon: $0.icon, isBuiltIn: $0.isBuiltIn, isVisible: $0.isVisible, sortOrder: $0.sortOrder, createdAt: $0.createdAt, updatedAt: $0.updatedAt, code: $0.code) }
        let settings = ["colorSchemePreference": UserDefaults.standard.string(forKey: "colorSchemePreference") ?? "system"]
        return BackupPayload(books: books, contacts: contacts, aliases: aliases, records: records, reminders: reminders, events: events, categories: categories, settings: settings)
    }

    private func insert(_ payload: BackupPayload, mode: RestoreMode, context: ModelContext) throws {
        let currentBooks = try context.fetch(FetchDescriptor<GiftBook>()); var books = Dictionary(uniqueKeysWithValues: currentBooks.map { ($0.id, $0) })
        let currentContacts = try context.fetch(FetchDescriptor<Contact>()); var contacts = Dictionary(uniqueKeysWithValues: currentContacts.map { ($0.id, $0) })
        let existingRecordIDs = Set(try context.fetch(FetchDescriptor<GiftRecord>()).map(\.id))
        let existingReminderIDs = Set(try context.fetch(FetchDescriptor<EventReminder>()).map(\.id))
        let existingEventIDs = Set(try context.fetch(FetchDescriptor<GiftEvent>()).map(\.id))
        let existingCategoryIDs = Set(try context.fetch(FetchDescriptor<CategoryItem>()).map(\.id))
        let existingAliasIDs = Set(try context.fetch(FetchDescriptor<ContactAlias>()).map(\.id))

        for item in payload.books where books[item.id] == nil {
            let model = GiftBook(name: item.name, icon: item.icon, colorHex: item.colorHex); model.id = item.id; model.note = item.note; model.createdAt = item.createdAt; model.updatedAt = item.updatedAt; model.isArchived = item.isArchived; model.sortOrder = item.sortOrder; context.insert(model); books[item.id] = model
        }
        for item in payload.contacts where contacts[item.id] == nil {
            let model = Contact(name: item.name, relation: item.relation); model.id = item.id; model.phone = item.phone; model.group = item.group; model.note = item.note; model.avatarSystemName = item.avatarSystemName; model.createdAt = item.createdAt; model.updatedAt = item.updatedAt; model.lunarBirthday = item.lunarBirthday; model.solarBirthday = item.solarBirthday; model.hasBirthday = item.hasBirthday; model.systemContactID = item.systemContactID; model.familySideCode = item.familySideCode; context.insert(model); contacts[item.id] = model
        }
        for item in payload.categories where !existingCategoryIDs.contains(item.id) {
            let model = CategoryItem(name: item.name, icon: item.icon, isBuiltIn: item.isBuiltIn, sortOrder: item.sortOrder); model.id = item.id; model.isVisible = item.isVisible; model.createdAt = item.createdAt; model.updatedAt = item.updatedAt; model.code = item.code; context.insert(model)
        }
        for item in payload.events where !existingEventIDs.contains(item.id) {
            let model = GiftEvent(name: item.name, category: item.category, icon: item.icon, isBuiltIn: item.isBuiltIn, sortOrder: item.sortOrder); model.id = item.id; model.createdAt = item.createdAt; context.insert(model)
        }
        for item in payload.aliases where !existingAliasIDs.contains(item.id) {
            guard let contact = contacts[item.contactID] else { continue }
            let model = ContactAlias(name: item.name, contact: contact); model.id = item.id; model.createdAt = item.createdAt; context.insert(model)
        }
        for item in payload.records where !existingRecordIDs.contains(item.id) {
            let model = GiftRecord(amount: item.amount, direction: item.direction, eventName: item.eventName); model.id = item.id; model.recordType = item.recordType; model.eventCategory = item.eventCategory; model.eventDate = item.eventDate; model.note = item.note; model.contactName = item.contactName; model.source = item.source; model.ocrImageData = item.ocrImageData ?? Data(); model.isLoanSettled = item.isLoanSettled; model.loanDueDate = item.loanDueDate; model.createdAt = item.createdAt; model.updatedAt = item.updatedAt; model.book = item.bookID.flatMap { books[$0] }; model.contact = item.contactID.flatMap { contacts[$0] }; model.categoryID = item.categoryID; model.linkedRecordID = item.linkedRecordID; model.currencyCode = item.currencyCode; model.categoryNameSnapshot = item.categoryNameSnapshot; model.contactNameSnapshot = item.contactNameSnapshot; model.familySideCode = item.familySideCode; model.reciprocityStatusCode = item.reciprocityStatusCode; model.refreshCompatibilityFields(); context.insert(model)
        }
        for item in payload.reminders where !existingReminderIDs.contains(item.id) {
            let model = EventReminder(title: item.title, eventCategory: item.eventCategory, eventDate: item.eventDate); model.id = item.id; model.note = item.note; model.reminderOption = item.reminderOption; model.reminderDate = item.reminderDate; model.isCompleted = item.isCompleted; model.isAllDay = item.isAllDay; model.createdAt = item.createdAt; model.updatedAt = item.updatedAt; model.contacts = item.contactIDs.compactMap { contacts[$0] }; model.linkedRecordID = item.linkedRecordID; model.completionActionCode = item.completionActionCode; context.insert(model)
        }
        for contact in contacts.values { contact.recalculateCachedAggregates(); contact.refreshCompatibilityFields() }
        for book in books.values { book.recalculateCachedAggregates() }
        for (key, value) in payload.settings { UserDefaults.standard.set(value, forKey: key) }
    }

    private func deleteAll(context: ModelContext) throws {
        try context.delete(model: ContactAlias.self); try context.delete(model: GiftRecord.self); try context.delete(model: EventReminder.self)
        try context.delete(model: GiftBook.self); try context.delete(model: Contact.self); try context.delete(model: GiftEvent.self); try context.delete(model: CategoryItem.self)
    }
}

private extension Digest {
    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}
