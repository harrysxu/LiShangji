//
//  EventReminderRepository.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import Foundation
import SwiftData

/// 事件提醒数据访问实现
struct EventReminderRepository: EventReminderRepositoryProtocol {

    func fetchAll(context: ModelContext) throws -> [EventReminder] {
        let descriptor = FetchDescriptor<EventReminder>(
            sortBy: [SortDescriptor(\.eventDate, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func fetchUpcoming(context: ModelContext) throws -> [EventReminder] {
        let now = Date()
        let predicate = #Predicate<EventReminder> { event in
            event.eventDate >= now && event.isCompleted == false
        }
        let descriptor = FetchDescriptor<EventReminder>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func fetchOverdue(context: ModelContext) throws -> [EventReminder] {
        let now = Date()
        let predicate = #Predicate<EventReminder> { event in
            event.eventDate < now && event.isCompleted == false
        }
        let descriptor = FetchDescriptor<EventReminder>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByCategory(_ category: String, context: ModelContext) throws -> [EventReminder] {
        let predicate = #Predicate<EventReminder> { event in
            event.eventCategory == category
        }
        let descriptor = FetchDescriptor<EventReminder>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByContact(_ contact: Contact, context: ModelContext) throws -> [EventReminder] {
        let allEvents = try fetchAll(context: context)
        return allEvents.filter { event in
            (event.contacts ?? []).contains { $0.id == contact.id }
        }
    }

    func search(query: String, context: ModelContext) throws -> [EventReminder] {
        guard !query.isEmpty else {
            return try fetchAll(context: context)
        }
        let predicate = #Predicate<EventReminder> { event in
            event.title.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<EventReminder>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.eventDate, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func create(title: String, eventCategory: String, eventDate: Date, context: ModelContext) throws -> EventReminder {
        let event = EventReminder(title: title, eventCategory: eventCategory, eventDate: eventDate)
        context.insert(event)
        try context.save()
        return event
    }

    func update(_ event: EventReminder, context: ModelContext) throws {
        event.updatedAt = Date()
        try context.save()
    }

    func delete(_ event: EventReminder, context: ModelContext) throws {
        context.delete(event)
        try context.save()
    }

    func toggleComplete(_ event: EventReminder, context: ModelContext) throws {
        event.isCompleted.toggle()
        event.updatedAt = Date()
        try context.save()
    }
}
