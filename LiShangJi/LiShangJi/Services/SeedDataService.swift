//
//  SeedDataService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 预设数据服务 - 负责初始化内置事件模板
struct SeedDataService {

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
            ("婚礼", EventCategory.wedding.rawValue, EventCategory.wedding.icon, 0),
            ("新生儿", EventCategory.babyBorn.rawValue, EventCategory.babyBorn.icon, 1),
            ("满月酒", EventCategory.fullMoon.rawValue, EventCategory.fullMoon.icon, 2),
            ("周岁", EventCategory.firstBirthday.rawValue, EventCategory.firstBirthday.icon, 3),
            ("生日", EventCategory.birthday.rawValue, EventCategory.birthday.icon, 4),
            ("丧事", EventCategory.funeral.rawValue, EventCategory.funeral.icon, 5),
            ("乔迁", EventCategory.housewarming.rawValue, EventCategory.housewarming.icon, 6),
            ("升学", EventCategory.graduation.rawValue, EventCategory.graduation.icon, 7),
            ("升职", EventCategory.promotion.rawValue, EventCategory.promotion.icon, 8),
            ("春节", EventCategory.springFestival.rawValue, EventCategory.springFestival.icon, 9),
            ("中秋", EventCategory.midAutumn.rawValue, EventCategory.midAutumn.icon, 10),
            ("端午", EventCategory.dragonBoat.rawValue, EventCategory.dragonBoat.icon, 11),
            ("其他", EventCategory.other.rawValue, EventCategory.other.icon, 12),
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
}
