//
//  TestHelpers.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Foundation
import SwiftData
@testable import LiShangJi

/// 创建内存 SwiftData 容器，供测试使用
@MainActor
func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        GiftBook.self,
        GiftRecord.self,
        Contact.self,
        GiftEvent.self,
        EventReminder.self,
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

/// 创建测试用 Contact
@MainActor
func makeTestContact(name: String = "张三", relation: String = "friend", in context: ModelContext) -> Contact {
    let contact = Contact(name: name, relation: relation)
    context.insert(contact)
    try? context.save()
    return contact
}

/// 创建测试用 GiftBook
@MainActor
func makeTestBook(name: String = "测试账本", in context: ModelContext) -> GiftBook {
    let book = GiftBook(name: name)
    context.insert(book)
    try? context.save()
    return book
}

/// 创建测试用 GiftRecord（同时更新关联的缓存聚合字段）
@MainActor
func makeTestRecord(
    amount: Double = 1000,
    direction: String = "received",
    eventName: String = "测试事件",
    book: GiftBook? = nil,
    contact: Contact? = nil,
    eventDate: Date = Date(),
    in context: ModelContext
) -> GiftRecord {
    let record = GiftRecord(amount: amount, direction: direction, eventName: eventName)
    record.book = book
    record.contact = contact
    record.eventDate = eventDate
    context.insert(record)

    // 更新缓存聚合字段
    contact?.updateCacheForAddedRecord(amount: amount, direction: direction)
    book?.updateCacheForAddedRecord(amount: amount, direction: direction)

    try? context.save()
    return record
}

/// 创建指定日期的辅助方法
func makeDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return Calendar.current.date(from: components)!
}
