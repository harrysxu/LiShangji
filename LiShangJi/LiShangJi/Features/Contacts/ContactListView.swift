//
//  ContactListView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 联系人列表页
struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ContactViewModel()
    @State private var showingAddContact = false
    @Query(sort: \Contact.name) private var contacts: [Contact]

    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchBar

            // 分组筛选
            relationFilter

            // 列表
            if filteredContacts.isEmpty {
                Spacer()
                if contacts.isEmpty {
                    LSJEmptyStateView(
                        icon: "person.2",
                        title: "还没有联系人",
                        subtitle: "记录人情时会自动创建联系人",
                        actionTitle: "添加联系人"
                    ) {
                        showingAddContact = true
                    }
                } else {
                    LSJEmptyStateView(
                        icon: "magnifyingglass",
                        title: "没有找到相关联系人",
                        subtitle: "试试换个关键词搜索"
                    )
                }
                Spacer()
            } else {
                List {
                    ForEach(filteredContacts, id: \.id) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            contactRow(contact)
                        }
                        .listRowBackground(Color.theme.card)
                    }
                    .onDelete(perform: deleteContacts)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .refreshable {
                    // @Query 自动刷新，此处提供下拉手势反馈
                }
            }
        }
        .lsjPageBackground()
        .navigationTitle("联系人")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddContact = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(Color.theme.primary)
                }
                .debounced()
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddContactSheet()
        }
        .alert("出错了", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var filteredContacts: [Contact] {
        var result = contacts

        if let relation = viewModel.selectedRelation {
            result = result.filter { $0.relation == relation.rawValue }
        }

        if !viewModel.searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(viewModel.searchQuery) }
        }

        return result
    }

    // MARK: - 搜索栏

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.theme.textSecondary)
            TextField("搜索联系人", text: $viewModel.searchQuery)
        }
        .padding(AppConstants.Spacing.md)
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.top, AppConstants.Spacing.sm)
    }

    // MARK: - 关系筛选

    private var relationFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                LSJTag(text: "全部", isSelected: viewModel.selectedRelation == nil)
                    .onTapGesture {
                        HapticManager.shared.selection()
                        viewModel.selectedRelation = nil
                    }

                ForEach(RelationType.allCases, id: \.self) { relation in
                    LSJTag(
                        text: relation.displayName,
                        isSelected: viewModel.selectedRelation == relation
                    )
                    .onTapGesture {
                        HapticManager.shared.selection()
                        viewModel.selectedRelation = (viewModel.selectedRelation == relation) ? nil : relation
                    }
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.sm)
        }
    }

    // MARK: - 联系人行

    private func contactRow(_ contact: Contact) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: contact.avatarSystemName)
                .font(.title2)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 40, height: 40)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundStyle(Color.theme.textPrimary)
                    Text(contact.relationType.displayName)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.theme.textSecondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                Text("往来 \(contact.recordCount) 笔  差额: \(contact.balance.balanceString)")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - 删除

    private func deleteContacts(at offsets: IndexSet) {
        let filtered = filteredContacts
        for index in offsets {
            modelContext.delete(filtered[index])
        }
        try? modelContext.save()
    }
}

// MARK: - 添加/编辑联系人 Sheet

struct ContactFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var note = ""
    @State private var selectedRelation: RelationType = .friend
    @State private var hasBirthday = false
    @State private var solarBirthday = Date()

    var editingContact: Contact? = nil

    private var isEditing: Bool { editingContact != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("姓名", text: $name)
                    TextField("电话（选填）", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("备注（选填）", text: $note)
                }

                Section("关系类型") {
                    Picker("关系", selection: $selectedRelation) {
                        ForEach(RelationType.allCases, id: \.self) { relation in
                            Text(relation.displayName).tag(relation)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("生日") {
                    Toggle("设置生日提醒", isOn: $hasBirthday)
                        .tint(Color.theme.primary)
                    if hasBirthday {
                        DatePicker("公历生日", selection: $solarBirthday, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑联系人" : "添加联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveContact()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .debounced()
                }
            }
            .onAppear {
                if let contact = editingContact {
                    name = contact.name
                    phone = contact.phone
                    note = contact.note
                    selectedRelation = contact.relationType
                    hasBirthday = contact.hasBirthday
                    solarBirthday = contact.solarBirthday
                }
            }
        }
    }

    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let contact = editingContact {
            contact.name = trimmedName
            contact.phone = phone
            contact.note = note
            contact.relation = selectedRelation.rawValue
            contact.hasBirthday = hasBirthday
            contact.solarBirthday = solarBirthday
            contact.updatedAt = Date()
            try? modelContext.save()
        } else {
            let contact = Contact(name: trimmedName, relation: selectedRelation.rawValue)
            contact.phone = phone
            contact.note = note
            contact.hasBirthday = hasBirthday
            contact.solarBirthday = solarBirthday
            modelContext.insert(contact)
            try? modelContext.save()
        }

        HapticManager.shared.successNotification()
        dismiss()
    }
}

/// 保留旧名称的兼容别名
typealias AddContactSheet = ContactFormView
