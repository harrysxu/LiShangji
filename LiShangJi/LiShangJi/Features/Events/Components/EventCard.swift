//
//  EventCard.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI

/// 事件列表卡片组件
struct EventCard: View {
    let event: EventReminder
    var onToggleComplete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // 完成状态按钮
            Button {
                HapticManager.shared.lightImpact()
                onToggleComplete?()
            } label: {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(event.isCompleted ? Color.theme.received : Color.theme.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // 事件类别图标
            Image(systemName: event.category.icon)
                .font(.body)
                .foregroundStyle(categoryColor)
                .frame(width: 32, height: 32)
                .background(categoryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // 事件信息
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(event.isCompleted ? Color.theme.textSecondary : Color.theme.textPrimary)
                    .strikethrough(event.isCompleted)
                    .lineLimit(1)

                HStack(spacing: AppConstants.Spacing.sm) {
                    // 日期
                    Label(formattedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(dateColor)

                    // 关联联系人数量
                    if let contacts = event.contacts, !contacts.isEmpty {
                        Label("\(contacts.count)人", systemImage: "person.2")
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
            }

            Spacer()

            // 状态标签
            if !event.isCompleted {
                statusBadge
            }
        }
        .padding(AppConstants.Spacing.md)
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
    }

    // MARK: - 状态标签

    @ViewBuilder
    private var statusBadge: some View {
        if event.isToday {
            Text("今天")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.theme.primary.opacity(0.15))
                .foregroundStyle(Color.theme.primary)
                .clipShape(Capsule())
        } else if event.isOverdue {
            Text("已过期")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.theme.sent.opacity(0.15))
                .foregroundStyle(Color.theme.sent)
                .clipShape(Capsule())
        } else if event.isUpcoming {
            Text("\(event.daysUntilEvent)天后")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.theme.warning.opacity(0.15))
                .foregroundStyle(Color.theme.warning)
                .clipShape(Capsule())
        }
    }

    // MARK: - 辅助

    private var categoryColor: Color {
        switch event.category {
        case .wedding: return Color.theme.primary
        case .birthday, .firstBirthday: return Color.theme.warning
        case .springFestival, .midAutumn, .dragonBoat: return .orange
        case .funeral: return Color.theme.textSecondary
        default: return Color.theme.info
        }
    }

    private var dateColor: Color {
        if event.isOverdue {
            return Color.theme.sent
        } else if event.isToday {
            return Color.theme.primary
        }
        return Color.theme.textSecondary
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        if event.isAllDay {
            formatter.dateFormat = "M月d日"
        } else {
            formatter.dateFormat = "M月d日 HH:mm"
        }
        return formatter.string(from: event.eventDate)
    }
}
