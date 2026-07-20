//
//  SearchFilterService.swift
//  LiShangJi
//
//  全局搜索与记录筛选服务
//

import Foundation
import SwiftData

struct RecordFilterOptions {
    var query: String = ""
    var startDate: Date?
    var endDate: Date?
    var direction: GiftDirection?
    var recordType: RecordType?
    var bookIDs: Set<UUID> = []
    var categoryNames: Set<String> = []
    var sources: Set<String> = []
    var minAmount: Double?
    var maxAmount: Double?
    var relationTypes: Set<String> = []
}

struct GlobalSearchResult {
    var records: [GiftRecord]
    var contacts: [Contact]
    var books: [GiftBook]
    var events: [EventReminder]
}

final class SearchFilterService {
    static let shared = SearchFilterService()
    private init() {}

    func globalSearch(query: String, context: ModelContext) throws -> GlobalSearchResult {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return GlobalSearchResult(records: [], contacts: [], books: [], events: [])
        }

        let records = try context.fetch(FetchDescriptor<GiftRecord>()).filter { record in
            record.displayName.localizedStandardContains(normalized)
                || record.eventName.localizedStandardContains(normalized)
                || record.eventCategory.localizedStandardContains(normalized)
                || record.note.localizedStandardContains(normalized)
                || record.book?.name.localizedStandardContains(normalized) == true
                || String(Int(record.amount)).contains(normalized)
        }
        let contacts = try context.fetch(FetchDescriptor<Contact>()).filter {
            $0.name.localizedStandardContains(normalized)
                || $0.phone.localizedStandardContains(normalized)
                || $0.note.localizedStandardContains(normalized)
        }
        let books = try context.fetch(FetchDescriptor<GiftBook>()).filter {
            $0.name.localizedStandardContains(normalized)
                || $0.note.localizedStandardContains(normalized)
        }
        let events = try context.fetch(FetchDescriptor<EventReminder>()).filter {
            $0.title.localizedStandardContains(normalized)
                || $0.note.localizedStandardContains(normalized)
                || $0.eventCategory.localizedStandardContains(normalized)
        }

        return GlobalSearchResult(records: records, contacts: contacts, books: books, events: events)
    }

    func filterRecords(options: RecordFilterOptions, context: ModelContext) throws -> [GiftRecord] {
        var records = try context.fetch(FetchDescriptor<GiftRecord>(
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        ))

        if !options.query.isEmpty {
            records = records.filter {
                $0.displayName.localizedStandardContains(options.query)
                    || $0.eventName.localizedStandardContains(options.query)
                    || $0.note.localizedStandardContains(options.query)
            }
        }
        if let startDate = options.startDate {
            records = records.filter { $0.eventDate >= startDate }
        }
        if let endDate = options.endDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
            records = records.filter { $0.eventDate < endOfDay }
        }
        if let direction = options.direction {
            records = records.filter { $0.direction == direction.rawValue }
        }
        if let recordType = options.recordType {
            records = records.filter { $0.giftRecordType == recordType }
        }
        if !options.bookIDs.isEmpty {
            records = records.filter { record in
                guard let bookID = record.book?.id else { return false }
                return options.bookIDs.contains(bookID)
            }
        }
        if !options.categoryNames.isEmpty {
            records = records.filter { options.categoryNames.contains($0.eventCategory) }
        }
        if !options.sources.isEmpty {
            records = records.filter { options.sources.contains($0.source) }
        }
        if let minAmount = options.minAmount {
            records = records.filter { $0.amount >= minAmount }
        }
        if let maxAmount = options.maxAmount {
            records = records.filter { $0.amount <= maxAmount }
        }
        if !options.relationTypes.isEmpty {
            records = records.filter { record in
                guard let relation = record.contact?.relation else { return false }
                return options.relationTypes.contains(relation)
            }
        }

        return records
    }
}
