//
//  EventReminder.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import Foundation
import SwiftData

/// 事件提醒模型 — 用户创建的具体事件实例（区别于 GiftEvent 事件模板）
@Model
final class EventReminder {
    // MARK: - 基本属性
    var id: UUID = UUID()
    var title: String = ""                          // 事件标题
    var note: String = ""                           // 备注
    var eventCategory: String = "other"             // 事件类别 (复用 EventCategory)
    var eventDate: Date = Date()                    // 事件日期
    var reminderOption: String = "none"             // 提醒选项 (ReminderOption rawValue)
    var reminderDate: Date?                         // 计算后的提醒时间
    var isCompleted: Bool = false                   // 是否已完成
    var isAllDay: Bool = true                       // 是否全天事件
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - 关联联系人
    @Relationship(deleteRule: .nullify, inverse: \Contact.eventReminders)
    var contacts: [Contact]? = []

    init(title: String, eventCategory: String = "other", eventDate: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.eventCategory = eventCategory
        self.eventDate = eventDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 计算属性

    /// 事件类别枚举
    var category: EventCategory {
        EventCategory(rawValue: eventCategory) ?? .other
    }

    /// 提醒选项枚举
    var reminder: ReminderOption {
        ReminderOption(rawValue: reminderOption) ?? .none
    }

    /// 是否已过期
    var isOverdue: Bool {
        !isCompleted && eventDate < Date()
    }

    /// 是否即将到来（7天内）
    var isUpcoming: Bool {
        guard !isCompleted, !isOverdue else { return false }
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
        return daysUntil >= 0 && daysUntil <= 7
    }

    /// 是否是今天的事件
    var isToday: Bool {
        Calendar.current.isDateInToday(eventDate)
    }

    /// 关联联系人名称列表
    var contactNames: String {
        let names = (contacts ?? []).map { $0.name }
        return names.isEmpty ? "未关联联系人" : names.joined(separator: "、")
    }

    /// 距离事件还有几天（正数=未来，负数=已过）
    var daysUntilEvent: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: eventDate)).day ?? 0
    }
}
