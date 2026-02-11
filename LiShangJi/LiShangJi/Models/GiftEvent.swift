//
//  GiftEvent.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

@Model
final class GiftEvent {
    // MARK: - 基本属性
    var id: UUID = UUID()
    var name: String = ""                           // 事件名称
    var category: String = "婚礼"                   // 事件类别（中文名）
    var icon: String = "heart.fill"                 // SF Symbol
    var isBuiltIn: Bool = false                     // 是否为系统内置事件
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(name: String, category: String, icon: String, isBuiltIn: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.icon = icon
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }

    /// 事件类别显示名称（即 category 本身，现在直接存储中文名）
    var categoryDisplayName: String {
        category
    }
}
