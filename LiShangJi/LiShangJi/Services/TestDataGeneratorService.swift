//
//  TestDataGeneratorService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

#if DEBUG

import Foundation
import SwiftData

// MARK: - 测试数据生成服务（仅 DEBUG 环境可用）

struct TestDataGeneratorService {

    // MARK: - 生成配置

    struct GenerationConfig {
        var monthsRange: Int = 12           // 时间范围（月数，最大24）
        var contactCount: Int = 30          // 联系人数量
        var bookCount: Int = 6              // 账本数量
        var recordsPerBook: Int = 30        // 每个账本的记录数
        var includeLoanRecords: Bool = true // 是否包含借贷记录
        var includeOCRRecords: Bool = true  // 是否包含 OCR 来源记录
        var includeVoiceRecords: Bool = true // 是否包含语音来源记录

        // 预设配置
        static let small = GenerationConfig(
            monthsRange: 12, contactCount: 10, bookCount: 3, recordsPerBook: 10
        )
        static let medium = GenerationConfig(
            monthsRange: 12, contactCount: 30, bookCount: 6, recordsPerBook: 30
        )
        static let large = GenerationConfig(
            monthsRange: 24, contactCount: 50, bookCount: 10, recordsPerBook: 60
        )
    }

    // MARK: - 生成结果

    struct GenerationResult {
        var contactsCreated: Int = 0
        var booksCreated: Int = 0
        var recordsCreated: Int = 0
        var eventsCreated: Int = 0
    }

    // MARK: - 姓名池

    private static let surnames = [
        "张", "王", "李", "赵", "刘", "陈", "杨", "黄", "周", "吴",
        "徐", "孙", "马", "朱", "胡", "郭", "何", "林", "罗", "高",
    ]

    private static let givenNames = [
        "伟", "芳", "娜", "敏", "静", "丽", "强", "磊", "洋", "艳",
        "勇", "军", "杰", "娟", "涛", "明", "超", "秀英", "华", "慧",
        "建华", "建国", "志强", "秀兰", "桂英", "玉兰", "淑珍", "海燕",
        "小红", "小明", "大伟", "国强", "晓峰", "雪梅", "丽华", "文静",
        "婷婷", "浩然", "子轩", "梓涵", "思远", "雨泽", "欣怡", "诗涵",
    ]

    // MARK: - 账本模板

    private static let bookTemplates: [(name: String, icon: String, colorHex: String)] = [
        ("我的婚礼", "heart.fill", "#C04851"),
        ("2025春节", "fireworks", "#D4380D"),
        ("2024春节", "fireworks", "#CF1322"),
        ("张三婚礼", "heart.fill", "#EB2F96"),
        ("宝宝满月酒", "moon.fill", "#FA8C16"),
        ("乔迁之喜", "house.fill", "#52C41A"),
        ("毕业升学宴", "graduationcap.fill", "#1890FF"),
        ("中秋往来", "moon.haze.fill", "#722ED1"),
        ("日常人情", "gift.fill", "#13C2C2"),
        ("公司同事", "briefcase.fill", "#2F54EB"),
        ("老家亲戚", "figure.and.child.holdinghands", "#EB2F96"),
        ("朋友往来", "person.2.fill", "#FA541C"),
    ]

    // MARK: - 常见金额（吉利数字）

    private static let commonAmounts: [Double] = [
        100, 200, 300, 500, 600, 666, 800, 888,
        1000, 1200, 1600, 1888, 2000, 2600, 2888,
        3000, 3600, 5000, 6600, 6666, 8000, 8800, 8888,
        10000, 16600, 18800, 28800, 66600,
    ]

    // MARK: - 备注模板

    private static let noteTemplates = [
        "", "", "", "", // 多数没有备注
        "祝新婚快乐", "百年好合", "恭喜恭喜",
        "祝宝宝健康成长", "恭喜乔迁之喜",
        "前程似锦", "心想事成", "万事如意",
        "节日快乐", "新年快乐", "中秋快乐",
        "感谢照顾", "多谢款待", "回礼",
    ]

    // MARK: - 生成测试数据

    @MainActor
    static func generate(config: GenerationConfig, context: ModelContext) -> GenerationResult {
        var result = GenerationResult()

        // 1. 生成联系人
        let contacts = generateContacts(count: config.contactCount, context: context)
        result.contactsCreated = contacts.count

        // 2. 生成账本
        let books = generateBooks(count: config.bookCount, context: context)
        result.booksCreated = books.count

        // 3. 生成礼金记录
        let recordCount = generateRecords(
            config: config,
            books: books,
            contacts: contacts,
            context: context
        )
        result.recordsCreated = recordCount

        // 4. 更新所有缓存聚合字段
        for contact in contacts {
            contact.recalculateCachedAggregates()
        }
        for book in books {
            book.recalculateCachedAggregates()
        }

        // 5. 保存
        try? context.save()

        return result
    }

    // MARK: - 生成联系人

    private static func generateContacts(count: Int, context: ModelContext) -> [Contact] {
        var contacts: [Contact] = []
        var usedNames: Set<String> = []

        for _ in 0..<count {
            // 生成不重复的姓名
            var name: String
            repeat {
                let surname = surnames.randomElement()!
                let givenName = givenNames.randomElement()!
                name = surname + givenName
            } while usedNames.contains(name)
            usedNames.insert(name)

            let relation = RelationType.allCases.randomElement()!
            let contact = Contact(name: name, relation: relation.rawValue)

            // 随机电话号码
            contact.phone = generatePhoneNumber()

            // 随机头像
            let avatars = [
                "person.circle.fill", "person.crop.circle.fill",
                "face.smiling.inverse", "figure.stand",
            ]
            contact.avatarSystemName = avatars.randomElement()!

            // 约 30% 的联系人有生日
            if Bool.random() && Bool.random() { // ~25%
                contact.hasBirthday = true
                let calendar = Calendar.current
                let year = Int.random(in: 1960...2005)
                let month = Int.random(in: 1...12)
                let day = Int.random(in: 1...28)
                if let birthday = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                    contact.solarBirthday = birthday
                }
                // 部分设置农历生日
                if Bool.random() {
                    let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月",
                                       "七月", "八月", "九月", "十月", "冬月", "腊月"]
                    let lunarDays = ["初一", "初五", "初十", "十五", "二十", "廿五", "三十"]
                    contact.lunarBirthday = "\(lunarMonths.randomElement()!)-\(lunarDays.randomElement()!)"
                }
            }

            // 随机备注
            if Bool.random() && Bool.random() {
                let notes = ["老朋友", "爸爸同事", "妈妈朋友", "大学室友", "高中同学", "隔壁邻居", "公司领导"]
                contact.note = notes.randomElement()!
            }

            context.insert(contact)
            contacts.append(contact)
        }

        return contacts
    }

    // MARK: - 生成账本

    private static func generateBooks(count: Int, context: ModelContext) -> [GiftBook] {
        var books: [GiftBook] = []
        let templates = Array(bookTemplates.shuffled().prefix(count))

        for (index, template) in templates.enumerated() {
            let book = GiftBook(name: template.name, icon: template.icon, colorHex: template.colorHex)
            book.sortOrder = index

            // 少数账本标记为归档
            if index >= count - 1 && count > 3 {
                book.isArchived = true
            }

            // 随机备注
            let bookNotes = ["", "", "", "记录往来", "今年的人情账", "重要"]
            book.note = bookNotes.randomElement()!

            context.insert(book)
            books.append(book)
        }

        return books
    }

    // MARK: - 生成记录

    private static func generateRecords(
        config: GenerationConfig,
        books: [GiftBook],
        contacts: [Contact],
        context: ModelContext
    ) -> Int {
        guard !books.isEmpty, !contacts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -config.monthsRange, to: now)!

        var totalRecords = 0

        for book in books {
            let recordCount = config.recordsPerBook + Int.random(in: -5...5) // 轻微随机波动
            let actualCount = max(1, recordCount)

            for _ in 0..<actualCount {
                let contact = contacts.randomElement()!
                let amount = commonAmounts.randomElement()!
                let direction: GiftDirection = Bool.random() ? .received : .sent
                let eventCategory = EventCategory.allCases.randomElement()!

                let record = GiftRecord(
                    amount: amount,
                    direction: direction.rawValue,
                    eventName: "\(contact.name)\(eventCategory.displayName)"
                )

                // 随机日期
                let timeInterval = now.timeIntervalSince(startDate)
                let randomInterval = TimeInterval.random(in: 0...timeInterval)
                record.eventDate = startDate.addingTimeInterval(randomInterval)
                record.createdAt = record.eventDate
                record.updatedAt = record.eventDate

                // 事件类别
                record.eventCategory = eventCategory.rawValue

                // 记录类型 - 大部分是 gift，少量是 loan
                if config.includeLoanRecords && Int.random(in: 0...9) == 0 { // ~10%
                    record.recordType = RecordType.loan.rawValue
                    record.isLoanSettled = Bool.random()
                    if !record.isLoanSettled {
                        record.loanDueDate = calendar.date(byAdding: .month, value: Int.random(in: 1...6), to: now)!
                    }
                } else {
                    record.recordType = RecordType.gift.rawValue
                }

                // 来源标记
                let sourceRoll = Int.random(in: 0...9)
                if config.includeOCRRecords && sourceRoll == 0 { // ~10%
                    record.source = "ocr"
                } else if config.includeVoiceRecords && sourceRoll == 1 { // ~10%
                    record.source = "voice"
                } else {
                    record.source = "manual"
                }

                // 备注
                record.note = noteTemplates.randomElement()!

                // 关联
                record.book = book
                record.contact = contact

                context.insert(record)
                totalRecords += 1
            }
        }

        return totalRecords
    }

    // MARK: - 清除所有数据

    @MainActor
    static func clearAllData(context: ModelContext) {
        do {
            try context.delete(model: GiftRecord.self)
            try context.delete(model: GiftBook.self)
            try context.delete(model: Contact.self)
            try context.delete(model: GiftEvent.self)
            try context.save()
        } catch {
            print("清除数据失败: \(error)")
        }

        // 重新初始化内置事件
        SeedDataService.seedBuiltInEvents(context: context)
    }

    // MARK: - 辅助方法

    private static func generatePhoneNumber() -> String {
        let prefixes = ["138", "139", "136", "137", "158", "159", "188", "189", "131", "132", "152", "186"]
        let prefix = prefixes.randomElement()!
        let suffix = String(format: "%08d", Int.random(in: 0...99999999))
        return prefix + suffix
    }
}

#endif
