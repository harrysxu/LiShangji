//
//  GiftRecordRepositoryProtocol.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 礼金记录数据访问协议
protocol GiftRecordRepositoryProtocol {
    func fetchAll(context: ModelContext) throws -> [GiftRecord]
    func fetchByBook(_ book: GiftBook, context: ModelContext) throws -> [GiftRecord]
    func fetchByContact(_ contact: Contact, context: ModelContext) throws -> [GiftRecord]
    func fetchRecent(limit: Int, context: ModelContext) throws -> [GiftRecord]
    /// 获取指定日期范围内的记录（半开区间 [from, to)）
    func fetchByDateRange(from: Date, to: Date, context: ModelContext) throws -> [GiftRecord]
    func create(amount: Double, direction: String, eventName: String, eventCategory: String, eventDate: Date, note: String, contactName: String, book: GiftBook?, contact: Contact?, context: ModelContext) throws -> GiftRecord
    func update(_ record: GiftRecord, context: ModelContext) throws
    func delete(_ record: GiftRecord, context: ModelContext) throws
    func totalSent(context: ModelContext) throws -> Double
    func totalReceived(context: ModelContext) throws -> Double
}
