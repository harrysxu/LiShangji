//
//  NotificationService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import UserNotifications

/// 本地通知服务
class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    // MARK: - 通知标识符前缀
    private let birthdayPrefix = "birthday_"
    private let festivalPrefix = "festival_"
    private let eventPrefix = "event_"
    
    // MARK: - 权限管理
    
    /// 请求通知权限
    /// - Returns: 是否获得授权
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("请求通知权限失败: \(error)")
            return false
        }
    }
    
    /// 检查通知权限状态
    /// - Returns: 当前授权状态
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - 生日提醒
    
    /// 设置生日提醒（提前7天通知）
    /// - Parameters:
    ///   - contactName: 联系人姓名
    ///   - nextBirthday: 下一个生日的公历日期
    ///   - contactID: 联系人ID
    func scheduleBirthdayReminder(contactName: String, nextBirthday: Date, contactID: UUID) {
        // 计算提醒日期（提前7天）
        let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: nextBirthday)
        guard let reminderDate = reminderDate, reminderDate > Date() else {
            print("生日提醒日期无效或已过期")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "生日提醒"
        content.body = "\(contactName)的生日还有7天就到了（\(formatDate(nextBirthday))）"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "birthday",
            "contactID": contactID.uuidString,
            "contactName": contactName,
            "birthday": nextBirthday.timeIntervalSince1970
        ]
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let identifier = "\(birthdayPrefix)\(contactID.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("设置生日提醒失败: \(error)")
            } else {
                print("生日提醒设置成功: \(contactName) - \(reminderDate)")
            }
        }
    }
    
    // MARK: - 节日提醒
    
    /// 设置节日提醒
    /// - Parameters:
    ///   - festivalName: 节日名称
    ///   - date: 节日日期
    func scheduleFestivalReminder(festivalName: String, date: Date) {
        // 提前1天提醒
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: date)
        guard let reminderDate = reminderDate, reminderDate > Date() else {
            print("节日提醒日期无效或已过期")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "节日提醒"
        content.body = "明天是\(festivalName)，记得准备礼物哦！"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "festival",
            "festivalName": festivalName,
            "date": date.timeIntervalSince1970
        ]
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        // 设置提醒时间为上午9点
        var components = dateComponents
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "\(festivalPrefix)\(festivalName)_\(formatDate(date))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("设置节日提醒失败: \(error)")
            } else {
                print("节日提醒设置成功: \(festivalName) - \(reminderDate)")
            }
        }
    }
    
    // MARK: - 事件提醒
    
    /// 设置事件提醒
    /// - Parameter event: 事件提醒模型
    func scheduleEventReminder(event: EventReminder) {
        let option = event.reminder
        guard option != .none else { return }
        
        guard let reminderDate = option.reminderDate(for: event.eventDate),
              reminderDate > Date() else {
            print("事件提醒日期无效或已过期")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "事件提醒"
        content.body = "\(event.title) — \(formatDate(event.eventDate))"
        if !event.contactNames.isEmpty && event.contactNames != "未关联联系人" {
            content.body += "\n关联联系人: \(event.contactNames)"
        }
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "event",
            "eventID": event.id.uuidString,
            "eventTitle": event.title,
            "eventDate": event.eventDate.timeIntervalSince1970
        ]
        
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        // 全天事件默认上午 9 点提醒
        if event.isAllDay && option == .atTime {
            dateComponents.hour = 9
            dateComponents.minute = 0
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "\(eventPrefix)\(event.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("设置事件提醒失败: \(error)")
            } else {
                print("事件提醒设置成功: \(event.title) - \(reminderDate)")
            }
        }
    }
    
    /// 取消事件提醒
    /// - Parameter eventID: 事件ID
    func cancelEventReminder(eventID: UUID) {
        let identifier = "\(eventPrefix)\(eventID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    /// 重新调度事件提醒（编辑后调用）
    /// - Parameter event: 更新后的事件提醒模型
    func rescheduleEventReminder(event: EventReminder) {
        cancelEventReminder(eventID: event.id)
        if !event.isCompleted {
            scheduleEventReminder(event: event)
        }
    }
    
    // MARK: - 取消提醒
    
    /// 取消指定联系人的提醒
    /// - Parameter contactID: 联系人ID
    func cancelReminder(for contactID: UUID) {
        let identifier = "\(birthdayPrefix)\(contactID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    /// 取消所有提醒
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    /// 取消指定节日的提醒
    /// - Parameters:
    ///   - festivalName: 节日名称
    ///   - date: 节日日期
    func cancelFestivalReminder(festivalName: String, date: Date) {
        let identifier = "\(festivalPrefix)\(festivalName)_\(formatDate(date))"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    // MARK: - 辅助方法
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}
