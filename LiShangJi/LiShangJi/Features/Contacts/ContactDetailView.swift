//
//  ContactDetailView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 联系人详情页 - 往来时间线 + 差额统计
struct ContactDetailView: View {
    let contact: Contact
    @State private var showingEditSheet = false

    private var sortedRecords: [GiftRecord] {
        (contact.records ?? []).sorted { $0.eventDate < $1.eventDate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 头部信息
                profileHeader

                // 收送统计
                balanceCards

                // 往来时间线
                timelineSection
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("编辑")
                        .foregroundStyle(Color.theme.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ContactFormView(editingContact: contact)
        }
    }

    // MARK: - 头部

    private var profileHeader: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: contact.avatarSystemName)
                .font(.system(size: 48))
                .foregroundStyle(Color.theme.primary)
                .frame(width: 80, height: 80)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(Circle())

            Text(contact.name)
                .font(.title2.bold())
                .foregroundStyle(Color.theme.textPrimary)

            HStack(spacing: AppConstants.Spacing.sm) {
                Text(contact.relationType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
                if !contact.phone.isEmpty {
                    Text("·")
                        .foregroundStyle(Color.theme.textSecondary)
                    Text(contact.phone)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }

            if contact.hasBirthday && !contact.lunarBirthday.isEmpty {
                Text("农历生日: \(contact.lunarBirthday)")
                    .font(.caption)
                    .foregroundStyle(Color.theme.info)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.lg)
    }

    // MARK: - 收送统计卡片

    private var balanceCards: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            statCard("收到", value: contact.totalReceived, color: Color.theme.received)
            statCard("送出", value: contact.totalSent, color: Color.theme.sent)
            statCard("差额", value: contact.balance, color: contact.balance >= 0 ? Color.theme.received : Color.theme.sent, showSign: true)
        }
    }

    private func statCard(_ label: String, value: Double, color: Color, showSign: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
            Text(showSign ? value.balanceString : value.currencyString)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.md)
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - 往来时间线

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("往来时间线")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            if sortedRecords.isEmpty {
                LSJEmptyStateView(
                    icon: "clock",
                    title: "暂无往来记录",
                    subtitle: "记录第一笔与\(contact.name)的人情往来"
                )
            } else {
                LSJCard {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedRecords.enumerated()), id: \.element.id) { index, record in
                            HStack(spacing: AppConstants.Spacing.md) {
                                // 时间线指示器
                                VStack(spacing: 0) {
                                    if index > 0 {
                                        Rectangle()
                                            .fill(Color.theme.divider)
                                            .frame(width: 1, height: 12)
                                    }
                                    Circle()
                                        .fill(record.isReceived ? Color.theme.received : Color.theme.sent)
                                        .frame(width: 10, height: 10)
                                    if index < sortedRecords.count - 1 {
                                        Rectangle()
                                            .fill(Color.theme.divider)
                                            .frame(width: 1, height: 12)
                                    }
                                }

                                // 内容
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.eventDate.chineseFullDate)
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.textSecondary)
                                    Text("\(record.giftDirection.displayName) · \(record.eventName)")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.theme.textPrimary)
                                }

                                Spacer()

                                Text(record.amount.currencyString)
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(record.isReceived ? Color.theme.received : Color.theme.sent)
                            }
                            .padding(.vertical, AppConstants.Spacing.xs)
                        }
                    }
                }
            }
        }
    }
}
