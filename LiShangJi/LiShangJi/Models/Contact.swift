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

    // MARK: - 关系
    @Relationship(deleteRule: .nullify, inverse: \GiftRecord.contact)
    var records: [GiftRecord]? = []

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

    /// 人情差额（正数=对方欠我，负数=我欠对方）
    var balance: Double {
        totalReceived - totalSent
    }

    /// 往来记录总数
    var recordCount: Int {
        (records ?? []).count
    }
}
