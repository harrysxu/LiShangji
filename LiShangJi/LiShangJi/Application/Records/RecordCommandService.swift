import Foundation
import SwiftData

struct RecordDraft {
    var amount: Double
    var direction: GiftDirection
    var contactName: String
    var eventName: String
    var eventCategory: String
    var eventDate: Date
    var note: String = ""
    var sourceCode: String = "manual"
    var recordType: RecordType = .gift
    var familySideCode: String = "unspecified"
    var contact: Contact?
    var book: GiftBook?
    var categoryID: UUID?
    var linkedRecordID: UUID?
    var ocrImageData: Data?
    var reciprocitySource: GiftRecord?
}

struct RecordReceipt {
    let recordID: UUID
    let createdContactID: UUID?
}

enum RecordCommandError: LocalizedError {
    case invalidAmount(index: Int?)
    case missingContact(index: Int?)
    case premiumRequired

    var errorDescription: String? {
        switch self {
        case .invalidAmount(let index): return index.map { "第\($0 + 1)条记录金额无效" } ?? "请输入有效金额"
        case .missingContact(let index): return index.map { "第\($0 + 1)条记录缺少联系人" } ?? "请输入联系人"
        case .premiumRequired: return "此批量录入方式需要高级版"
        }
    }
}

@MainActor
struct RecordCommandService {
    @discardableResult
    func create(_ draft: RecordDraft, context: ModelContext) throws -> RecordReceipt {
        try createBatch([draft], context: context).first!
    }

    @discardableResult
    func createBatch(_ drafts: [RecordDraft], context: ModelContext) throws -> [RecordReceipt] {
        try validate(drafts)
        if let source = drafts.first?.sourceCode,
           (source == "ocr" || source == "voice"),
           !EntitlementPolicy(isPremium: PremiumManager.shared.isPremium).allows(source == "ocr" ? .ocrBatch : .voiceBatch) {
            throw RecordCommandError.premiumRequired
        }

        do {
            var receipts: [RecordReceipt] = []
            var affectedContacts: [UUID: Contact] = [:]
            var affectedBooks: [UUID: GiftBook] = [:]

            for draft in drafts {
                let name = draft.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
                let contact: Contact
                let createdContactID: UUID?
                if let existing = draft.contact {
                    contact = existing
                    createdContactID = nil
                } else {
                    contact = Contact(name: name)
                    context.insert(contact)
                    createdContactID = contact.id
                }

                let record = GiftRecord(amount: draft.amount, direction: draft.direction.rawValue, eventName: draft.eventName)
                record.eventCategory = draft.eventCategory
                record.eventDate = draft.eventDate
                record.note = draft.note
                record.contactName = name
                record.contactNameSnapshot = name
                record.categoryNameSnapshot = draft.eventCategory
                record.categoryID = draft.categoryID
                record.source = draft.sourceCode
                record.recordType = draft.recordType.rawValue
                record.familySideCode = draft.familySideCode
                record.linkedRecordID = draft.linkedRecordID
                if let imageData = draft.ocrImageData { record.ocrImageData = imageData }
                record.contact = contact
                record.book = draft.book
                record.refreshCompatibilityFields()
                context.insert(record)
                if let source = draft.reciprocitySource {
                    source.reciprocityStatusCode = "returned"
                    source.linkedRecordID = record.id
                    record.linkedRecordID = source.id
                }

                affectedContacts[contact.id] = contact
                if let book = draft.book { affectedBooks[book.id] = book }
                receipts.append(RecordReceipt(recordID: record.id, createdContactID: createdContactID))
            }

            for contact in affectedContacts.values {
                contact.recalculateCachedAggregates()
                contact.refreshCompatibilityFields()
            }
            for book in affectedBooks.values { book.recalculateCachedAggregates() }
            try context.save()
            return receipts
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(_ record: GiftRecord, context: ModelContext) throws {
        try deleteBatch([record], context: context)
    }

    func deleteBatch(_ records: [GiftRecord], context: ModelContext) throws {
        var contacts: [UUID: Contact] = [:]
        var books: [UUID: GiftBook] = [:]
        do {
            for record in records {
                if let contact = record.contact { contacts[contact.id] = contact }
                if let book = record.book { books[book.id] = book }
                context.delete(record)
            }
            for contact in contacts.values { contact.recalculateCachedAggregates(); contact.refreshCompatibilityFields() }
            for book in books.values { book.recalculateCachedAggregates() }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func commitChanges(to record: GiftRecord, previousBook: GiftBook?, context: ModelContext) throws {
        do {
            record.updatedAt = Date()
            record.refreshCompatibilityFields()
            record.contact?.recalculateCachedAggregates()
            record.contact?.refreshCompatibilityFields()
            previousBook?.recalculateCachedAggregates()
            record.book?.recalculateCachedAggregates()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func setReciprocityStatus(_ status: String, for record: GiftRecord, context: ModelContext) throws {
        do {
            record.reciprocityStatusCode = status
            record.updatedAt = Date()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func validate(_ drafts: [RecordDraft]) throws {
        for (index, draft) in drafts.enumerated() {
            guard draft.amount.isFinite, draft.amount > 0 else { throw RecordCommandError.invalidAmount(index: drafts.count > 1 ? index : nil) }
            guard !draft.contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RecordCommandError.missingContact(index: drafts.count > 1 ? index : nil)
            }
        }
    }
}
