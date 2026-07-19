//
//  ContactDetailView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 联系人详情页 - 往来时间线 + 差额统计
struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @State private var showingEditSheet = false
    @State private var showPurchase = false
    @State private var showingMerge = false

    private var sortedRecords: [GiftRecord] {
        (contact.records ?? []).sorted { $0.eventDate > $1.eventDate }
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
                Menu {
                    Button("编辑", systemImage: "pencil") { showingEditSheet = true }
                    Button("合并联系人", systemImage: "person.2.badge.gearshape") { showingMerge = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("联系人更多操作")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ContactFormView(editingContact: contact)
        }
        .sheet(isPresented: $showPurchase) { PurchaseView() }
        .sheet(isPresented: $showingMerge) { MergeContactView(target: contact) }
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
            if let aliases = contact.aliases, !aliases.isEmpty {
                Text("曾用名：\(aliases.map(\.name).joined(separator: "、"))")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
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

                                if record.isReceived && record.reciprocityStatusCode != "returned" {
                                    Button {
                                        guard PremiumManager.shared.entitlementPolicy.allows(.returnGiftAssistant) else { showPurchase = true; return }
                                        if record.reciprocityStatusCode == "toReturn" {
                                            router.selectedRecordForReturn = record
                                            router.selectedBookForEntry = record.book
                                            router.showingRecordEntry = true
                                        } else {
                                            try? RecordCommandService().setReciprocityStatus("toReturn", for: record, context: modelContext)
                                        }
                                    } label: {
                                        Image(systemName: record.reciprocityStatusCode == "toReturn" ? "arrow.uturn.forward.circle.fill" : "arrow.uturn.forward.circle")
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(record.reciprocityStatusCode == "toReturn" ? "按此记录回礼" : "加入待回礼")
                                }
                            }
                            .padding(.vertical, AppConstants.Spacing.xs)
                        }
                    }
                }
            }
        }
    }
}

private struct MergeContactView: View {
    let target: Contact
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Contact> { $0.mergedIntoContactID == nil }, sort: \Contact.name) private var contacts: [Contact]
    @State private var selected: Contact?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List(contacts.filter { $0.id != target.id }) { contact in
                Button {
                    selected = contact
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(contact.name)
                            Text("\(contact.recordCount) 条往来").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selected?.id == contact.id { Image(systemName: "checkmark").foregroundStyle(Color.theme.primary) }
                    }
                }
            }
            .navigationTitle("合并到 \(target.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("合并") {
                        guard let selected else { return }
                        do { try ContactCommandService().merge(selected, into: target, context: modelContext); dismiss() }
                        catch { errorMessage = error.localizedDescription }
                    }.disabled(selected == nil)
                }
            }
            .alert("合并没有完成", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("确定") {} } message: { Text(errorMessage ?? "") }
        }
    }
}
