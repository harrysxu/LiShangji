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

    /// 总收到金额
    var totalReceived: Double {
        (records ?? [])
            .filter { $0.direction == GiftDirection.received.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    /// 总送出金额
    var totalSent: Double {
        (records ?? [])
            .filter { $0.direction == GiftDirection.sent.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    /// 结余
    var balance: Double {
        totalReceived - totalSent
    }

    /// 记录总数
    var recordCount: Int {
        (records ?? []).count
    }
}
