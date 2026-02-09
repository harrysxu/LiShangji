//
//  EventReminderRepositoryProtocol.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import Foundation
import SwiftData

/// 事件提醒数据访问协议
protocol EventReminderRepositoryProtocol {
    func fetchAll(context: ModelContext) throws -> [EventReminder]
    func fetchUpcoming(context: ModelContext) throws -> [EventReminder]
    func fetchOverdue(context: ModelContext) throws -> [EventReminder]
    func fetchByCategory(_ category: String, context: ModelContext) throws -> [EventReminder]
    func fetchByContact(_ contact: Contact, context: ModelContext) throws -> [EventReminder]
    func search(query: String, context: ModelContext) throws -> [EventReminder]
    @discardableResult
    func create(title: String, eventCategory: String, eventDate: Date, context: ModelContext) throws -> EventReminder
    func update(_ event: EventReminder, context: ModelContext) throws
    func delete(_ event: EventReminder, context: ModelContext) throws
    func toggleComplete(_ event: EventReminder, context: ModelContext) throws
}
