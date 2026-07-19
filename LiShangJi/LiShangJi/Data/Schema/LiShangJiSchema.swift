import Foundation
import SwiftData

// The V1 types mirror main@f582257. Do not edit them when the current models evolve.
enum LiShangJiSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [GiftBook.self, GiftRecord.self, Contact.self, GiftEvent.self, EventReminder.self, CategoryItem.self]
    }

    @Model final class GiftBook {
        var id: UUID = UUID(); var name = ""; var icon = "book.closed.fill"; var colorHex = "#C04851"; var note = ""
        var createdAt = Date(); var updatedAt = Date(); var isArchived = false; var sortOrder = 0
        var cachedTotalReceived = 0.0; var cachedTotalSent = 0.0; var cachedRecordCount = 0
        @Relationship(deleteRule: .cascade, inverse: \GiftRecord.book) var records: [GiftRecord]? = []
        init(name: String) { self.name = name }
    }

    @Model final class GiftRecord {
        var id: UUID = UUID(); var amount = 0.0; var direction = "sent"; var recordType = "gift"
        var eventName = ""; var eventCategory = "婚礼"; var eventDate = Date(); var note = ""; var contactName = ""
        var createdAt = Date(); var updatedAt = Date(); var source = "manual"
        @Attribute(.externalStorage) var ocrImageData = Data()
        var isLoanSettled = false; var loanDueDate = Date()
        var book: GiftBook?; var contact: Contact?
        init(amount: Double, direction: String, eventName: String) {
            self.amount = amount; self.direction = direction; self.eventName = eventName
        }
    }

    @Model final class Contact {
        var id: UUID = UUID(); var name = ""; var phone = ""; var relation = "other"; var group = ""; var note = ""
        var avatarSystemName = "person.circle.fill"; var createdAt = Date(); var updatedAt = Date()
        var lunarBirthday = ""; var solarBirthday = Date(); var hasBirthday = false; var systemContactID = ""
        var cachedTotalReceived = 0.0; var cachedTotalSent = 0.0; var cachedRecordCount = 0
        @Relationship(deleteRule: .nullify, inverse: \GiftRecord.contact) var records: [GiftRecord]? = []
        @Relationship(deleteRule: .nullify) var eventReminders: [EventReminder]? = []
        init(name: String) { self.name = name }
    }

    @Model final class GiftEvent {
        var id: UUID = UUID(); var name = ""; var category = "婚礼"; var icon = "heart.fill"
        var isBuiltIn = false; var sortOrder = 0; var createdAt = Date()
        init(name: String) { self.name = name }
    }

    @Model final class EventReminder {
        var id: UUID = UUID(); var title = ""; var note = ""; var eventCategory = "其他"; var eventDate = Date()
        var reminderOption = "none"; var reminderDate: Date?; var isCompleted = false; var isAllDay = true
        var createdAt = Date(); var updatedAt = Date()
        @Relationship(deleteRule: .nullify, inverse: \Contact.eventReminders) var contacts: [Contact]? = []
        init(title: String) { self.title = title }
    }

    @Model final class CategoryItem {
        var id: UUID = UUID(); var name = ""; var icon = "tag.fill"; var isBuiltIn = false; var isVisible = true
        var sortOrder = 0; var createdAt = Date(); var updatedAt = Date()
        init(name: String) { self.name = name }
    }
}

enum LiShangJiSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [GiftBook.self, GiftRecord.self, Contact.self, ContactAlias.self, GiftEvent.self, EventReminder.self, CategoryItem.self]
    }
}

enum LiShangJiMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [LiShangJiSchemaV1.self, LiShangJiSchemaV2.self] }
    static var stages: [MigrationStage] { [v1toV2] }
    static let v1toV2 = MigrationStage.lightweight(fromVersion: LiShangJiSchemaV1.self, toVersion: LiShangJiSchemaV2.self)
}
