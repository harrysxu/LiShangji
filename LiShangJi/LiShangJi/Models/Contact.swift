//
//  Contact.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

@Model
final class Contact {
    // MARK: - 基本属性
    var id: UUID = UUID()
    var name: String = ""                           // 姓名
    var phone: String = ""                          // 电话号码
    var relation: String = "other"                  // 关系类型
    var group: String = ""                          // 分组（亲戚/同事/同学/朋友）
    var note: String = ""                           // 备注
    var avatarSystemName: String = "person.circle.fill" // SF Symbol 头像
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - 农历生日
    var lunarBirthday: String = ""                  // 农历生日字符串，格式: "腊月-廿五"
    var solarBirthday: Date = Date()                // 公历生日
    var hasBirthday: Bool = false                   // 是否设置了生日

    // MARK: - 系统通讯录关联
    var systemContactID: String = ""                // CNContact identifier

    // MARK: - 缓存聚合字段（性能优化，避免每次遍历 records）
    var cachedTotalReceived: Double = 0             // 缓存：总收到金额
    var cachedTotalSent: Double = 0                 // 缓存：总送出金额
    var cachedRecordCount: Int = 0                  // 缓存：记录总数

    // MARK: - 关系
    @Relationship(deleteRule: .nullify, inverse: \GiftRecord.contact)
    var records: [GiftRecord]? = []

    /// 关联的事件提醒
    @Relationship(deleteRule: .nullify)
    var eventReminders: [EventReminder]? = []

    init(name: String, relation: String = "other") {
        self.id = UUID()
        self.name = name
        self.relation = relation
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 计算属性

    /// 关系类型枚举
    var relationType: RelationType {
        RelationType(rawValue: relation) ?? .other
    }

    /// 总收到金额（读取缓存）
    var totalReceived: Double {
        cachedTotalReceived
    }

    /// 总送出金额（读取缓存）
    var totalSent: Double {
        cachedTotalSent
    }

    /// 人情差额（正数=对方欠我，负数=我欠对方）
    var balance: Double {
        cachedTotalReceived - cachedTotalSent
    }

    /// 往来记录总数（读取缓存）
    var recordCount: Int {
        cachedRecordCount
    }

    // MARK: - 缓存更新方法

    /// 重新计算并更新缓存的聚合字段
    func recalculateCachedAggregates() {
        let allRecords = records ?? []
        cachedTotalReceived = allRecords
            .filter { $0.direction == GiftDirection.received.rawValue }
            .reduce(0) { $0 + $1.amount }
        cachedTotalSent = allRecords
            .filter { $0.direction == GiftDirection.sent.rawValue }
            .reduce(0) { $0 + $1.amount }
        cachedRecordCount = allRecords.count
    }

    /// 增量更新：添加一条记录后更新缓存
    func updateCacheForAddedRecord(amount: Double, direction: String) {
        if direction == GiftDirection.received.rawValue {
            cachedTotalReceived += amount
        } else {
            cachedTotalSent += amount
        }
        cachedRecordCount += 1
    }

    /// 增量更新：删除一条记录后更新缓存
    func updateCacheForRemovedRecord(amount: Double, direction: String) {
        if direction == GiftDirection.received.rawValue {
            cachedTotalReceived = max(0, cachedTotalReceived - amount)
        } else {
            cachedTotalSent = max(0, cachedTotalSent - amount)
        }
        cachedRecordCount = max(0, cachedRecordCount - 1)
    }
}
