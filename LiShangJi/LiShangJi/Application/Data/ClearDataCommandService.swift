import Foundation
import SwiftData

@MainActor
struct ClearDataCommandService {
    @discardableResult
    func execute(context: ModelContext) throws -> URL {
        let snapshot = try BackupService.shared.createBackup(context: context, directory: AppModelContainerFactory.recoveryDirectory())
        do {
            try context.delete(model: ContactAlias.self)
            try context.delete(model: GiftRecord.self)
            try context.delete(model: EventReminder.self)
            try context.delete(model: GiftBook.self)
            try context.delete(model: Contact.self)
            try context.delete(model: GiftEvent.self)
            try context.delete(model: CategoryItem.self)
            try context.save()
            NotificationService.shared.cancelAll()
            SeedDataService.seedBuiltInCategories(context: context)
            SeedDataService.seedBuiltInEvents(context: context)
            return snapshot
        } catch {
            context.rollback()
            throw error
        }
    }
}
