import Foundation
import SwiftData
import Testing
@testable import LiShangJi

struct UpgradeDomainTests {
    @Test func moneyShadowUsesRoundedMinorUnits() {
        #expect(GiftRecord.minorUnits(from: 88.88) == 8_888)
        #expect(GiftRecord.minorUnits(from: 0.105) == 11)
    }

    @Test func freePolicyKeepsDataCapabilitiesAvailable() {
        let policy = EntitlementPolicy(isPremium: false)
        #expect(policy.canCreateBook(existingActiveBookCount: 0))
        #expect(!policy.canCreateBook(existingActiveBookCount: 1))
        #expect(!policy.allows(.ocrBatch))
    }

    @Test func contactNormalizationHandlesSpacesAndWidth() {
        #expect(Contact.normalize(" 张 三 ") == "张三")
        #expect(Contact.normalize("Ａlice") == "alice")
    }

    @Test @MainActor func legacyRecordBackfillUsesRelatedContactName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let contact = makeTestContact(name: "旧版联系人", in: context)
        let record = GiftRecord(amount: 600, direction: "received", eventName: "旧版记录")
        record.contact = contact
        record.contactName = ""
        record.contactNameSnapshot = ""
        context.insert(record)

        record.refreshCompatibilityFields()

        #expect(record.contactName == "旧版联系人")
        #expect(record.contactNameSnapshot == "旧版联系人")
        record.contact = nil
        #expect(record.displayName == "旧版联系人")
    }
}

struct RecordCommandUpgradeTests {
    @Test @MainActor func createRecordAndContactAtomically() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let receipt = try RecordCommandService().create(
            RecordDraft(amount: 888, direction: .received, contactName: "张三", eventName: "张三婚礼", eventCategory: "婚礼", eventDate: Date()),
            context: context
        )
        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        let contacts = try context.fetch(FetchDescriptor<Contact>())
        #expect(records.count == 1)
        #expect(contacts.count == 1)
        #expect(records[0].amountMinor == 88_800)
        #expect(records[0].contactNameSnapshot == "张三")
        #expect(receipt.createdContactID == contacts[0].id)
        #expect(contacts[0].cachedRecordCount == 1)
    }

    @Test @MainActor func invalidBatchDoesNotInsertPartialRows() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let drafts = [
            RecordDraft(amount: 100, direction: .received, contactName: "甲", eventName: "测试", eventCategory: "其他", eventDate: Date()),
            RecordDraft(amount: 0, direction: .sent, contactName: "乙", eventName: "测试", eventCategory: "其他", eventDate: Date())
        ]
        #expect(throws: RecordCommandError.self) { try RecordCommandService().createBatch(drafts, context: context) }
        #expect(try context.fetchCount(FetchDescriptor<GiftRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Contact>()) == 0)
    }

    @Test @MainActor func deletingBookRepairsContactAggregate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let book = makeTestBook(in: context)
        let contact = makeTestContact(in: context)
        _ = makeTestRecord(amount: 500, direction: "received", book: book, contact: contact, in: context)
        try GiftBookRepository().delete(book, context: context)
        #expect(contact.recordCount == 0)
        #expect(contact.totalReceived == 0)
    }
}

struct BackupAndImportTests {
    @Test @MainActor func iCloudPreferenceChangesOnlyAfterBackupSucceeds() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        _ = makeTestRecord(in: context)
        let suiteName = "iCloud-change-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let backupDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("icloud-backup-\(UUID())", isDirectory: true)
        let receipt = try ICloudConfigurationChangeService.stageChange(
            to: true,
            context: context,
            defaults: defaults,
            backupDirectory: backupDirectory
        )
        #expect(FileManager.default.fileExists(atPath: receipt.backupURL.path))
        #expect(defaults.bool(forKey: ICloudConfigurationChangeService.enabledKey))
        #expect(defaults.bool(forKey: ICloudConfigurationChangeService.restartRequiredKey))
    }

    @Test @MainActor func failedICloudBackupKeepsPreviousPreference() throws {
        let container = try makeTestContainer()
        let suiteName = "iCloud-change-failure-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(false, forKey: ICloudConfigurationChangeService.enabledKey)

        let invalidDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("not-a-directory-\(UUID())")
        try Data("file".utf8).write(to: invalidDirectory)
        defer { try? FileManager.default.removeItem(at: invalidDirectory) }

        #expect(throws: (any Error).self) {
            try ICloudConfigurationChangeService.stageChange(
                to: true,
                context: container.mainContext,
                defaults: defaults,
                backupDirectory: invalidDirectory
            )
        }
        #expect(!defaults.bool(forKey: ICloudConfigurationChangeService.enabledKey))
        #expect(!defaults.bool(forKey: ICloudConfigurationChangeService.restartRequiredKey))
    }

    @Test @MainActor func backupReplaceRoundTripPreservesRelationships() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let book = makeTestBook(name: "婚礼", in: context)
        let contact = makeTestContact(name: "李四", in: context)
        let record = makeTestRecord(amount: 1_200, direction: "received", book: book, contact: contact, in: context)
        record.note = "原始备注"
        try context.save()

        let url = try BackupService.shared.createBackup(context: context)
        let preview = try BackupService.shared.preview(url: url)
        record.note = "已修改"
        try context.save()
        try BackupService.shared.restore(preview, mode: .replace, context: context)

        let restored = try context.fetch(FetchDescriptor<GiftRecord>())
        #expect(restored.count == 1)
        #expect(restored[0].note == "原始备注")
        #expect(restored[0].book?.name == "婚礼")
        #expect(restored[0].contact?.name == "李四")
    }

    @Test @MainActor func legacyCSVCanBePreviewedAndImported() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-\(UUID()).csv")
        try "序号,姓名,关系,金额,收/送,事件类型,事件名称,日期,备注,账本\n1,王五,朋友,800,收到,婚礼,王五婚礼,2026-07-11,测试,".write(to: url, atomically: true, encoding: .utf8)
        let preview = try CSVImportService().preview(url: url, context: context)
        #expect(preview.validRows.count == 1)
        let count = try CSVImportService().importRows(preview.validRows, includeDuplicates: false, defaultBook: nil, context: context)
        #expect(count == 1)
        #expect(try context.fetchCount(FetchDescriptor<GiftRecord>()) == 1)
    }

    @Test @MainActor func csvExportNeutralizesSpreadsheetFormula() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let contact = makeTestContact(name: "=HYPERLINK(\"bad\")", in: context)
        _ = makeTestRecord(contact: contact, in: context)
        let url = try ExportService.shared.exportAllToCSV(context: context)
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("'=HYPERLINK"))
    }
}

struct SchemaMigrationTests {
    @Test @MainActor func productionShapeV1MigratesToAdditiveV2() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("migration-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("default.store")

        do {
            let schema = Schema(versionedSchema: LiShangJiSchemaV1.self)
            let config = ModelConfiguration("default", schema: schema, url: storeURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext
            let book = LiShangJiSchemaV1.GiftBook(name: "V1 账本")
            let contact = LiShangJiSchemaV1.Contact(name: "线上用户")
            let record = LiShangJiSchemaV1.GiftRecord(amount: 888, direction: "received", eventName: "线上记录")
            record.book = book; record.contact = contact; record.contactName = "线上用户"; record.eventCategory = "婚礼"
            context.insert(book); context.insert(contact); context.insert(record)
            try context.save()
        }

        let schema = Schema(versionedSchema: LiShangJiSchemaV2.self)
        let config = ModelConfiguration("default", schema: schema, url: storeURL, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: LiShangJiMigrationPlan.self, configurations: [config])
        let records = try container.mainContext.fetch(FetchDescriptor<GiftRecord>())
        #expect(records.count == 1)
        #expect(records[0].amount == 888)
        #expect(records[0].contact?.name == "线上用户")
        #expect(records[0].book?.name == "V1 账本")
    }
}
