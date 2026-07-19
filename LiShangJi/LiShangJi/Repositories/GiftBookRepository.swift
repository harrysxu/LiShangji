//
//  GiftBookRepository.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 账本数据访问实现
struct GiftBookRepository: GiftBookRepositoryProtocol {

    func fetchAll(context: ModelContext) throws -> [GiftBook] {
        let descriptor = FetchDescriptor<GiftBook>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchActive(context: ModelContext) throws -> [GiftBook] {
        let predicate = #Predicate<GiftBook> { book in
            book.isArchived == false
        }
        let descriptor = FetchDescriptor<GiftBook>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchArchived(context: ModelContext) throws -> [GiftBook] {
        let predicate = #Predicate<GiftBook> { book in
            book.isArchived == true
        }
        let descriptor = FetchDescriptor<GiftBook>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func create(name: String, icon: String, colorHex: String, context: ModelContext) throws -> GiftBook {
        let book = GiftBook(name: name, icon: icon, colorHex: colorHex)
        context.insert(book)
        try context.save()
        return book
    }

    func update(_ book: GiftBook, context: ModelContext) throws {
        book.updatedAt = Date()
        try context.save()
    }

    func archive(_ book: GiftBook, context: ModelContext) throws {
        book.isArchived = true
        book.updatedAt = Date()
        try context.save()
    }

    func delete(_ book: GiftBook, context: ModelContext) throws {
        let deletedRecords = book.records ?? []
        let deletedIDs = Set(deletedRecords.map(\.id))
        let contacts = Dictionary(uniqueKeysWithValues: deletedRecords.compactMap { record in
            record.contact.map { ($0.id, $0) }
        })
        do {
            for record in deletedRecords { context.delete(record) }
            context.delete(book)
            for contact in contacts.values {
                let remaining = (contact.records ?? []).filter { !deletedIDs.contains($0.id) }
                contact.cachedTotalReceived = remaining.filter { $0.direction == GiftDirection.received.rawValue }.reduce(0) { $0 + $1.amount }
                contact.cachedTotalSent = remaining.filter { $0.direction == GiftDirection.sent.rawValue }.reduce(0) { $0 + $1.amount }
                contact.cachedRecordCount = remaining.count
                contact.refreshCompatibilityFields()
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
