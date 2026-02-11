//
//  EventViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import Foundation
import SwiftData

/// 事件筛选类型
enum EventFilterType: String, CaseIterable {
    case all = "全部"
    case upcoming = "即将到来"
    case overdue = "已过期"
    case completed = "已完成"
}

/// 事件列表 ViewModel
@Observable
class EventViewModel {
    var searchQuery: String = ""
    var selectedFilter: EventFilterType = .all
    var selectedCategoryName: String? = nil
    var errorMessage: String?

    private let repository = EventReminderRepository()

    /// 删除事件
    func deleteEvent(_ event: EventReminder, context: ModelContext) {
        do {
            NotificationService.shared.cancelEventReminder(eventID: event.id)
            try repository.delete(event, context: context)
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
    }

    /// 切换完成状态
    func toggleComplete(_ event: EventReminder, context: ModelContext) {
        do {
            try repository.toggleComplete(event, context: context)
            if event.isCompleted {
                NotificationService.shared.cancelEventReminder(eventID: event.id)
            } else {
                NotificationService.shared.rescheduleEventReminder(event: event)
            }
        } catch {
            errorMessage = "操作失败: \(error.localizedDescription)"
        }
    }

    /// 根据筛选条件过滤事件
    func filteredEvents(from events: [EventReminder]) -> [EventReminder] {
        var result = events

        // 搜索过滤
        if !searchQuery.isEmpty {
            result = result.filter { event in
                event.title.localizedStandardContains(searchQuery) ||
                event.contactNames.localizedStandardContains(searchQuery)
            }
        }

        // 类别过滤
        if let categoryName = selectedCategoryName {
            result = result.filter { $0.eventCategory == categoryName }
        }

        // 状态过滤
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            result = result.filter { !$0.isCompleted && $0.eventDate >= Date() }
        case .overdue:
            result = result.filter { $0.isOverdue }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        return result
    }

    /// 将事件按时间段分组
    func groupedEvents(from events: [EventReminder]) -> [(title: String, events: [EventReminder])] {
        let filtered = filteredEvents(from: events)
        var groups: [(title: String, events: [EventReminder])] = []

        let today = filtered.filter { $0.isToday && !$0.isCompleted }
        let upcoming = filtered.filter { !$0.isToday && !$0.isOverdue && !$0.isCompleted }
        let overdue = filtered.filter { $0.isOverdue }
        let completed = filtered.filter { $0.isCompleted }

        if !today.isEmpty {
            groups.append(("今天", today))
        }
        if !upcoming.isEmpty {
            groups.append(("即将到来", upcoming.sorted { $0.eventDate < $1.eventDate }))
        }
        if !overdue.isEmpty {
            groups.append(("已过期", overdue.sorted { $0.eventDate > $1.eventDate }))
        }
        if !completed.isEmpty {
            groups.append(("已完成", completed.sorted { $0.updatedAt > $1.updatedAt }))
        }

        return groups
    }
}
