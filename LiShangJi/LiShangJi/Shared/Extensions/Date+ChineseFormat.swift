//
//  Date+ChineseFormat.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

/// 中文日期格式化扩展
/// 确保日期始终以中文格式展示，不受系统语言设置影响
extension Date {

    private static let chineseLocale = Locale(identifier: "zh_CN")

    /// 完整中文日期，如 "2026年2月6日"
    var chineseFullDate: String {
        formatted(.dateTime.year().month().day().locale(Self.chineseLocale))
    }

    /// 中文月日，如 "2月6日"
    var chineseMonthDay: String {
        formatted(.dateTime.month().day().locale(Self.chineseLocale))
    }

    /// 中文数字日期，如 "2026/2/6"
    var chineseNumericDate: String {
        formatted(.dateTime.year().month(.defaultDigits).day().locale(Self.chineseLocale))
    }
}
