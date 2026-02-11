//
//  SeedDataService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 预设数据服务 - 负责初始化内置事件模板和内置分类
struct SeedDataService {

    // MARK: - 内置分类数据源

    /// 内置分类定义（名称、图标、排序）
    static let builtInCategoryDefinitions: [(name: String, icon: String, order: Int)] = [
        ("婚礼", "heart.fill", 0),
        ("新生儿", "figure.and.child.holdinghands", 1),
        ("满月酒", "moon.fill", 2),
        ("周岁", "birthday.cake.fill", 3),
        ("生日", "gift.fill", 4),
        ("丧事", "leaf.fill", 5),
        ("乔迁", "house.fill", 6),
        ("升学", "graduationcap.fill", 7),
        ("升职", "star.fill", 8),
        ("春节", "fireworks", 9),
        ("中秋", "moon.haze.fill", 10),
        ("端午", "sailboat.fill", 11),
        ("其他", "ellipsis.circle.fill", 12),
    ]

    // MARK: - 初始化内置分类

    /// 初始化内置分类（基于 name 去重，支持 iCloud 多设备场景）
    static func seedBuiltInCategories(context: ModelContext) {
        do {
            // 获取已有分类
            let descriptor = FetchDescriptor<CategoryItem>()
            let existingItems = try context.fetch(descriptor)
            let existingNames = Set(existingItems.map { $0.name })

            var inserted = false
            for def in builtInCategoryDefinitions {
                guard !existingNames.contains(def.name) else { continue }
                let item = CategoryItem(
                    name: def.name,
                    icon: def.icon,
                    isBuiltIn: true,
                    sortOrder: def.order
                )
                context.insert(item)
                inserted = true
            }

            if inserted {
                try context.save()
            }
        } catch {
            print("初始化内置分类失败: \(error)")
        }
    }

    // MARK: - 初始化内置事件模板

    /// 初始化预设事件模板（仅首次启动时执行）
    static func seedBuiltInEvents(context: ModelContext) {
        // 检查是否已有内置事件
        let predicate = #Predicate<GiftEvent> { event in
            event.isBuiltIn == true
        }
        let descriptor = FetchDescriptor<GiftEvent>(predicate: predicate)

        do {
            let existingEvents = try context.fetch(descriptor)
            guard existingEvents.isEmpty else { return } // 已初始化，跳过
        } catch {
            // 查询失败，尝试插入
        }

        // 内置事件模板
        let builtInEvents: [(name: String, category: String, icon: String, order: Int)] = [
            ("婚礼", "婚礼", "heart.fill", 0),
            ("新生儿", "新生儿", "figure.and.child.holdinghands", 1),
            ("满月酒", "满月酒", "moon.fill", 2),
            ("周岁", "周岁", "birthday.cake.fill", 3),
            ("生日", "生日", "gift.fill", 4),
            ("丧事", "丧事", "leaf.fill", 5),
            ("乔迁", "乔迁", "house.fill", 6),
            ("升学", "升学", "graduationcap.fill", 7),
            ("升职", "升职", "star.fill", 8),
            ("春节", "春节", "fireworks", 9),
            ("中秋", "中秋", "moon.haze.fill", 10),
            ("端午", "端午", "sailboat.fill", 11),
            ("其他", "其他", "ellipsis.circle.fill", 12),
        ]

        for event in builtInEvents {
            let giftEvent = GiftEvent(
                name: event.name,
                category: event.category,
                icon: event.icon,
                isBuiltIn: true,
                sortOrder: event.order
            )
            context.insert(giftEvent)
        }

        try? context.save()
    }

    // MARK: - iCloud 同步去重

    /// 清理重复的分类（基于 name 去重，保留最早创建的）
    static func deduplicateCategories(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<CategoryItem>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
            let allItems = try context.fetch(descriptor)

            var seenNames: [String: CategoryItem] = [:]
            var toDelete: [CategoryItem] = []

            for item in allItems {
                if let existing = seenNames[item.name] {
                    // 保留最早的，删除后来的
                    // 如果后来的有更新的 updatedAt，合并可见性
                    if item.updatedAt > existing.updatedAt {
                        existing.isVisible = item.isVisible
                        existing.icon = item.icon
                        existing.sortOrder = item.sortOrder
                        existing.updatedAt = item.updatedAt
                    }
                    toDelete.append(item)
                } else {
                    seenNames[item.name] = item
                }
            }

            for item in toDelete {
                context.delete(item)
            }

            if !toDelete.isEmpty {
                try context.save()
            }
        } catch {
            print("分类去重失败: \(error)")
        }
    }
}
