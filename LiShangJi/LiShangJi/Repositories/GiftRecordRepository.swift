//
//  GiftRecordRepository.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 礼金记录数据访问实现
struct GiftRecordRepository: GiftRecordRepositoryProtocol {

    func fetchAll(context: ModelContext) throws -> [GiftRecord] {
        let descriptor = FetchDescriptor<GiftRecord>(
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByBook(_ book: GiftBook, context: ModelContext) throws -> [GiftRecord] {
        let bookID = book.persistentModelID
        let predicate = #Predicate<GiftRecord> { record in
            record.book?.persistentModelID == bookID
        }
        let descriptor = FetchDescriptor<GiftRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByContact(_ contact: Contact, context: ModelContext) throws -> [GiftRecord] {
        let contactID = contact.persistentModelID
        let predicate = #Predicate<GiftRecord> { record in
            record.contact?.persistentModelID == contactID
        }
        let descriptor = FetchDescriptor<GiftRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchRecent(limit: Int, context: ModelContext) throws -> [GiftRecord] {
        var descriptor = FetchDescriptor<GiftRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func fetchByDateRange(from startDate: Date, to endDate: Date, context: ModelContext) throws -> [GiftRecord] {
        let predicate = #Predicate<GiftRecord> { record in
            record.eventDate >= startDate && record.eventDate < endDate
        }
        let descriptor = FetchDescriptor<GiftRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func create(
        amount: Double,
        direction: String,
        eventName: String,
        eventCategory: String,
        eventDate: Date,
        note: String,
        book: GiftBook?,
        contact: Contact?,
        context: ModelContext
    ) throws -> GiftRecord {
        let record = GiftRecord(amount: amount, direction: direction, eventName: eventName)
        record.eventCategory = eventCategory
        record.eventDate = eventDate
        record.note = note
        record.book = book
        record.contact = contact
        context.insert(record)
        try context.save()
        return record
    }

    func update(_ record: GiftRecord, context: ModelContext) throws {
        record.updatedAt = Date()
        try context.save()
    }

    func delete(_ record: GiftRecord, context: ModelContext) throws {
        context.delete(record)
        try context.save()
    }

    func totalSent(context: ModelContext) throws -> Double {
        let sentValue = GiftDirection.sent.rawValue
        let predicate = #Predicate<GiftRecord> { record in
            record.direction == sentValue
        }
        let records = try context.fetch(FetchDescriptor<GiftRecord>(predicate: predicate))
        return records.reduce(0) { $0 + $1.amount }
    }

    func totalReceived(context: ModelContext) throws -> Double {
        let receivedValue = GiftDirection.received.rawValue
        let predicate = #Predicate<GiftRecord> { record in
            record.direction == receivedValue
        }
        let records = try context.fetch(FetchDescriptor<GiftRecord>(predicate: predicate))
        return records.reduce(0) { $0 + $1.amount }
    }
}
