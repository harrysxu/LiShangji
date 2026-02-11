//
//  ViewModelTests.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Testing
import Foundation
import SwiftUI
import SwiftData
@testable import LiShangJi

// MARK: - RecordViewModel Tests

struct RecordViewModelTests {

    @Test func parsedAmountEmpty() {
        let vm = RecordViewModel()
        vm.amount = ""
        #expect(vm.parsedAmount == 0)
    }

    @Test func parsedAmountValid() {
        let vm = RecordViewModel()
        vm.amount = "888"
        #expect(vm.parsedAmount == 888)
    }

    @Test func parsedAmountDecimal() {
        let vm = RecordViewModel()
        vm.amount = "66.6"
        #expect(vm.parsedAmount == 66.6)
    }

    @Test func parsedAmountInvalid() {
        let vm = RecordViewModel()
        vm.amount = "abc"
        #expect(vm.parsedAmount == 0)
    }

    @Test @MainActor func saveRecordFailsWithZeroAmount() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "0"
        vm.contactName = "张三"

        let result = vm.saveRecord(context: context)
        #expect(result == false)
        #expect(vm.errorMessage == "请输入金额")
    }

    @Test @MainActor func saveRecordFailsWithEmptyContact() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "1000"
        vm.contactName = ""

        let result = vm.saveRecord(context: context)
        #expect(result == false)
        #expect(vm.errorMessage == "请输入联系人")
    }

    @Test @MainActor func saveRecordFailsWithWhitespaceContact() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "1000"
        vm.contactName = "   "

        let result = vm.saveRecord(context: context)
        #expect(result == false)
        #expect(vm.errorMessage == "请输入联系人")
    }

    @Test @MainActor func saveRecordSuccess() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "1000"
        vm.contactName = "张三"
        vm.direction = .received
        vm.selectedCategoryName = "婚礼"

        let result = vm.saveRecord(context: context)
        #expect(result == true)
        #expect(vm.isSaved == true)
        #expect(vm.errorMessage == nil)

        // 验证记录已创建
        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        #expect(records.count == 1)
        #expect(records.first?.amount == 1000)
        #expect(records.first?.direction == "received")
    }

    @Test @MainActor func saveRecordWithExistingContact() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = makeTestContact(name: "张三", in: context)

        let vm = RecordViewModel()
        vm.amount = "500"
        vm.contactName = "张三"
        vm.selectedContact = contact
        vm.direction = .sent

        let result = vm.saveRecord(context: context)
        #expect(result == true)

        // 验证使用了已有联系人
        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        #expect(records.first?.contact?.name == "张三")

        // 不应创建新联系人
        let contacts = try context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
    }

    @Test func reset() {
        let vm = RecordViewModel()
        vm.amount = "1000"
        vm.direction = .received
        vm.contactName = "张三"
        vm.eventName = "婚礼"
        vm.note = "测试备注"
        vm.errorMessage = "错误"
        vm.isSaved = true

        vm.reset()

        #expect(vm.amount == "")
        #expect(vm.direction == .sent)
        #expect(vm.contactName == "")
        #expect(vm.selectedContact == nil)
        #expect(vm.eventName == "")
        #expect(vm.selectedCategoryName == "婚礼")
        #expect(vm.note == "")
        #expect(vm.errorMessage == nil)
        #expect(vm.isSaved == false)
    }

    @Test @MainActor func searchContacts() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestContact(name: "张三", in: context)
        let _ = makeTestContact(name: "张四", in: context)
        let _ = makeTestContact(name: "李五", in: context)

        let vm = RecordViewModel()
        vm.searchContacts(query: "张", context: context)
        #expect(vm.contactSuggestions.count == 2)
    }

    @Test @MainActor func searchContactsEmptyQuery() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestContact(name: "张三", in: context)

        let vm = RecordViewModel()
        vm.searchContacts(query: "", context: context)
        #expect(vm.contactSuggestions.isEmpty)
    }

    @Test func selectContact() {
        let vm = RecordViewModel()
        let contact = Contact(name: "张三", relation: "friend")

        vm.selectContact(contact)

        #expect(vm.selectedContact === contact)
        #expect(vm.contactName == "张三")
        #expect(vm.contactSuggestions.isEmpty)
    }
}

// MARK: - GiftBookViewModel Tests

struct GiftBookViewModelTests {

    @Test @MainActor func loadBooks() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let repo = GiftBookRepository()
        let _ = try repo.create(name: "活跃1", icon: "book.fill", colorHex: "#C04851", context: context)
        let _ = try repo.create(name: "活跃2", icon: "book.fill", colorHex: "#C04851", context: context)
        let archivedBook = try repo.create(name: "归档", icon: "book.fill", colorHex: "#C04851", context: context)
        try repo.archive(archivedBook, context: context)

        let vm = GiftBookViewModel()
        vm.loadBooks(context: context)

        #expect(vm.books.count == 2)
        #expect(vm.archivedBooks.count == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test @MainActor func createBook() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = GiftBookViewModel()
        vm.createBook(name: "新账本", icon: "heart.fill", colorHex: "#FF0000", context: context)

        #expect(vm.books.count == 1)
        #expect(vm.books.first?.name == "新账本")
    }

    @Test @MainActor func archiveBook() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = GiftBookViewModel()
        vm.createBook(name: "将归档", icon: "book.fill", colorHex: "#C04851", context: context)
        #expect(vm.books.count == 1)

        let book = vm.books.first!
        vm.archiveBook(book, context: context)

        #expect(vm.books.count == 0)
        #expect(vm.archivedBooks.count == 1)
    }

    @Test @MainActor func deleteBook() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = GiftBookViewModel()
        vm.createBook(name: "将删除", icon: "book.fill", colorHex: "#C04851", context: context)
        #expect(vm.books.count == 1)

        let book = vm.books.first!
        vm.deleteBook(book, context: context)

        #expect(vm.books.count == 0)
    }
}

// MARK: - HomeViewModel Tests

struct HomeViewModelTests {

    @Test @MainActor func loadData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // 创建本月数据
        let now = Date()
        let _ = makeTestRecord(amount: 1000, direction: "received", eventDate: now, in: context)
        let _ = makeTestRecord(amount: 500, direction: "received", eventDate: now, in: context)
        let _ = makeTestRecord(amount: 800, direction: "sent", eventDate: now, in: context)

        let vm = HomeViewModel()
        vm.loadData(context: context)

        #expect(vm.totalReceived == 1500)
        #expect(vm.totalSent == 800)
        #expect(vm.errorMessage == nil)
    }

    @Test func balance() {
        let vm = HomeViewModel()
        vm.totalReceived = 2000
        vm.totalSent = 800
        #expect(vm.balance == 1200)
    }

    @Test func balanceNegative() {
        let vm = HomeViewModel()
        vm.totalReceived = 500
        vm.totalSent = 1000
        #expect(vm.balance == -500)
    }

    @Test @MainActor func loadDataRecentRecords() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date()
        for i in 1...15 {
            let _ = makeTestRecord(amount: Double(i * 100), eventDate: now, in: context)
        }

        let vm = HomeViewModel()
        vm.loadData(context: context)

        #expect(vm.recentRecords.count == 10) // limit 10
    }

    @Test @MainActor func loadDataEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = HomeViewModel()
        vm.loadData(context: context)

        #expect(vm.totalReceived == 0)
        #expect(vm.totalSent == 0)
        #expect(vm.recentRecords.isEmpty)
        #expect(vm.errorMessage == nil)
    }
}

// MARK: - StatisticsViewModel Tests

struct StatisticsViewModelTests {

    @Test @MainActor func loadDataTotals() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestRecord(amount: 1000, direction: "received", in: context)
        let _ = makeTestRecord(amount: 500, direction: "received", in: context)
        let _ = makeTestRecord(amount: 800, direction: "sent", in: context)

        let vm = StatisticsViewModel()
        vm.loadData(context: context)

        #expect(vm.totalReceived == 1500)
        #expect(vm.totalSent == 800)
        #expect(vm.recordCount == 3)
        #expect(vm.balance == 700)
    }

    @Test @MainActor func loadDataEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = StatisticsViewModel()
        vm.loadData(context: context)

        #expect(vm.totalReceived == 0)
        #expect(vm.totalSent == 0)
        #expect(vm.recordCount == 0)
    }

    @Test @MainActor func timeFilterYear() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let date2025 = makeDate(year: 2025, month: 6, day: 15)
        let date2026 = makeDate(year: 2026, month: 1, day: 15)

        let _ = makeTestRecord(amount: 1000, direction: "received", eventDate: date2025, in: context)
        let _ = makeTestRecord(amount: 500, direction: "received", eventDate: date2026, in: context)

        let vm = StatisticsViewModel()

        // 全部
        vm.timeFilter = .allTime
        vm.loadData(context: context)
        #expect(vm.totalReceived == 1500)
        #expect(vm.recordCount == 2)

        // 仅2026
        vm.timeFilter = .year(2026)
        vm.loadData(context: context)
        #expect(vm.totalReceived == 500)
        #expect(vm.recordCount == 1)

        // 仅2025
        vm.timeFilter = .year(2025)
        vm.loadData(context: context)
        #expect(vm.totalReceived == 1000)
        #expect(vm.recordCount == 1)
    }

    @Test @MainActor func availableYears() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestRecord(amount: 100, eventDate: makeDate(year: 2024, month: 6, day: 1), in: context)
        let _ = makeTestRecord(amount: 200, eventDate: makeDate(year: 2025, month: 6, day: 1), in: context)
        let _ = makeTestRecord(amount: 300, eventDate: makeDate(year: 2026, month: 1, day: 1), in: context)

        let vm = StatisticsViewModel()
        vm.loadData(context: context)

        #expect(vm.availableYears.count == 3)
        #expect(vm.availableYears.contains(2024))
        #expect(vm.availableYears.contains(2025))
        #expect(vm.availableYears.contains(2026))
        // 验证降序排列
        #expect(vm.availableYears.first == 2026)
    }

    @Test func balanceComputed() {
        let vm = StatisticsViewModel()
        vm.totalReceived = 3000
        vm.totalSent = 2000
        #expect(vm.balance == 1000)
    }

    @Test @MainActor func topContacts() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact1 = makeTestContact(name: "张三", in: context)
        let contact2 = makeTestContact(name: "李四", in: context)

        let _ = makeTestRecord(amount: 2000, direction: "received", contact: contact1, in: context)
        let _ = makeTestRecord(amount: 1000, direction: "sent", contact: contact1, in: context)
        let _ = makeTestRecord(amount: 500, direction: "received", contact: contact2, in: context)

        let vm = StatisticsViewModel()
        vm.loadData(context: context)

        #expect(vm.topContacts.count == 2)
        // 张三排第一（总额 3000 > 李四 500）
        #expect(vm.topContacts.first?.name == "张三")
        #expect(vm.topContacts.first?.received == 2000)
        #expect(vm.topContacts.first?.sent == 1000)
    }
}

// MARK: - NavigationRouter Tests

struct NavigationRouterTests {

    @Test func initialState() {
        let router = NavigationRouter()
        #expect(router.selectedTab == .home)
        #expect(router.showingRecordEntry == false)
        #expect(router.showingOCRScanner == false)
        #expect(router.showingVoiceInput == false)
        #expect(router.selectedBookForEntry == nil)
    }

    @Test func resetToRoot() {
        let router = NavigationRouter()

        // 模拟导航操作
        router.homePath.append(UUID())
        router.booksPath.append(UUID())
        router.statisticsPath.append(UUID())
        router.profilePath.append(UUID())

        #expect(router.homePath.count == 1)
        #expect(router.booksPath.count == 1)

        router.resetToRoot()

        #expect(router.homePath.count == 0)
        #expect(router.booksPath.count == 0)
        #expect(router.statisticsPath.count == 0)
        #expect(router.profilePath.count == 0)
    }

    @Test func tabSwitching() {
        let router = NavigationRouter()

        router.selectedTab = .books
        #expect(router.selectedTab == .books)

        router.selectedTab = .statistics
        #expect(router.selectedTab == .statistics)

        router.selectedTab = .profile
        #expect(router.selectedTab == .profile)

        router.selectedTab = .home
        #expect(router.selectedTab == .home)
    }
}

// MARK: - AppTab Tests

struct AppTabTests {

    @Test func allCasesCount() {
        #expect(AppTab.allCases.count == 4)
    }

    @Test func rawValues() {
        #expect(AppTab.home.rawValue == "首页")
        #expect(AppTab.books.rawValue == "账本")
        #expect(AppTab.statistics.rawValue == "统计")
        #expect(AppTab.profile.rawValue == "我的")
    }

    @Test func icons() {
        #expect(AppTab.home.icon == "house.fill")
        #expect(AppTab.books.icon == "book.closed.fill")
        #expect(AppTab.statistics.icon == "chart.bar.fill")
        #expect(AppTab.profile.icon == "person.fill")
    }
}

// MARK: - StatisticsTimeFilter Tests

struct StatisticsTimeFilterTests {

    @Test func displayNameAllTime() {
        let filter = StatisticsTimeFilter.allTime
        #expect(filter.displayName == "全部")
    }

    @Test func displayNameYear() {
        let filter = StatisticsTimeFilter.year(2026)
        #expect(filter.displayName == "2026年")
    }

    @Test func equatable() {
        #expect(StatisticsTimeFilter.allTime == StatisticsTimeFilter.allTime)
        #expect(StatisticsTimeFilter.year(2026) == StatisticsTimeFilter.year(2026))
        #expect(StatisticsTimeFilter.year(2025) != StatisticsTimeFilter.year(2026))
        #expect(StatisticsTimeFilter.allTime != StatisticsTimeFilter.year(2026))
    }
}
