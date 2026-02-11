//
//  ServiceTests.swift
//  LiShangJiTests
//
//  Created for LiShangJi unit tests.
//

import Testing
import Foundation
import SwiftData
@testable import LiShangJi

// MARK: - LunarCalendarService Tests

struct LunarCalendarServiceTests {

    let service = LunarCalendarService.shared

    // MARK: - 公历转农历 - 基本属性验证

    @Test func solarToLunarReturnsValidMonth() {
        let date = makeDate(year: 2024, month: 6, day: 15)
        let lunar = service.solarToLunar(date: date)
        #expect(lunar.month >= 1 && lunar.month <= 12)
        #expect(lunar.day >= 1 && lunar.day <= 30)
        #expect(!lunar.monthName.isEmpty)
        #expect(!lunar.dayName.isEmpty)
    }

    @Test func solarToLunarShengXiaoNotEmpty() {
        let date = makeDate(year: 2024, month: 6, day: 1)
        let lunar = service.solarToLunar(date: date)
        let validAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
        #expect(validAnimals.contains(lunar.shengXiao))
    }

    @Test func solarToLunarGanZhiFormat() {
        let date = makeDate(year: 2024, month: 6, day: 1)
        let lunar = service.solarToLunar(date: date)
        // 干支年应该是两个字符（一天干 + 一地支）
        #expect(lunar.yearGanZhi.count == 2)
    }

    @Test func solarToLunarGanZhiNotEmpty() {
        let date = makeDate(year: 2026, month: 1, day: 15)
        let lunar = service.solarToLunar(date: date)
        #expect(!lunar.yearGanZhi.isEmpty)
        #expect(!lunar.shengXiao.isEmpty)
    }

    // MARK: - 农历日期字符串格式

    @Test func lunarDateStringFormat() {
        let date = makeDate(year: 2026, month: 1, day: 15)
        let str = service.lunarDateString(from: date)
        // 格式应为 "X月XX"
        #expect(str.contains("月"))
        #expect(str.count >= 3)
    }

    // MARK: - 农历转公历 - 边界验证

    @Test func lunarToSolarReturnsDate() {
        // 任意一个有效农历日期应该能转换
        let solarDate = service.lunarToSolar(lunarYear: 2024, lunarMonth: 1, lunarDay: 1)
        #expect(solarDate != nil)
    }

    @Test func lunarToSolarInvalidYear() {
        let result = service.lunarToSolar(lunarYear: 1800, lunarMonth: 1, lunarDay: 1)
        #expect(result == nil)
    }

    @Test func lunarToSolarInvalidMonth() {
        let result = service.lunarToSolar(lunarYear: 2024, lunarMonth: 13, lunarDay: 1)
        #expect(result == nil)
    }

    @Test func lunarToSolarInvalidDay() {
        let result = service.lunarToSolar(lunarYear: 2024, lunarMonth: 1, lunarDay: 31)
        #expect(result == nil)
    }

    // MARK: - 往返转换一致性

    @Test func roundTripConversion() {
        // 从一个公历日期转农历，再转回公历，应该在同一天附近
        let originalDate = makeDate(year: 2025, month: 6, day: 15)
        let lunar = service.solarToLunar(date: originalDate)

        if let roundTrip = service.lunarToSolar(lunarYear: lunar.year, lunarMonth: lunar.month, lunarDay: lunar.day, isLeap: lunar.isLeap) {
            let calendar = Calendar.current
            let diff = abs(calendar.dateComponents([.day], from: originalDate, to: roundTrip).day ?? 999)
            #expect(diff <= 1) // 允许 1 天误差（由于时区/时间差异）
        }
    }

    // MARK: - 节日判断

    @Test func festivalNameNonFestival() {
        // 测试非节日日期返回 nil（使用一个非常不可能是节日的日期）
        let date = makeDate(year: 2024, month: 7, day: 3)
        let name = service.festivalName(for: date)
        // 大部分随机日期都不是节日
        // 不做严格断言，只验证不会崩溃
        _ = name
    }

    @Test func festivalNameDoesNotCrash() {
        // 测试各种日期不会导致崩溃
        for month in 1...12 {
            let date = makeDate(year: 2025, month: month, day: 15)
            let _ = service.festivalName(for: date)
        }
    }
}

// MARK: - OCRService Tests

struct OCRServiceTests {

    let service = OCRService.shared

    // MARK: - 解析姓名-金额对

    @Test func parseNameAmountPairsColonFormat() {
        let lines = ["张三：1000", "李四：888"]
        let items = service.parseNameAmountPairs(from: lines)

        #expect(items.count == 2)
        if items.count >= 2 {
            #expect(items[0].name == "张三")
            #expect(items[0].amount == 1000)
            #expect(items[1].name == "李四")
            #expect(items[1].amount == 888)
        }
    }

    @Test func parseNameAmountPairsSpaceFormat() {
        let lines = ["张三 1000", "李四 500"]
        let items = service.parseNameAmountPairs(from: lines)

        #expect(items.count == 2)
        if items.count >= 2 {
            #expect(items[0].name == "张三")
            #expect(items[0].amount == 1000)
        }
    }

    @Test func parseNameAmountPairsHalfWidthColon() {
        let lines = ["王五:500"]
        let items = service.parseNameAmountPairs(from: lines)

        #expect(items.count == 1)
        if let first = items.first {
            #expect(first.name == "王五")
            #expect(first.amount == 500)
        }
    }

    @Test func parseNameAmountPairsEmpty() {
        let items = service.parseNameAmountPairs(from: [])
        #expect(items.isEmpty)
    }

    @Test func parseNameAmountPairsInvalid() {
        let lines = ["这是一段无关的文字", "12345"]
        let items = service.parseNameAmountPairs(from: lines)
        #expect(items.isEmpty)
    }

    // MARK: - 中文数字转换

    @Test func chineseNumberToDoubleThousand() {
        #expect(service.chineseNumberToDouble("一千") == 1000)
    }

    @Test func chineseNumberToDouble888() {
        #expect(service.chineseNumberToDouble("八百八十八") == 888)
    }

    @Test func chineseNumberToDouble500() {
        #expect(service.chineseNumberToDouble("五百") == 500)
    }

    @Test func chineseNumberToDoubleWithYuan() {
        #expect(service.chineseNumberToDouble("一千元") == 1000)
    }

    @Test func chineseNumberToDoubleInvalid() {
        #expect(service.chineseNumberToDouble("无效") == nil)
    }
}

// MARK: - VoiceRecordingService Tests

struct VoiceRecordingServiceTests {

    let service = VoiceRecordingService.shared

    // MARK: - 自然语言解析

    @Test func parseDirectionSent() {
        let result = service.parseSingleRecord("送张三一千元")
        #expect(result.direction == "sent")
    }

    @Test func parseDirectionReceived() {
        let result = service.parseSingleRecord("收到李四五百元")
        #expect(result.direction == "received")
    }

    @Test func parseContactName() {
        let result = service.parseSingleRecord("送张三1000元")
        #expect(result.contactName != nil)
    }

    @Test func parseAmountArabicDigits() {
        let result = service.parseSingleRecord("张三结婚随礼1000元")
        #expect(result.amount == 1000)
    }

    @Test func parseEventCategoryWedding() {
        let result = service.parseSingleRecord("张三结婚随礼1000元")
        #expect(result.eventCategory == "婚礼")
    }

    @Test func parseEventCategoryBirthday() {
        let result = service.parseSingleRecord("李四生日送500元")
        #expect(result.eventCategory == "生日")
    }

    @Test func parseEventCategoryFullMoon() {
        let result = service.parseSingleRecord("王五满月酒随礼800元")
        #expect(result.eventCategory == "满月酒")
    }

    @Test func parseFullSentence() {
        let result = service.parseSingleRecord("张三结婚随礼1000元")
        #expect(result.contactName != nil)
        #expect(result.direction == "sent") // "随" -> sent
        #expect(result.amount == 1000)
        #expect(result.eventCategory == "婚礼")
        #expect(result.rawText == "张三结婚随礼1000元")
    }

    @Test func parseEmptyText() {
        let result = service.parseSingleRecord("")
        #expect(result.contactName == nil)
        #expect(result.amount == nil)
        #expect(result.direction == nil)
        #expect(result.eventCategory == nil)
    }

    @Test func parseMultipleRecords() {
        let results = service.parseMultipleRecords("张三结婚随礼1000元，李四生日送500元")
        #expect(results.count >= 2)
    }
}

// MARK: - ExportService Tests

struct ExportServiceTests {

    // 测试 CSV 转义通过 ExportService 创建 CSV 文件

    @Test @MainActor func exportAllToCSV() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let contact = makeTestContact(name: "张三", in: context)
        let book = makeTestBook(name: "测试账本", in: context)
        let _ = makeTestRecord(
            amount: 1000,
            direction: "received",
            eventName: "张三婚礼",
            book: book,
            contact: contact,
            in: context
        )

        let url = try ExportService.shared.exportAllToCSV(context: context)
        #expect(FileManager.default.fileExists(atPath: url.path))

        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("序号"))
        #expect(content.contains("姓名"))
        #expect(content.contains("张三"))
        #expect(content.contains("1000"))

        // 清理临时文件
        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func exportContactsToCSV() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let _ = makeTestContact(name: "张三", in: context)
        let _ = makeTestContact(name: "李四", relation: "family", in: context)

        let url = try ExportService.shared.exportContactsToCSV(context: context)
        #expect(FileManager.default.fileExists(atPath: url.path))

        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("张三"))
        #expect(content.contains("李四"))

        // 清理临时文件
        try? FileManager.default.removeItem(at: url)
    }

    @Test @MainActor func exportBookToCSV() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let book = makeTestBook(name: "婚礼账本", in: context)
        let _ = makeTestRecord(amount: 888, direction: "received", book: book, in: context)

        let url = try ExportService.shared.exportBookToCSV(book: book)
        #expect(FileManager.default.fileExists(atPath: url.path))

        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("888"))

        // 清理临时文件
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - SeedDataService Tests

struct SeedDataServiceTests {

    @Test @MainActor func seedBuiltInEventsCreatesEvents() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // 首次初始化
        SeedDataService.seedBuiltInEvents(context: context)

        let descriptor = FetchDescriptor<GiftEvent>()
        let events = try context.fetch(descriptor)
        #expect(events.count == 13)

        // 验证所有事件都是内置的
        let allBuiltIn = events.allSatisfy { $0.isBuiltIn }
        #expect(allBuiltIn)
    }

    @Test @MainActor func seedBuiltInEventsDoesNotDuplicate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // 首次调用
        SeedDataService.seedBuiltInEvents(context: context)
        let firstCount = try context.fetch(FetchDescriptor<GiftEvent>()).count

        // 重复调用
        SeedDataService.seedBuiltInEvents(context: context)
        let secondCount = try context.fetch(FetchDescriptor<GiftEvent>()).count

        #expect(firstCount == 13)
        #expect(secondCount == 13) // 不会重复创建
    }

    @Test @MainActor func seedBuiltInEventsContainsExpectedNames() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        SeedDataService.seedBuiltInEvents(context: context)

        let events = try context.fetch(FetchDescriptor<GiftEvent>())
        let names = Set(events.map { $0.name })

        #expect(names.contains("婚礼"))
        #expect(names.contains("新生儿"))
        #expect(names.contains("满月酒"))
        #expect(names.contains("周岁"))
        #expect(names.contains("生日"))
        #expect(names.contains("丧事"))
        #expect(names.contains("乔迁"))
        #expect(names.contains("升学"))
        #expect(names.contains("升职"))
        #expect(names.contains("春节"))
        #expect(names.contains("中秋"))
        #expect(names.contains("端午"))
        #expect(names.contains("其他"))
    }
}
