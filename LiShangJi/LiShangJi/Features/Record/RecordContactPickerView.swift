//
//  RecordContactPickerView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI
import SwiftData

/// 记录页面的联系人单选组件
struct RecordContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @State private var searchQuery = ""

    var onSelect: (Contact) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack(spacing: AppConstants.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.theme.textSecondary)
                    TextField("搜索联系人", text: $searchQuery)
                        .font(.body)
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.theme.textSecondary.opacity(0.6))
                        }
                    }
                }
                .padding(AppConstants.Spacing.md)
                .background(Color.theme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.top, AppConstants.Spacing.sm)

                if filteredContacts.isEmpty {
                    // 空状态
                    VStack(spacing: AppConstants.Spacing.md) {
                        Spacer()
                        Image(systemName: "person.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.4))
                        Text(searchQuery.isEmpty ? "暂无联系人" : "未找到匹配的联系人")
                            .font(.body)
                            .foregroundStyle(Color.theme.textSecondary)
                        Text("可在输入框中手动输入姓名")
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // 联系人列表
                    List {
                        ForEach(filteredContacts) { contact in
                            contactRow(contact)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .lsjPageBackground()
            .navigationTitle("选择联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    // MARK: - 联系人行

    private func contactRow(_ contact: Contact) -> some View {
        Button {
            HapticManager.shared.selection()
            onSelect(contact)
        } label: {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: contact.avatarSystemName)
                    .font(.title3)
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.theme.primary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.body)
                        .foregroundStyle(Color.theme.textPrimary)
                    HStack(spacing: AppConstants.Spacing.sm) {
                        Text(contact.relationType.displayName)
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                        if !contact.phone.isEmpty {
                            Text(contact.phone)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("差额: \(contact.balance.balanceString)")
                        .font(.caption)
                        .foregroundStyle(contact.balance >= 0 ? Color.theme.received : Color.theme.sent)
                    if contact.recordCount > 0 {
                        Text("\(contact.recordCount)条记录")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
            }
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 过滤

    private var filteredContacts: [Contact] {
        if searchQuery.isEmpty {
            return allContacts
        }
        return allContacts.filter { $0.name.localizedStandardContains(searchQuery) }
    }
}
