//
//  ModelTests.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Testing
import Foundation
import SwiftData
@testable import LiShangJi

// MARK: - Contact Model Tests

struct ContactModelTests {

    @Test @MainActor func initDefaultValues() throws {
        let contact = Contact(name: "张三")
        #expect(contact.name == "张三")
        #expect(contact.relation == "other")
        #expect(contact.phone == "")
        #expect(contact.group == "")
        #expect(contact.note == "")
        #expect(contact.avatarSystemName == "person.circle.fill")
        #expect(contact.hasBirthday == false)
        #expect(contact.lunarBirthday == "")
        #expect(contact.systemContactID == "")
    }

    @Test @MainActor func initWithRelation() throws {
        let contact = Contact(name: "李四", relation: "friend")
        #expect(contact.name == "李四")
        #expect(contact.relation == "friend")
    }

    @Test @MainActor func relationType() throws {
        let contact = Contact(name: "王五", relation: "family")
        #expect(contact.relationType == .family)
    }

    @Test @MainActor func relationTypeInvalid() throws {
        let contact = Contact(name: "赵六", relation: "invalid_value")
        #expect(contact.relationType == .other)
    }

    @Test @MainActor func computedPropertiesWithRecords() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = makeTestContact(name: "测试人", in: context)

        // 创建收到记录
        let _ = makeTestRecord(amount: 1000, direction: "received", contact: contact, in: context)
        let _ = makeTestRecord(amount: 500, direction: "received", contact: contact, in: context)

        // 创建送出记录
        let _ = makeTestRecord(amount: 800, direction: "sent", contact: contact, in: context)

        #expect(contact.totalReceived == 1500)
        #expect(contact.totalSent == 800)
        #expect(contact.balance == 700)
        #expect(contact.recordCount == 3)
    }

    @Test @MainActor func computedPropertiesNoRecords() throws {
        let contact = Contact(name: "空记录")
        #expect(contact.totalReceived == 0)
        #expect(contact.totalSent == 0)
        #expect(contact.balance == 0)
        #expect(contact.recordCount == 0)
    }
}

// MARK: - GiftBook Model Tests

struct GiftBookModelTests {

    @Test @MainActor func initDefaultValues() throws {
        let book = GiftBook(name: "我的婚礼")
        #expect(book.name == "我的婚礼")
        #expect(book.icon == "book.closed.fill")
        #expect(book.colorHex == "#C04851")
        #expect(book.note == "")
        #expect(book.isArchived == false)
        #expect(book.sortOrder == 0)
    }

    @Test @MainActor func initWithCustomValues() throws {
        let book = GiftBook(name: "春节", icon: "gift.fill", colorHex: "#FF0000")
        #expect(book.name == "春节")
        #expect(book.icon == "gift.fill")
        #expect(book.colorHex == "#FF0000")
    }

    @Test @MainActor func computedPropertiesWithRecords() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = makeTestBook(name: "测试账本", in: context)

        let _ = makeTestRecord(amount: 2000, direction: "received", book: book, in: context)
        let _ = makeTestRecord(amount: 1000, direction: "received", book: book, in: context)
        let _ = makeTestRecord(amount: 500, direction: "sent", book: book, in: context)

        #expect(book.totalReceived == 3000)
        #expect(book.totalSent == 500)
        #expect(book.balance == 2500)
        #expect(book.recordCount == 3)
    }

    @Test @MainActor func computedPropertiesNoRecords() throws {
        let book = GiftBook(name: "空账本")
        #expect(book.totalReceived == 0)
        #expect(book.totalSent == 0)
        #expect(book.balance == 0)
        #expect(book.recordCount == 0)
    }
}

// MARK: - GiftRecord Model Tests

struct GiftRecordModelTests {

    @Test func initDefaultValues() {
        let record = GiftRecord(amount: 888, direction: "received", eventName: "张三婚礼")
        #expect(record.amount == 888)
        #expect(record.direction == "received")
        #expect(record.eventName == "张三婚礼")
        #expect(record.recordType == "gift")
        #expect(record.eventCategory == "wedding")
        #expect(record.note == "")
        #expect(record.source == "manual")
        #expect(record.isLoanSettled == false)
    }

    @Test func giftDirection() {
        let sentRecord = GiftRecord(amount: 500, direction: "sent", eventName: "送礼")
        #expect(sentRecord.giftDirection == .sent)

        let receivedRecord = GiftRecord(amount: 500, direction: "received", eventName: "收礼")
        #expect(receivedRecord.giftDirection == .received)
    }

    @Test func giftDirectionInvalid() {
        let record = GiftRecord(amount: 500, direction: "invalid", eventName: "测试")
        #expect(record.giftDirection == .sent) // 默认为 sent
    }

    @Test func eventCategoryDisplayName() {
        let record = GiftRecord(amount: 500, direction: "sent", eventName: "测试")
        record.eventCategory = "生日"
        #expect(record.eventCategoryDisplayName == "生日")
    }

    @Test func eventCategoryDefaultValue() {
        let record = GiftRecord(amount: 500, direction: "sent", eventName: "测试")
        #expect(record.eventCategory == "婚礼") // 默认值
    }

    @Test func giftRecordType() {
        let giftRecord = GiftRecord(amount: 500, direction: "sent", eventName: "测试")
        #expect(giftRecord.giftRecordType == .gift)

        let loanRecord = GiftRecord(amount: 500, direction: "sent", eventName: "测试")
        loanRecord.recordType = "loan"
        #expect(loanRecord.giftRecordType == .loan)
    }

    @Test func isReceived() {
        let receivedRecord = GiftRecord(amount: 500, direction: "received", eventName: "收礼")
        #expect(receivedRecord.isReceived == true)

        let sentRecord = GiftRecord(amount: 500, direction: "sent", eventName: "送礼")
        #expect(sentRecord.isReceived == false)
    }
}

// MARK: - GiftEvent Model Tests

struct GiftEventModelTests {

    @Test func initValues() {
        let event = GiftEvent(name: "婚礼", category: "wedding", icon: "heart.fill", isBuiltIn: true, sortOrder: 0)
        #expect(event.name == "婚礼")
        #expect(event.category == "wedding")
        #expect(event.icon == "heart.fill")
        #expect(event.isBuiltIn == true)
        #expect(event.sortOrder == 0)
    }

    @Test func eventCategory() {
        let event = GiftEvent(name: "生日", category: "birthday", icon: "gift.fill")
        #expect(event.eventCategory == .birthday)
    }

    @Test func eventCategoryInvalid() {
        let event = GiftEvent(name: "自定义", category: "custom_value", icon: "star.fill")
        #expect(event.eventCategory == .other)
    }
}
