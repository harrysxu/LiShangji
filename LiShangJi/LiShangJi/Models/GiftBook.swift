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
    var cachedLoanIn: Double = 0                    // 缓存：借入金额
    var cachedLoanOut: Double = 0                   // 缓存：借出金额

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

    /// 借贷余额（正数=借出未收回，负数=借入未归还）
    var loanBalance: Double {
        cachedLoanOut - cachedLoanIn
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
            .filter { $0.direction == GiftDirection.received.rawValue && $0.giftRecordType != .loan }
            .reduce(0) { $0 + $1.giftStatsAmount }
        cachedTotalSent = allRecords
            .filter { $0.direction == GiftDirection.sent.rawValue && $0.giftRecordType != .loan }
            .reduce(0) { $0 + $1.giftStatsAmount }
        cachedLoanIn = allRecords
            .filter { $0.direction == GiftDirection.received.rawValue && $0.giftRecordType == .loan && !$0.isLoanSettled }
            .reduce(0) { $0 + $1.amount }
        cachedLoanOut = allRecords
            .filter { $0.direction == GiftDirection.sent.rawValue && $0.giftRecordType == .loan && !$0.isLoanSettled }
            .reduce(0) { $0 + $1.amount }
        cachedRecordCount = allRecords.count
    }

    /// 增量更新：添加一条记录后更新缓存
    func updateCacheForAddedRecord(amount: Double, direction: String, recordType: String = RecordType.gift.rawValue, includeInGiftStats: Bool = true) {
        let type = RecordType(rawValue: recordType) ?? .gift
        if type == .loan {
            if !includeInGiftStats {
                cachedRecordCount += 1
                return
            }
            if direction == GiftDirection.received.rawValue {
                cachedLoanIn += amount
            } else {
                cachedLoanOut += amount
            }
        } else if includeInGiftStats, direction == GiftDirection.received.rawValue {
            cachedTotalReceived += amount
        } else if includeInGiftStats {
            cachedTotalSent += amount
        }
        cachedRecordCount += 1
    }

    func updateCacheForAddedRecord(_ record: GiftRecord) {
        let amount = record.giftRecordType == .loan ? record.amount : record.giftStatsAmount
        updateCacheForAddedRecord(
            amount: amount,
            direction: record.direction,
            recordType: record.recordType,
            includeInGiftStats: record.includeInGiftStats && !record.isLoanSettled
        )
    }

    /// 增量更新：删除一条记录后更新缓存
    func updateCacheForRemovedRecord(amount: Double, direction: String, recordType: String = RecordType.gift.rawValue, includeInGiftStats: Bool = true) {
        let type = RecordType(rawValue: recordType) ?? .gift
        if type == .loan {
            if !includeInGiftStats {
                cachedRecordCount = max(0, cachedRecordCount - 1)
                return
            }
            if direction == GiftDirection.received.rawValue {
                cachedLoanIn = max(0, cachedLoanIn - amount)
            } else {
                cachedLoanOut = max(0, cachedLoanOut - amount)
            }
        } else if includeInGiftStats, direction == GiftDirection.received.rawValue {
            cachedTotalReceived = max(0, cachedTotalReceived - amount)
        } else if includeInGiftStats {
            cachedTotalSent = max(0, cachedTotalSent - amount)
        }
        cachedRecordCount = max(0, cachedRecordCount - 1)
    }

    func updateCacheForRemovedRecord(_ record: GiftRecord) {
        let amount = record.giftRecordType == .loan ? record.amount : record.giftStatsAmount
        updateCacheForRemovedRecord(
            amount: amount,
            direction: record.direction,
            recordType: record.recordType,
            includeInGiftStats: record.includeInGiftStats && !record.isLoanSettled
        )
    }

    /// 兼容旧调用：添加一条记录后更新缓存
    func updateCacheForAddedRecord(amount: Double, direction: String) {
        updateCacheForAddedRecord(amount: amount, direction: direction, recordType: RecordType.gift.rawValue)
    }

    /// 兼容旧调用：删除一条记录后更新缓存
    func updateCacheForRemovedRecord(amount: Double, direction: String) {
        updateCacheForRemovedRecord(amount: amount, direction: direction, recordType: RecordType.gift.rawValue)
    }
}
