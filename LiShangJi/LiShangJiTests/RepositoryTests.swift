//
//  RepositoryTests.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Testing
import Foundation
import SwiftData
@testable import LiShangJi

// MARK: - ContactRepository Tests

struct ContactRepositoryTests {
    let repository = ContactRepository()

    @Test @MainActor func create() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = try repository.create(name: "张三", relation: "friend", phone: "13800138000", context: context)

        #expect(contact.name == "张三")
        #expect(contact.relation == "friend")
        #expect(contact.phone == "13800138000")
    }

    @Test @MainActor func fetchAll() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = try repository.create(name: "张三", relation: "friend", phone: "", context: context)
        let _ = try repository.create(name: "李四", relation: "family", phone: "", context: context)
        let _ = try repository.create(name: "王五", relation: "colleague", phone: "", context: context)

        let all = try repository.fetchAll(context: context)
        #expect(all.count == 3)
    }

    @Test @MainActor func fetchByRelation() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = try repository.create(name: "张三", relation: "friend", phone: "", context: context)
        let _ = try repository.create(name: "李四", relation: "friend", phone: "", context: context)
        let _ = try repository.create(name: "王五", relation: "family", phone: "", context: context)

        let friends = try repository.fetchByRelation("friend", context: context)
        #expect(friends.count == 2)

        let family = try repository.fetchByRelation("family", context: context)
        #expect(family.count == 1)
    }

    @Test @MainActor func searchWithQuery() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = try repository.create(name: "张三", relation: "friend", phone: "", context: context)
        let _ = try repository.create(name: "张四", relation: "friend", phone: "", context: context)
        let _ = try repository.create(name: "李五", relation: "family", phone: "", context: context)

        let results = try repository.search(query: "张", context: context)
        #expect(results.count == 2)
    }

    @Test @MainActor func searchEmptyQuery() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = try repository.create(name: "张三", relation: "friend", phone: "", context: context)
        let _ = try repository.create(name: "李四", relation: "family", phone: "", context: context)

        let results = try repository.search(query: "", context: context)
        #expect(results.count == 2) // 空查询返回全部
    }

    @Test @MainActor func update() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = try repository.create(name: "张三", relation: "friend", phone: "", context: context)
        let oldUpdatedAt = contact.updatedAt

        // 等待一小时足够区分时间
        contact.name = "张三丰"
        try repository.update(contact, context: context)

        #expect(contact.name == "张三丰")
        #expect(contact.updatedAt >= oldUpdatedAt)
    }

    @Test @MainActor func delete() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = try repository.create(name: "张三", relation: "friend", phone: "", context: context)
        let allBefore = try repository.fetchAll(context: context)
        #expect(allBefore.count == 1)

        try repository.delete(contact, context: context)
        let allAfter = try repository.fetchAll(context: context)
        #expect(allAfter.count == 0)
    }
}

// MARK: - GiftBookRepository Tests

struct GiftBookRepositoryTests {
    let repository = GiftBookRepository()

    @Test @MainActor func create() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = try repository.create(name: "我的婚礼", icon: "heart.fill", colorHex: "#FF0000", context: context)

        #expect(book.name == "我的婚礼")
        #expect(book.icon == "heart.fill")
        #expect(book.colorHex == "#FF0000")
        #expect(book.isArchived == false)
    }

    @Test @MainActor func fetchAll() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = try repository.create(name: "账本1", icon: "book.fill", colorHex: "#C04851", context: context)
        let _ = try repository.create(name: "账本2", icon: "book.fill", colorHex: "#C04851", context: context)

        let all = try repository.fetchAll(context: context)
        #expect(all.count == 2)
    }

    @Test @MainActor func fetchActiveExcludesArchived() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = try repository.create(name: "活跃账本", icon: "book.fill", colorHex: "#C04851", context: context)
        let archivedBook = try repository.create(name: "归档账本", icon: "book.fill", colorHex: "#C04851", context: context)
        try repository.archive(archivedBook, context: context)

        let active = try repository.fetchActive(context: context)
        #expect(active.count == 1)
        #expect(active.first?.name == "活跃账本")
    }

    @Test @MainActor func fetchArchived() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = try repository.create(name: "活跃账本", icon: "book.fill", colorHex: "#C04851", context: context)
        let archivedBook = try repository.create(name: "归档账本", icon: "book.fill", colorHex: "#C04851", context: context)
        try repository.archive(archivedBook, context: context)

        let archived = try repository.fetchArchived(context: context)
        #expect(archived.count == 1)
        #expect(archived.first?.name == "归档账本")
    }

    @Test @MainActor func archive() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = try repository.create(name: "测试账本", icon: "book.fill", colorHex: "#C04851", context: context)
        #expect(book.isArchived == false)

        try repository.archive(book, context: context)
        #expect(book.isArchived == true)
    }

    @Test @MainActor func update() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = try repository.create(name: "旧名称", icon: "book.fill", colorHex: "#C04851", context: context)
        book.name = "新名称"
        try repository.update(book, context: context)

        #expect(book.name == "新名称")
    }

    @Test @MainActor func delete() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = try repository.create(name: "将删除", icon: "book.fill", colorHex: "#C04851", context: context)
        #expect(try repository.fetchAll(context: context).count == 1)

        try repository.delete(book, context: context)
        #expect(try repository.fetchAll(context: context).count == 0)
    }
}

// MARK: - GiftRecordRepository Tests

struct GiftRecordRepositoryTests {
    let repository = GiftRecordRepository()

    @Test @MainActor func create() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let record = try repository.create(
            amount: 1000,
            direction: "received",
            eventName: "张三婚礼",
            eventCategory: "wedding",
            eventDate: Date(),
            note: "测试备注",
            contactName: "张三",
            book: nil,
            contact: nil,
            context: context
        )

        #expect(record.amount == 1000)
        #expect(record.direction == "received")
        #expect(record.eventName == "张三婚礼")
        #expect(record.eventCategory == "wedding")
        #expect(record.note == "测试备注")
    }

    @Test @MainActor func fetchAll() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestRecord(amount: 100, in: context)
        let _ = makeTestRecord(amount: 200, in: context)
        let _ = makeTestRecord(amount: 300, in: context)

        let all = try repository.fetchAll(context: context)
        #expect(all.count == 3)
    }

    @Test @MainActor func fetchByBook() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = makeTestBook(name: "测试账本", in: context)
        let _ = makeTestRecord(amount: 100, book: book, in: context)
        let _ = makeTestRecord(amount: 200, book: book, in: context)
        let _ = makeTestRecord(amount: 300, in: context) // 不属于此账本

        let bookRecords = try repository.fetchByBook(book, context: context)
        #expect(bookRecords.count == 2)
    }

    @Test @MainActor func fetchByContact() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = makeTestContact(name: "张三", in: context)
        let _ = makeTestRecord(amount: 100, contact: contact, in: context)
        let _ = makeTestRecord(amount: 200, contact: contact, in: context)
        let _ = makeTestRecord(amount: 300, in: context) // 无联系人

        let contactRecords = try repository.fetchByContact(contact, context: context)
        #expect(contactRecords.count == 2)
    }

    @Test @MainActor func fetchRecent() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        for i in 1...10 {
            let _ = makeTestRecord(amount: Double(i * 100), in: context)
        }

        let recent5 = try repository.fetchRecent(limit: 5, context: context)
        #expect(recent5.count == 5)

        let recent3 = try repository.fetchRecent(limit: 3, context: context)
        #expect(recent3.count == 3)
    }

    @Test @MainActor func fetchByDateRange() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let jan = makeDate(year: 2026, month: 1, day: 15)
        let feb = makeDate(year: 2026, month: 2, day: 15)
        let mar = makeDate(year: 2026, month: 3, day: 15)

        let _ = makeTestRecord(amount: 100, eventDate: jan, in: context)
        let _ = makeTestRecord(amount: 200, eventDate: feb, in: context)
        let _ = makeTestRecord(amount: 300, eventDate: mar, in: context)

        let febStart = makeDate(year: 2026, month: 2, day: 1)
        let febEnd = makeDate(year: 2026, month: 3, day: 1)

        let febRecords = try repository.fetchByDateRange(from: febStart, to: febEnd, context: context)
        #expect(febRecords.count == 1)
        #expect(febRecords.first?.amount == 200)
    }

    @Test @MainActor func totalSent() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestRecord(amount: 100, direction: "sent", in: context)
        let _ = makeTestRecord(amount: 200, direction: "sent", in: context)
        let _ = makeTestRecord(amount: 500, direction: "received", in: context)

        let total = try repository.totalSent(context: context)
        #expect(total == 300)
    }

    @Test @MainActor func totalReceived() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestRecord(amount: 100, direction: "sent", in: context)
        let _ = makeTestRecord(amount: 500, direction: "received", in: context)
        let _ = makeTestRecord(amount: 300, direction: "received", in: context)

        let total = try repository.totalReceived(context: context)
        #expect(total == 800)
    }

    @Test @MainActor func update() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let record = makeTestRecord(amount: 100, in: context)
        record.amount = 999
        try repository.update(record, context: context)

        #expect(record.amount == 999)
    }

    @Test @MainActor func delete() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let record = makeTestRecord(amount: 100, in: context)
        #expect(try repository.fetchAll(context: context).count == 1)

        try repository.delete(record, context: context)
        #expect(try repository.fetchAll(context: context).count == 0)
    }
}
