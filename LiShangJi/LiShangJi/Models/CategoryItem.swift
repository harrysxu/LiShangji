//
//  CategoryItem.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/11.
//

import Foundation
import SwiftData

/// 事件分类模型 — 支持内置类型和自定义类型
@Model
final class CategoryItem {
    // MARK: - 基本属性
    var id: UUID = UUID()
    var name: String = ""               // 显示名称，也作为关联 key（如"婚礼"、"乔迁"）
    var icon: String = "tag.fill"       // SF Symbol 名称
    var isBuiltIn: Bool = false         // 内置类型不可删除
    var isVisible: Bool = true          // 内置类型可设置不可见
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(name: String, icon: String, isBuiltIn: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isBuiltIn = isBuiltIn
        self.isVisible = true
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 静态辅助方法

    /// 内置分类图标映射（用于不需要 ModelContext 的场景）
    private static let builtInIconMap: [String: String] = {
        var map: [String: String] = [:]
        for def in SeedDataService.builtInCategoryDefinitions {
            map[def.name] = def.icon
        }
        return map
    }()

    /// 根据分类名称获取图标（静态查找，优先从内置定义获取）
    static func iconForName(_ name: String) -> String {
        builtInIconMap[name] ?? "tag.fill"
    }

    /// 根据分类名称从给定列表中查找图标
    static func iconForName(_ name: String, in categories: [CategoryItem]) -> String {
        categories.first(where: { $0.name == name })?.icon ?? iconForName(name)
    }
}
