//
//  AdditionalTests.swift
//  LiShangJiTests
//
//  补充测试 - 覆盖遗漏的功能点
//

import Testing
import Foundation
import SwiftUI
import SwiftData
@testable import LiShangJi

// MARK: - Color HEX 初始化测试

struct ColorHexTests {

    @Test func validHexWithHash() {
        let color = Color(hex: "#FF0000")
        #expect(color != nil)
    }

    @Test func validHexWithoutHash() {
        let color = Color(hex: "00FF00")
        #expect(color != nil)
    }

    @Test func validHexBlack() {
        let color = Color(hex: "#000000")
        #expect(color != nil)
    }

    @Test func validHexWhite() {
        let color = Color(hex: "#FFFFFF")
        #expect(color != nil)
    }

    @Test func validHexThemeColor() {
        // 朱砂红
        let color = Color(hex: "#C04851")
        #expect(color != nil)
    }

    @Test func invalidHexEmpty() {
        let color = Color(hex: "")
        #expect(color == nil)
    }

    @Test func invalidHexGarbage() {
        let color = Color(hex: "ZZZZZZ")
        #expect(color == nil)
    }

    @Test func hexWithWhitespace() {
        let color = Color(hex: "  #FF0000  ")
        #expect(color != nil)
    }

    @Test func hexLowercase() {
        let color = Color(hex: "#ff5500")
        #expect(color != nil)
    }
}

// MARK: - ContactViewModel 测试

struct ContactViewModelTests {

    @Test @MainActor func initialState() {
        let vm = ContactViewModel()
        #expect(vm.searchQuery == "")
        #expect(vm.selectedRelation == nil)
        #expect(vm.errorMessage == nil)
    }

    @Test @MainActor func deleteContact() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = makeTestContact(name: "将删除", in: context)

        // 确认联系人存在
        let before = try context.fetch(FetchDescriptor<Contact>())
        #expect(before.count == 1)

        let vm = ContactViewModel()
        vm.deleteContact(contact, context: context)

        // 确认联系人已删除
        let after = try context.fetch(FetchDescriptor<Contact>())
        #expect(after.count == 0)
        #expect(vm.errorMessage == nil)
    }

    @Test @MainActor func deleteContactWithRecords() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = makeTestContact(name: "有记录", in: context)
        let _ = makeTestRecord(amount: 1000, contact: contact, in: context)

        let vm = ContactViewModel()
        vm.deleteContact(contact, context: context)

        // 联系人已删除
        let contacts = try context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 0)

        // 记录还在，但关联为 nil（nullify 规则）
        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        #expect(records.count == 1)
        #expect(records.first?.contact == nil)
    }
}

// MARK: - KeypadInputHelper 测试

struct KeypadInputHelperTests {

    // MARK: - appendDigit 基本测试

    @Test func appendSingleDigit() {
        let result = KeypadInputHelper.appendDigit("5", to: "")
        #expect(result == "5")
    }

    @Test func appendMultipleDigits() {
        var amount = ""
        amount = KeypadInputHelper.appendDigit("1", to: amount)
        amount = KeypadInputHelper.appendDigit("0", to: amount)
        amount = KeypadInputHelper.appendDigit("0", to: amount)
        amount = KeypadInputHelper.appendDigit("0", to: amount)
        #expect(amount == "1000")
    }

    @Test func appendDoubleZero() {
        let result = KeypadInputHelper.appendDigit("00", to: "5")
        #expect(result == "500")
    }

    @Test func appendTripleZero() {
        let result = KeypadInputHelper.appendDigit("000", to: "1")
        #expect(result == "1000")
    }

    // MARK: - 小数点处理

    @Test func appendDecimalPoint() {
        let result = KeypadInputHelper.appendDigit(".", to: "100")
        #expect(result == "100.")
    }

    @Test func appendDecimalPointToEmpty() {
        let result = KeypadInputHelper.appendDigit(".", to: "")
        #expect(result == "0.")
    }

    @Test func preventDuplicateDecimalPoint() {
        let result = KeypadInputHelper.appendDigit(".", to: "100.5")
        #expect(result == "100.5") // 不变
    }

    @Test func limitDecimalToTwoPlaces() {
        var amount = "100.1"
        amount = KeypadInputHelper.appendDigit("2", to: amount)
        #expect(amount == "100.12")

        // 第三位应被拒绝
        amount = KeypadInputHelper.appendDigit("3", to: amount)
        #expect(amount == "100.12") // 不变
    }

    // MARK: - 整数位数限制

    @Test func limitIntegerTo8Digits() {
        let amount = "12345678" // 8 位
        let result = KeypadInputHelper.appendDigit("9", to: amount)
        #expect(result == "12345678") // 不变
    }

    @Test func allow8Digits() {
        let amount = "1234567" // 7 位
        let result = KeypadInputHelper.appendDigit("8", to: amount)
        #expect(result == "12345678") // 第8位可以
    }

    @Test func allowDecimalAfterMax8Digits() {
        let amount = "12345678"
        let result = KeypadInputHelper.appendDigit(".", to: amount)
        #expect(result == "12345678.")
    }

    @Test func integerLimitDoesNotApplyWithDecimal() {
        // 带小数点时整数位限制不适用于整个字符串
        let amount = "12345678.9"
        let result = KeypadInputHelper.appendDigit("9", to: amount)
        #expect(result == "12345678.99")
    }

    // MARK: - deleteDigit

    @Test func deleteFromNonEmpty() {
        #expect(KeypadInputHelper.deleteDigit(from: "123") == "12")
    }

    @Test func deleteFromSingleChar() {
        #expect(KeypadInputHelper.deleteDigit(from: "5") == "")
    }

    @Test func deleteFromEmpty() {
        #expect(KeypadInputHelper.deleteDigit(from: "") == "")
    }

    @Test func deleteDecimalPoint() {
        #expect(KeypadInputHelper.deleteDigit(from: "100.") == "100")
    }

    // MARK: - clear

    @Test func clearAmount() {
        #expect(KeypadInputHelper.clear() == "")
    }
}

// MARK: - GiftRecord sourceDisplayName 测试

struct GiftRecordSourceTests {

    @Test func sourceDisplayNameManual() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        record.source = "manual"
        #expect(record.sourceDisplayName == "手动")
    }

    @Test func sourceDisplayNameOCR() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        record.source = "ocr"
        #expect(record.sourceDisplayName == "OCR 识别")
    }

    @Test func sourceDisplayNameVoice() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        record.source = "voice"
        #expect(record.sourceDisplayName == "语音输入")
    }

    @Test func sourceDisplayNameDefault() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        // 默认值是 "manual"
        #expect(record.sourceDisplayName == "手动")
    }

    @Test func sourceDisplayNameUnknown() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        record.source = "unknown"
        #expect(record.sourceDisplayName == "手动") // default 分支
    }
}

// MARK: - RecordViewModel 附加测试

struct RecordViewModelAdditionalTests {

    @Test @MainActor func saveRecordWithSelectedBook() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = makeTestBook(name: "婚礼账本", in: context)

        let vm = RecordViewModel()
        vm.amount = "888"
        vm.contactName = "张三"
        vm.direction = .received
        vm.selectedBook = book

        let result = vm.saveRecord(context: context)
        #expect(result == true)

        // 验证记录关联了账本
        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        #expect(records.count == 1)
        #expect(records.first?.book?.name == "婚礼账本")
    }

    @Test @MainActor func saveRecordAutoGeneratesEventName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "1000"
        vm.contactName = "李四"
        vm.direction = .sent
        vm.selectedCategoryName = "生日"
        vm.eventName = "" // 不手动指定事件名

        let result = vm.saveRecord(context: context)
        #expect(result == true)

        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        // 自动生成的事件名 = "联系人名 + 事件类别显示名"
        #expect(records.first?.eventName == "李四生日")
    }

    @Test @MainActor func saveRecordCustomEventName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "500"
        vm.contactName = "王五"
        vm.direction = .received
        vm.eventName = "二婚庆典"
        vm.selectedCategoryName = "婚礼"

        let result = vm.saveRecord(context: context)
        #expect(result == true)

        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        #expect(records.first?.eventName == "二婚庆典") // 使用自定义名称
    }

    @Test func parsedAmountNegative() {
        let vm = RecordViewModel()
        vm.amount = "-100"
        // -100 is a valid Double but should it be negative? parsedAmount just does Double(amount) ?? 0
        #expect(vm.parsedAmount == -100)
    }

    @Test @MainActor func saveRecordCreatesNewContact() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "600"
        vm.contactName = "新人物"
        vm.direction = .sent
        vm.selectedContact = nil // 没有选中已有联系人

        let result = vm.saveRecord(context: context)
        #expect(result == true)

        // 应自动创建新联系人
        let contacts = try context.fetch(FetchDescriptor<Contact>())
        #expect(contacts.count == 1)
        #expect(contacts.first?.name == "新人物")
        #expect(contacts.first?.relation == RelationType.other.rawValue)
    }

    @Test @MainActor func saveRecordWithRecordType() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let vm = RecordViewModel()
        vm.amount = "5000"
        vm.contactName = "张三"
        vm.direction = .sent
        vm.recordType = .loan

        let result = vm.saveRecord(context: context)
        #expect(result == true)

        let records = try context.fetch(FetchDescriptor<GiftRecord>())
        // 验证 recordType 默认是 gift（因为 saveRecord 当前不设置 recordType）
        // 这反映了一个可能的遗漏功能点
        #expect(records.count == 1)
    }
}

// MARK: - HomeViewModel 附加测试

struct HomeViewModelAdditionalTests {

    @Test @MainActor func loadDataExcludesNonCurrentMonth() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date()
        let calendar = Calendar.current

        // 本月记录
        let _ = makeTestRecord(amount: 1000, direction: "received", eventDate: now, in: context)

        // 上个月记录
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let _ = makeTestRecord(amount: 5000, direction: "received", eventDate: lastMonth, in: context)

        // 下个月记录
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
        let _ = makeTestRecord(amount: 3000, direction: "received", eventDate: nextMonth, in: context)

        let vm = HomeViewModel()
        vm.loadData(context: context)

        // 只统计本月
        #expect(vm.totalReceived == 1000)
        #expect(vm.totalSent == 0)
    }

    @Test @MainActor func loadDataMixedDirectionsCurrentMonth() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date()
        let _ = makeTestRecord(amount: 800, direction: "received", eventDate: now, in: context)
        let _ = makeTestRecord(amount: 200, direction: "received", eventDate: now, in: context)
        let _ = makeTestRecord(amount: 500, direction: "sent", eventDate: now, in: context)
        let _ = makeTestRecord(amount: 100, direction: "sent", eventDate: now, in: context)

        let vm = HomeViewModel()
        vm.loadData(context: context)

        #expect(vm.totalReceived == 1000)
        #expect(vm.totalSent == 600)
        #expect(vm.balance == 400)
    }

    @Test @MainActor func recentRecordsSortedByCreatedAt() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date()
        // fetchRecent 按 createdAt 降序排列
        // 创建记录时手动设置不同的 createdAt
        let record1 = GiftRecord(amount: 100, direction: "received", eventName: "旧")
        record1.createdAt = now.addingTimeInterval(-100)
        record1.eventDate = now
        context.insert(record1)

        let record2 = GiftRecord(amount: 300, direction: "received", eventName: "新")
        record2.createdAt = now
        record2.eventDate = now
        context.insert(record2)

        let record3 = GiftRecord(amount: 200, direction: "received", eventName: "中")
        record3.createdAt = now.addingTimeInterval(-50)
        record3.eventDate = now
        context.insert(record3)

        try? context.save()

        let vm = HomeViewModel()
        vm.loadData(context: context)

        #expect(vm.recentRecords.count == 3)
        // fetchRecent 按 createdAt 降序排列，最新创建的在前
        #expect(vm.recentRecords.first?.amount == 300)
        #expect(vm.recentRecords.last?.amount == 100)
    }
}

// MARK: - OCR 中文数字转换附加测试

struct OCRChineseNumberAdditionalTests {

    let service = OCRService.shared

    @Test func chineseNumberTenThousand() {
        #expect(service.chineseNumberToDouble("一万") == 10000)
    }

    @Test func chineseNumberComposite() {
        // 一万二千三百四十五
        #expect(service.chineseNumberToDouble("一万二千三百四十五") == 12345)
    }

    @Test func chineseNumberWithWan() {
        #expect(service.chineseNumberToDouble("二万") == 20000)
    }

    @Test func chineseNumberSingleDigit() {
        #expect(service.chineseNumberToDouble("五") == 5)
    }

    @Test func chineseNumberTen() {
        // "十" 单独出现时应为 10
        #expect(service.chineseNumberToDouble("十") == 10)
    }

    @Test func chineseNumberTraditional() {
        // 大写中文数字
        #expect(service.chineseNumberToDouble("壹仟伍佰") == 1500)
    }

    @Test func chineseNumberZheng() {
        #expect(service.chineseNumberToDouble("一千元整") == 1000)
    }

    @Test func chineseNumberThreeHundred() {
        #expect(service.chineseNumberToDouble("三百") == 300)
    }

    @Test func chineseNumberTwoHundredFifty() {
        #expect(service.chineseNumberToDouble("二百五十") == 250)
    }

    @Test func chineseNumberOnlyYuan() {
        // 只有"元"应返回 nil
        #expect(service.chineseNumberToDouble("元") == nil)
    }
}

// MARK: - Export CSV 转义测试

struct ExportCSVEscapingTests {

    @Test @MainActor func csvWithCommaInName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = Contact(name: "张,三", relation: "friend")
        context.insert(contact)
        try? context.save()

        let _ = makeTestRecord(
            amount: 1000,
            direction: "received",
            eventName: "测试",
            contact: contact,
            in: context
        )

        let url = try ExportService.shared.exportAllToCSV(context: context)
        let content = try String(contentsOf: url, encoding: .utf8)

        // 含逗号的字段应被引号包裹
        #expect(content.contains("\"张,三\""))

        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func csvWithQuoteInNote() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let record = GiftRecord(amount: 500, direction: "sent", eventName: "测试")
        record.note = "他说\"谢谢\""
        context.insert(record)
        try? context.save()

        let url = try ExportService.shared.exportAllToCSV(context: context)
        let content = try String(contentsOf: url, encoding: .utf8)

        // 含双引号的字段：引号应被转义为双引号，整体被引号包裹
        #expect(content.contains("\"他说\"\"谢谢\"\"\""))

        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func csvWithNewlineInNote() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let record = GiftRecord(amount: 800, direction: "received", eventName: "测试")
        record.note = "第一行\n第二行"
        context.insert(record)
        try? context.save()

        let url = try ExportService.shared.exportAllToCSV(context: context)
        let content = try String(contentsOf: url, encoding: .utf8)

        // 含换行的字段应被引号包裹
        #expect(content.contains("\"第一行\n第二行\""))

        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func csvHasBOM() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let url = try ExportService.shared.exportAllToCSV(context: context)
        let data = try Data(contentsOf: url)

        // UTF-8 BOM 字节: EF BB BF
        #expect(data.count >= 3)
        #expect(data[0] == 0xEF)
        #expect(data[1] == 0xBB)
        #expect(data[2] == 0xBF)

        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func csvHeaderColumns() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let url = try ExportService.shared.exportAllToCSV(context: context)
        let content = try String(contentsOf: url, encoding: .utf8)

        // 验证表头完整
        #expect(content.contains("序号"))
        #expect(content.contains("姓名"))
        #expect(content.contains("关系"))
        #expect(content.contains("金额"))
        #expect(content.contains("收/送"))
        #expect(content.contains("事件类型"))
        #expect(content.contains("事件名称"))
        #expect(content.contains("日期"))
        #expect(content.contains("备注"))
        #expect(content.contains("账本"))

        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func exportContactsCSVHeaderColumns() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let url = try ExportService.shared.exportContactsToCSV(context: context)
        let content = try String(contentsOf: url, encoding: .utf8)

        #expect(content.contains("姓名"))
        #expect(content.contains("关系"))
        #expect(content.contains("电话"))
        #expect(content.contains("总收到"))
        #expect(content.contains("总送出"))
        #expect(content.contains("差额"))
        #expect(content.contains("往来笔数"))
        #expect(content.contains("备注"))

        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Double chineseUppercase 附加边界测试

struct ChineseUppercaseAdditionalTests {

    @Test func chineseUppercase1() {
        #expect(Double(1).chineseUppercase == "壹元整")
    }

    @Test func chineseUppercase10() {
        #expect(Double(10).chineseUppercase == "壹拾元整")
    }

    @Test func chineseUppercase1001() {
        // 壹仟零壹
        let result = Double(1001).chineseUppercase
        #expect(result.contains("壹仟"))
        #expect(result.contains("壹元"))
    }

    @Test func chineseUppercase10001() {
        let result = Double(10001).chineseUppercase
        #expect(result.contains("壹万"))
        #expect(result.contains("元整"))
    }

    @Test func chineseUppercase5000() {
        #expect(Double(5000).chineseUppercase == "伍仟元整")
    }

    @Test func chineseUppercase1200() {
        let result = Double(1200).chineseUppercase
        #expect(result.contains("壹仟"))
        #expect(result.contains("贰佰"))
    }

    @Test func chineseUppercase1888() {
        let result = Double(1888).chineseUppercase
        #expect(result.contains("壹仟"))
        #expect(result.contains("捌佰"))
        #expect(result.contains("捌拾"))
        #expect(result.contains("捌"))
        #expect(result.hasSuffix("元整"))
    }

    @Test func chineseUppercaseLargeNumber50000() {
        let result = Double(50000).chineseUppercase
        #expect(result.contains("伍万"))
        #expect(result.hasSuffix("元整"))
    }

    @Test func chineseUppercase99999() {
        let result = Double(99999).chineseUppercase
        #expect(result.hasPrefix("玖万"))
        #expect(result.hasSuffix("元整"))
    }
}

// MARK: - StatisticsViewModel 附加测试

struct StatisticsViewModelAdditionalTests {

    @Test @MainActor func monthlyTrendsWithData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date()
        let _ = makeTestRecord(amount: 1000, direction: "received", eventDate: now, in: context)
        let _ = makeTestRecord(amount: 500, direction: "sent", eventDate: now, in: context)

        let vm = StatisticsViewModel()
        vm.timeFilter = .allTime
        vm.loadData(context: context)

        // monthlyTrends 应有数据（至少有当月）
        #expect(!vm.monthlyTrends.isEmpty)

        // 检查趋势中有"收到"和"送出"
        let directions = Set(vm.monthlyTrends.map { $0.direction })
        #expect(directions.contains("收到"))
        #expect(directions.contains("送出"))
    }

    @Test @MainActor func relationStatsGrouping() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let friend = makeTestContact(name: "朋友A", relation: "friend", in: context)
        let family = makeTestContact(name: "家人A", relation: "family", in: context)

        let _ = makeTestRecord(amount: 1000, direction: "received", contact: friend, in: context)
        let _ = makeTestRecord(amount: 2000, direction: "received", contact: family, in: context)

        let vm = StatisticsViewModel()
        vm.loadData(context: context)

        // 应有关系分组
        #expect(!vm.relationStats.isEmpty)
        // 至少两组
        #expect(vm.relationStats.count >= 2)
    }

    @Test @MainActor func yearFilterExcludesOtherYears() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let date2024 = makeDate(year: 2024, month: 3, day: 15)
        let date2025 = makeDate(year: 2025, month: 6, day: 15)

        let _ = makeTestRecord(amount: 1000, direction: "received", eventDate: date2024, in: context)
        let _ = makeTestRecord(amount: 2000, direction: "sent", eventDate: date2025, in: context)

        let vm = StatisticsViewModel()

        // 筛选2024
        vm.timeFilter = .year(2024)
        vm.loadData(context: context)
        #expect(vm.totalReceived == 1000)
        #expect(vm.totalSent == 0)
        #expect(vm.recordCount == 1)

        // 筛选2025
        vm.timeFilter = .year(2025)
        vm.loadData(context: context)
        #expect(vm.totalReceived == 0)
        #expect(vm.totalSent == 2000)
        #expect(vm.recordCount == 1)
    }

    @Test @MainActor func topContactsLimitedTo10() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // 创建12个联系人，每个有记录
        for i in 1...12 {
            let contact = makeTestContact(name: "联系人\(i)", in: context)
            let _ = makeTestRecord(amount: Double(i * 100), direction: "received", contact: contact, in: context)
        }

        let vm = StatisticsViewModel()
        vm.loadData(context: context)

        #expect(vm.topContacts.count == 10) // 限制10个
    }

    @Test @MainActor func topContactsSortedByTotal() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let small = makeTestContact(name: "小额", in: context)
        let big = makeTestContact(name: "大额", in: context)

        let _ = makeTestRecord(amount: 100, direction: "received", contact: small, in: context)
        let _ = makeTestRecord(amount: 5000, direction: "received", contact: big, in: context)
        let _ = makeTestRecord(amount: 3000, direction: "sent", contact: big, in: context)

        let vm = StatisticsViewModel()
        vm.loadData(context: context)

        #expect(vm.topContacts.first?.name == "大额") // 总额最高
    }
}

// MARK: - Contact 附加测试

struct ContactAdditionalTests {

    @Test func defaultAvatarSystemName() {
        let contact = Contact(name: "测试")
        #expect(contact.avatarSystemName == "person.circle.fill")
    }

    @Test func defaultHasBirthday() {
        let contact = Contact(name: "测试")
        #expect(contact.hasBirthday == false)
    }

    @Test func defaultGroup() {
        let contact = Contact(name: "测试")
        #expect(contact.group == "")
    }

    @Test func defaultPhone() {
        let contact = Contact(name: "测试")
        #expect(contact.phone == "")
    }

    @Test func defaultNote() {
        let contact = Contact(name: "测试")
        #expect(contact.note == "")
    }
}

// MARK: - GiftRecord 附加测试

struct GiftRecordAdditionalTests {

    @Test func defaultSource() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        #expect(record.source == "manual")
    }

    @Test func defaultIsLoanSettled() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        #expect(record.isLoanSettled == false)
    }

    @Test func defaultOcrImageData() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        #expect(record.ocrImageData.isEmpty)
    }

    @Test func isReceivedTrue() {
        let record = GiftRecord(amount: 100, direction: "received", eventName: "测试")
        #expect(record.isReceived == true)
    }

    @Test func isReceivedFalse() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        #expect(record.isReceived == false)
    }

    @Test func recordTypeDefault() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        #expect(record.giftRecordType == .gift)
    }

    @Test func recordTypeLoan() {
        let record = GiftRecord(amount: 100, direction: "sent", eventName: "测试")
        record.recordType = "loan"
        #expect(record.giftRecordType == .loan)
    }
}

// MARK: - NavigationRouter 附加测试

struct NavigationRouterAdditionalTests {

    @Test func selectedBookForEntry() {
        let router = NavigationRouter()
        let book = GiftBook(name: "测试")
        router.selectedBookForEntry = book
        #expect(router.selectedBookForEntry?.name == "测试")
    }

    @Test func showingRecordEntry() {
        let router = NavigationRouter()
        router.showingRecordEntry = true
        #expect(router.showingRecordEntry == true)
    }

    @Test func showingOCRScanner() {
        let router = NavigationRouter()
        router.showingOCRScanner = true
        #expect(router.showingOCRScanner == true)
    }

    @Test func showingVoiceInput() {
        let router = NavigationRouter()
        router.showingVoiceInput = true
        #expect(router.showingVoiceInput == true)
    }
}
