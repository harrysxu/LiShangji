import Foundation
import SwiftData

@MainActor
struct BookCommandService {
    func save(_ book: GiftBook, context: ModelContext) throws {
        guard EntitlementPolicy(isPremium: PremiumManager.shared.isPremium).canCreateBook(existingActiveBookCount: (try? context.fetchCount(FetchDescriptor<GiftBook>(predicate: #Predicate { !$0.isArchived }))) ?? 0) || book.modelContext != nil else {
            throw RecordCommandError.premiumRequired
        }
        do {
            book.updatedAt = Date()
            if book.modelContext == nil { context.insert(book) }
            try context.save()
        } catch { context.rollback(); throw error }
    }
}
