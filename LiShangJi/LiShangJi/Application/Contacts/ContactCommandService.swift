import Foundation
import SwiftData

@MainActor
struct ContactCommandService {
    func create(names: [String], context: ModelContext) throws -> [Contact] {
        let normalizedNames = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        do {
            let contacts = normalizedNames.map { Contact(name: $0) }
            contacts.forEach(context.insert)
            try context.save()
            return contacts
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(_ contact: Contact, context: ModelContext) throws {
        do {
            context.delete(contact)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func save(_ contact: Contact, context: ModelContext) throws {
        do {
            contact.updatedAt = Date()
            contact.refreshCompatibilityFields()
            if contact.modelContext == nil { context.insert(contact) }
            try context.save()
        } catch { context.rollback(); throw error }
    }

    func merge(_ source: Contact, into target: Contact, context: ModelContext) throws {
        guard source.id != target.id else { return }
        do {
            if source.name != target.name && !(target.aliases ?? []).contains(where: { Contact.normalize($0.name) == Contact.normalize(source.name) }) {
                context.insert(ContactAlias(name: source.name, contact: target))
            }
            for alias in source.aliases ?? [] { alias.contact = target }
            for record in source.records ?? [] {
                record.contact = target
                if record.contactNameSnapshot.isEmpty { record.contactNameSnapshot = source.name }
            }
            for reminder in source.eventReminders ?? [] {
                var contacts = (reminder.contacts ?? []).filter { $0.id != source.id }
                if !contacts.contains(where: { $0.id == target.id }) { contacts.append(target) }
                reminder.contacts = contacts
            }
            source.mergedIntoContactID = target.id
            source.records = []
            source.eventReminders = []
            source.cachedRecordCount = 0
            source.cachedTotalReceived = 0
            source.cachedTotalSent = 0
            target.recalculateCachedAggregates()
            target.refreshCompatibilityFields()
            target.updatedAt = Date()
            try context.save()
        } catch { context.rollback(); throw error }
    }
}
