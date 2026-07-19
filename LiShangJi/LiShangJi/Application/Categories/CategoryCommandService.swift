import Foundation
import SwiftData

@MainActor
struct CategoryCommandService {
    func save(_ category: CategoryItem, context: ModelContext) throws {
        do {
            category.updatedAt = Date()
            if category.modelContext == nil { context.insert(category) }
            try context.save()
        } catch { context.rollback(); throw error }
    }

    func delete(_ categories: [CategoryItem], context: ModelContext) throws {
        do {
            categories.forEach(context.delete)
            try context.save()
        } catch { context.rollback(); throw error }
    }

    func saveOrder(_ categories: [CategoryItem], startingAt: Int, context: ModelContext) throws {
        do {
            for (index, category) in categories.enumerated() {
                category.sortOrder = startingAt + index
                category.updatedAt = Date()
            }
            try context.save()
        } catch { context.rollback(); throw error }
    }
}
