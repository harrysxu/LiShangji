//
//  EventFormViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import Foundation
import SwiftData

/// 事件表单 ViewModel
@Observable
class EventFormViewModel {
    // MARK: - 表单状态
    var title: String = ""
    var note: String = ""
    var selectedCategory: EventCategory = .other
    var eventDate: Date = Date()
    var isAllDay: Bool = true
    var reminderOption: ReminderOption = .none
    var selectedContacts: [Contact] = []

    // MARK: - 编辑模式
    var isEditing: Bool = false
    private var editingEvent: EventReminder?

    // MARK: - 错误
    var errorMessage: String?

    private let repository = EventReminderRepository()

    // MARK: - 初始化（编辑模式）

    /// 配置为编辑模式
    func configure(with event: EventReminder) {
        isEditing = true
        editingEvent = event
        title = event.title
        note = event.note
        selectedCategory = event.category
        eventDate = event.eventDate
        isAllDay = event.isAllDay
        reminderOption = event.reminder
        selectedContacts = event.contacts ?? []
    }

    // MARK: - 验证

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 保存

    /// 保存事件（新建或更新）
    func save(context: ModelContext) -> Bool {
        guard isValid else {
            errorMessage = "请输入事件标题"
            return false
        }

        do {
            if isEditing, let event = editingEvent {
                // 更新现有事件
                event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                event.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
                event.eventCategory = selectedCategory.rawValue
                event.eventDate = eventDate
                event.isAllDay = isAllDay
                event.reminderOption = reminderOption.rawValue
                event.reminderDate = reminderOption.reminderDate(for: eventDate)
                event.contacts = selectedContacts
                try repository.update(event, context: context)

                // 重新调度通知
                NotificationService.shared.rescheduleEventReminder(event: event)
            } else {
                // 新建事件
                let event = try repository.create(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    eventCategory: selectedCategory.rawValue,
                    eventDate: eventDate,
                    context: context
                )
                event.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
                event.isAllDay = isAllDay
                event.reminderOption = reminderOption.rawValue
                event.reminderDate = reminderOption.reminderDate(for: eventDate)
                event.contacts = selectedContacts
                try repository.update(event, context: context)

                // 调度通知
                NotificationService.shared.scheduleEventReminder(event: event)
            }

            return true
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 联系人管理

    func addContact(_ contact: Contact) {
        guard !selectedContacts.contains(where: { $0.id == contact.id }) else { return }
        selectedContacts.append(contact)
    }

    func removeContact(_ contact: Contact) {
        selectedContacts.removeAll { $0.id == contact.id }
    }

    func isContactSelected(_ contact: Contact) -> Bool {
        selectedContacts.contains { $0.id == contact.id }
    }
}
