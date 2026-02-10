//
//  LunarCalendarService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

/// 农历计算服务
class LunarCalendarService {
    static let shared = LunarCalendarService()
    private init() {}
    
    // MARK: - 农历数据表 (1900-2100)
    // 每个整数表示一年的农历数据，高4位表示闰月月份，低12位表示12个月的大小（1为大月30天，0为小月29天）
    private let lunarInfo: [Int] = [
        0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
        0x06566, 0x0d4a0, 0x0ea50, 0x16a95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
        0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
        0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
        0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
        0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
        0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
        0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0,
        0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
        0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
        0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
        0x05aa0, 0x076a3, 0x096d0, 0x04bd7, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
        0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
        0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
        0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
        0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
        0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
        0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252,
        0x0d520
    ]
    
    // MARK: - 天干地支生肖
    private let tianGan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private let diZhi = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private let shengXiao = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    
    // MARK: - 月份和日期中文
    private let monthNames = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    private let dayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    
    // MARK: - 重要节日
    private let festivals: [String: (month: Int, day: Int)] = [
        "春节": (1, 1),
        "元宵节": (1, 15),
        "端午节": (5, 5),
        "七夕节": (7, 7),
        "中秋节": (8, 15),
        "重阳节": (9, 9),
        "腊八节": (12, 8),
        "小年": (12, 23)
    ]
    
    // MARK: - 公历转农历
    
    /// 公历转农历
    /// - Parameter date: 公历日期
    /// - Returns: 农历年月日、是否闰月、月份名称、日期名称、干支年、生肖
    func solarToLunar(date: Date) -> (year: Int, month: Int, day: Int, isLeap: Bool, monthName: String, dayName: String, yearGanZhi: String, shengXiao: String) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let _ = components.month, let _ = components.day else {
            return (0, 0, 0, false, "", "", "", "")
        }
        
        var lunarYear = year
        var lunarMonth = 1
        var lunarDay = 1
        var isLeap = false
        
        // 计算1900年1月31日到指定日期的天数
        let baseDate = DateComponents(year: 1900, month: 1, day: 31)
        guard let base = calendar.date(from: baseDate) else {
            return (0, 0, 0, false, "", "", "", "")
        }
        
        let days = calendar.dateComponents([.day], from: base, to: date).day ?? 0
        
        // 计算农历年份
        var offset = days
        for y in 1900..<2100 {
            let yearDays = totalDaysInLunarYear(y)
            if offset < yearDays {
                lunarYear = y
                break
            }
            offset -= yearDays
        }
        
        // 计算农历月份和日期
        let leapMonth = getLeapMonth(lunarYear)
        var monthDays = 0
        
        for m in 1...12 {
            // 先处理普通月
            let daysInMonth = daysInLunarMonth(year: lunarYear, month: m)
            monthDays += daysInMonth
            
            if offset < monthDays {
                lunarMonth = m
                lunarDay = offset - (monthDays - daysInMonth) + 1
                break
            }
            
            // 如果这个月是闰月，需要处理闰月
            if leapMonth > 0 && m == leapMonth {
                let leapDays = daysInLunarMonth(year: lunarYear, month: leapMonth, isLeap: true)
                monthDays += leapDays
                if offset < monthDays {
                    lunarMonth = m
                    lunarDay = offset - (monthDays - leapDays) + 1
                    isLeap = true
                    break
                }
            }
        }
        
        let monthName = isLeap ? "闰\(monthNames[lunarMonth - 1])" : monthNames[lunarMonth - 1]
        let dayName = dayNames[lunarDay - 1]
        let ganZhi = getGanZhi(lunarYear)
        let shengXiaoName = shengXiao[(lunarYear - 1900) % 12]
        
        return (lunarYear, lunarMonth, lunarDay, isLeap, monthName, dayName, ganZhi, shengXiaoName)
    }
    
    /// 农历日期字符串
    /// - Parameter date: 公历日期
    /// - Returns: 农历日期字符串，如"腊月廿五"
    func lunarDateString(from date: Date) -> String {
        let lunar = solarToLunar(date: date)
        return "\(lunar.monthName)月\(lunar.dayName)"
    }
    
    // MARK: - 农历转公历
    
    /// 农历转公历
    /// - Parameters:
    ///   - lunarYear: 农历年
    ///   - lunarMonth: 农历月
    ///   - lunarDay: 农历日
    ///   - isLeap: 是否闰月
    /// - Returns: 公历日期
    func lunarToSolar(lunarYear: Int, lunarMonth: Int, lunarDay: Int, isLeap: Bool = false) -> Date? {
        guard lunarYear >= 1900 && lunarYear < 2100 else { return nil }
        guard lunarMonth >= 1 && lunarMonth <= 12 else { return nil }
        guard lunarDay >= 1 && lunarDay <= 30 else { return nil }
        
        let calendar = Calendar.current
        let baseDate = DateComponents(year: 1900, month: 1, day: 31)
        guard let base = calendar.date(from: baseDate) else { return nil }
        
        // 计算1900年到指定农历年的总天数
        var totalDays = 0
        for y in 1900..<lunarYear {
            totalDays += totalDaysInLunarYear(y)
        }
        
        // 计算到指定月份的天数
        let leapMonth = getLeapMonth(lunarYear)
        
        for m in 1..<lunarMonth {
            // 先加上普通月
            totalDays += daysInLunarMonth(year: lunarYear, month: m)
            
            // 如果这个月是闰月，需要加上闰月
            if leapMonth > 0 && m == leapMonth {
                totalDays += daysInLunarMonth(year: lunarYear, month: leapMonth, isLeap: true)
            }
        }
        
        // 如果目标月份是闰月，需要加上该月之前的普通月（如果存在）
        if isLeap && leapMonth == lunarMonth {
            // 闰月，需要先加上该月的普通月
            totalDays += daysInLunarMonth(year: lunarYear, month: lunarMonth)
        }
        
        // 加上日期（减1是因为日期从1开始）
        totalDays += lunarDay - 1
        
        return calendar.date(byAdding: .day, value: totalDays, to: base)
    }
    
    // MARK: - 下一个农历生日
    
    /// 获取下一个农历生日的公历日期
    /// - Parameters:
    ///   - lunarMonth: 农历月份
    ///   - lunarDay: 农历日期
    /// - Returns: 下一个农历生日对应的公历日期
    func nextLunarBirthday(lunarMonth: Int, lunarDay: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        
        // 尝试当前年和下一年
        for yearOffset in 0...1 {
            let year = currentYear + yearOffset
            guard year >= 1900 && year < 2100 else { continue }
            
            // 先尝试非闰月
            if let date = lunarToSolar(lunarYear: year, lunarMonth: lunarMonth, lunarDay: lunarDay, isLeap: false) {
                if date >= today {
                    return date
                }
            }
            
            // 如果该年有闰月，尝试闰月
            let leapMonth = getLeapMonth(year)
            if leapMonth == lunarMonth {
                if let date = lunarToSolar(lunarYear: year, lunarMonth: lunarMonth, lunarDay: lunarDay, isLeap: true) {
                    if date >= today {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - 节日判断
    
    /// 判断日期是否为重要节日
    /// - Parameter date: 公历日期
    /// - Returns: 节日名称，如果不是节日则返回nil
    func festivalName(for date: Date) -> String? {
        let lunar = solarToLunar(date: date)
        
        for (festivalName, festivalDate) in festivals {
            if lunar.month == festivalDate.month && lunar.day == festivalDate.day && !lunar.isLeap {
                return festivalName
            }
        }
        
        return nil
    }
    
    // MARK: - 指定月份的节日列表

    /// 获取指定公历年月内的所有农历节日
    /// - Parameters:
    ///   - year: 公历年
    ///   - month: 公历月
    /// - Returns: 该月内所有农历节日的名称、公历日期和农历日期字符串
    func festivalsInMonth(year: Int, month: Int) -> [(name: String, solarDate: Date, lunarDate: String)] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        var results: [(name: String, solarDate: Date, lunarDate: String)] = []
        for dayOffset in 0..<range.count {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }
            if let name = festivalName(for: date) {
                let lunarStr = lunarDateString(from: date)
                results.append((name: name, solarDate: date, lunarDate: lunarStr))
            }
        }
        return results
    }

    // MARK: - 辅助方法
    
    /// 获取农历年的总天数
    private func totalDaysInLunarYear(_ year: Int) -> Int {
        guard year >= 1900 && year < 1900 + lunarInfo.count else { return 0 }
        _ = year - 1900
        var total = 0
        
        for month in 1...12 {
            total += daysInLunarMonth(year: year, month: month)
        }
        
        let leapMonth = getLeapMonth(year)
        if leapMonth > 0 {
            total += daysInLunarMonth(year: year, month: leapMonth, isLeap: true)
        }
        
        return total
    }
    
    /// 获取农历月的天数
    private func daysInLunarMonth(year: Int, month: Int, isLeap: Bool = false) -> Int {
        guard year >= 1900 && year < 1900 + lunarInfo.count else { return 0 }
        guard month >= 1 && month <= 12 else { return 0 }
        
        let index = year - 1900
        let data = lunarInfo[index]
        
        // 低12位表示12个月的大小，bit 0 是第12个月，bit 11 是第1个月
        // 检查是否为闰月
        let leapMonth = getLeapMonth(year)
        if isLeap && leapMonth == month {
            // 闰月使用相同的位来判断大小
            let bit = 12 - month
            return (data & (1 << bit)) != 0 ? 30 : 29
        }
        
        // 普通月份：bit位置 = 12 - month
        let bit = 12 - month
        return (data & (1 << bit)) != 0 ? 30 : 29
    }
    
    /// 获取农历年的闰月月份（0表示无闰月）
    private func getLeapMonth(_ year: Int) -> Int {
        guard year >= 1900 && year < 1900 + lunarInfo.count else { return 0 }
        let index = year - 1900
        let data = lunarInfo[index]
        return (data >> 16) & 0x0F
    }
    
    /// 获取干支年
    private func getGanZhi(_ year: Int) -> String {
        // 1984年是甲子年
        let baseYear = 1984
        let offset = (year - baseYear) % 60
        let ganIndex = offset % 10
        let zhiIndex = offset % 12
        return "\(tianGan[ganIndex])\(diZhi[zhiIndex])"
    }
}
