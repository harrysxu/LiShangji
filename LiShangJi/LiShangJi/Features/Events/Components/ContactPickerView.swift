//
//  ContactPickerView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI
import SwiftData

/// 联系人多选组件
struct ContactPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @Binding var selectedContacts: [Contact]
    @State private var searchQuery = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack(spacing: AppConstants.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.theme.textSecondary)
                    TextField("搜索联系人", text: $searchQuery)
                        .font(.body)
                }
                .padding(AppConstants.Spacing.md)
                .background(Color.theme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.top, AppConstants.Spacing.sm)

                // 已选联系人标签
                if !selectedContacts.isEmpty {
                    selectedContactsTags
                }

                // 联系人列表
                List {
                    ForEach(filteredContacts) { contact in
                        contactRow(contact)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .lsjPageBackground()
            .navigationTitle("选择联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - 已选联系人标签

    private var selectedContactsTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                ForEach(selectedContacts) { contact in
                    HStack(spacing: 4) {
                        Text(contact.name)
                            .font(.caption)
                            .foregroundStyle(Color.theme.primary)
                        Button {
                            removeContact(contact)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.theme.primary.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.theme.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.sm)
        }
    }

    // MARK: - 联系人行

    private func contactRow(_ contact: Contact) -> some View {
        Button {
            toggleContact(contact)
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
                    if !contact.phone.isEmpty {
                        Text(contact.phone)
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }

                Spacer()

                if isSelected(contact) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.theme.primary)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(Color.theme.textSecondary.opacity(0.3))
                }
            }
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 辅助方法

    private var filteredContacts: [Contact] {
        if searchQuery.isEmpty {
            return allContacts
        }
        return allContacts.filter { $0.name.localizedStandardContains(searchQuery) }
    }

    private func isSelected(_ contact: Contact) -> Bool {
        selectedContacts.contains { $0.id == contact.id }
    }

    private func toggleContact(_ contact: Contact) {
        HapticManager.shared.selection()
        if isSelected(contact) {
            removeContact(contact)
        } else {
            selectedContacts.append(contact)
        }
    }

    private func removeContact(_ contact: Contact) {
        selectedContacts.removeAll { $0.id == contact.id }
    }
}
