import Foundation
import SwiftData

enum CompatibilityBackfillService {
    private static let receiptKey = "didCompleteSchemaV2Backfill"

    @MainActor
    static func runIfNeeded(context: ModelContext) throws {
        guard !UserDefaults.standard.bool(forKey: receiptKey) else { return }

        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        for record in records { record.refreshCompatibilityFields() }

        let contacts = try context.fetch(FetchDescriptor<Contact>())
        for contact in contacts {
            contact.refreshCompatibilityFields()
            contact.recalculateCachedAggregates()
        }

        let books = try context.fetch(FetchDescriptor<GiftBook>())
        for book in books { book.recalculateCachedAggregates() }

        let categories = try context.fetch(FetchDescriptor<CategoryItem>())
        for category in categories where category.isBuiltIn && category.code == nil {
            category.code = EventCategory.allCases.first(where: { $0.displayName == category.name })?.rawValue
        }

        try context.save()
        UserDefaults.standard.set(true, forKey: receiptKey)
    }
}
