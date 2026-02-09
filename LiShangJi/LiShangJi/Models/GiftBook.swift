//
//  GiftBook.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

@Model
final class GiftBook {
    // MARK: - 基本属性
    var id: UUID = UUID()
    var name: String = ""                         // 账本名称，如"我的婚礼"、"2026春节"
    var icon: String = "book.closed.fill"          // SF Symbol 名称
    var colorHex: String = "#C04851"               // 主题色 HEX
    var note: String = ""                          // 账本备注
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isArchived: Bool = false                   // 是否归档
    var sortOrder: Int = 0                         // 排序权重

    // MARK: - 缓存聚合字段（性能优化，避免每次遍历 records）
    var cachedTotalReceived: Double = 0             // 缓存：总收到金额
    var cachedTotalSent: Double = 0                 // 缓存：总送出金额
    var cachedRecordCount: Int = 0                  // 缓存：记录总数

    // MARK: - 关系
    @Relationship(deleteRule: .cascade, inverse: \GiftRecord.book)
    var records: [GiftRecord]? = []

    init(name: String, icon: String = "book.closed.fill", colorHex: String = "#C04851") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 计算属性

    /// 总收到金额（读取缓存）
    var totalReceived: Double {
        cachedTotalReceived
    }

    /// 总送出金额（读取缓存）
    var totalSent: Double {
        cachedTotalSent
    }

    /// 结余
    var balance: Double {
        cachedTotalReceived - cachedTotalSent
    }

    /// 记录总数（读取缓存）
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
