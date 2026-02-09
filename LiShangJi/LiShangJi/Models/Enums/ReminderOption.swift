//
//  ReminderOption.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import Foundation

/// 提醒时间选项
enum ReminderOption: String, CaseIterable, Codable {
    case none = "none"                     // 不提醒
    case atTime = "at_time"                // 事件发生时
    case fiveMinutes = "five_minutes"      // 提前 5 分钟
    case fifteenMinutes = "fifteen_minutes" // 提前 15 分钟
    case thirtyMinutes = "thirty_minutes"  // 提前 30 分钟
    case oneHour = "one_hour"              // 提前 1 小时
    case twoHours = "two_hours"            // 提前 2 小时
    case oneDay = "one_day"                // 提前 1 天
    case twoDays = "two_days"              // 提前 2 天
    case oneWeek = "one_week"              // 提前 1 周

    var displayName: String {
        switch self {
        case .none: return "不提醒"
        case .atTime: return "事件发生时"
        case .fiveMinutes: return "提前 5 分钟"
        case .fifteenMinutes: return "提前 15 分钟"
        case .thirtyMinutes: return "提前 30 分钟"
        case .oneHour: return "提前 1 小时"
        case .twoHours: return "提前 2 小时"
        case .oneDay: return "提前 1 天"
        case .twoDays: return "提前 2 天"
        case .oneWeek: return "提前 1 周"
        }
    }

    /// 相对于事件时间的偏移量（秒），负数表示提前
    var timeOffset: TimeInterval {
        switch self {
        case .none: return 0
        case .atTime: return 0
        case .fiveMinutes: return -5 * 60
        case .fifteenMinutes: return -15 * 60
        case .thirtyMinutes: return -30 * 60
        case .oneHour: return -60 * 60
        case .twoHours: return -2 * 60 * 60
        case .oneDay: return -24 * 60 * 60
        case .twoDays: return -2 * 24 * 60 * 60
        case .oneWeek: return -7 * 24 * 60 * 60
        }
    }

    /// 计算提醒日期
    /// - Parameter eventDate: 事件日期
    /// - Returns: 提醒日期，如果是 .none 则返回 nil
    func reminderDate(for eventDate: Date) -> Date? {
        guard self != .none else { return nil }
        return eventDate.addingTimeInterval(timeOffset)
    }
}
