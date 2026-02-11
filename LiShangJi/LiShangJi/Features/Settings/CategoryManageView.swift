//
//  CategoryManageView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/11.
//

import SwiftUI
import SwiftData

/// 分类管理视图 — 管理内置和自定义事件分类
struct CategoryManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CategoryItem.sortOrder) private var allCategories: [CategoryItem]

    @State private var showAddSheet = false
    @State private var editingCategory: CategoryItem?
    @State private var showDeleteConfirmation = false
    @State private var categoryToDelete: CategoryItem?

    private var builtInCategories: [CategoryItem] {
        allCategories.filter { $0.isBuiltIn }
    }

    private var customCategories: [CategoryItem] {
        allCategories.filter { !$0.isBuiltIn }
    }

    var body: some View {
        List {
            // MARK: - 内置类型
            Section {
                ForEach(builtInCategories, id: \.id) { category in
                    builtInRow(category)
                }
            } header: {
                Text("内置类型")
            } footer: {
                Text("内置类型不可删除和改名，可设置是否显示")
            }

            // MARK: - 自定义类型
            Section {
                ForEach(customCategories, id: \.id) { category in
                    customRow(category)
                }
                .onDelete(perform: deleteCustomCategories)
                .onMove(perform: moveCustomCategories)

                // 添加按钮
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.theme.primary)
                        Text("添加自定义类型")
                            .font(.body)
                            .foregroundStyle(Color.theme.primary)
                    }
                }
            } header: {
                Text("自定义类型")
            } footer: {
                Text("自定义类型可自由增删改，拖拽可调整排序")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("分类管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            CategoryEditSheet(mode: .add) { name, icon in
                addCategory(name: name, icon: icon)
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditSheet(
                mode: .edit(name: category.name, icon: category.icon)
            ) { name, icon in
                updateCategory(category, name: name, icon: icon)
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {
                categoryToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text("删除「\(category.name)」后，使用该分类的记录不会被删除，但分类显示可能受影响。")
            }
        }
    }

    // MARK: - 内置类型行

    private func builtInRow(_ category: CategoryItem) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: category.icon)
                .font(.body)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 28, height: 28)
                .background(Color.theme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(category.name)
                .font(.body)
                .foregroundStyle(category.isVisible ? Color.theme.textPrimary : Color.theme.textSecondary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { category.isVisible },
                set: { newValue in
                    category.isVisible = newValue
                    category.updatedAt = Date()
                    try? modelContext.save()
                }
            ))
            .tint(Color.theme.primary)
            .labelsHidden()
        }
    }

    // MARK: - 自定义类型行

    private func customRow(_ category: CategoryItem) -> some View {
        Button {
            editingCategory = category
        } label: {
            HStack(spacing: AppConstants.Spacing.md) {
                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundStyle(Color.theme.primary)
                    .frame(width: 28, height: 28)
                    .background(Color.theme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(category.name)
                    .font(.body)
                    .foregroundStyle(Color.theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
    }

    // MARK: - 操作方法

    private func addCategory(name: String, icon: String) {
        // 检查名称唯一性
        guard !allCategories.contains(where: { $0.name == name }) else { return }

        let maxOrder = allCategories.map(\.sortOrder).max() ?? 0
        let category = CategoryItem(
            name: name,
            icon: icon,
            isBuiltIn: false,
            sortOrder: maxOrder + 1
        )
        modelContext.insert(category)
        try? modelContext.save()
        HapticManager.shared.successNotification()
    }

    private func updateCategory(_ category: CategoryItem, name: String, icon: String) {
        // 检查名称唯一性（排除自身）
        guard !allCategories.contains(where: { $0.name == name && $0.id != category.id }) else { return }

        category.name = name
        category.icon = icon
        category.updatedAt = Date()
        try? modelContext.save()
        HapticManager.shared.successNotification()
    }

    private func deleteCategory(_ category: CategoryItem) {
        modelContext.delete(category)
        try? modelContext.save()
        categoryToDelete = nil
        HapticManager.shared.successNotification()
    }

    private func deleteCustomCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = customCategories[index]
            modelContext.delete(category)
        }
        try? modelContext.save()
    }

    private func moveCustomCategories(from source: IndexSet, to destination: Int) {
        var items = customCategories
        items.move(fromOffsets: source, toOffset: destination)

        // 更新排序：自定义类型排在内置类型之后
        let builtInMaxOrder = builtInCategories.map(\.sortOrder).max() ?? 0
        for (index, item) in items.enumerated() {
            item.sortOrder = builtInMaxOrder + 1 + index
            item.updatedAt = Date()
        }
        try? modelContext.save()
    }
}

// MARK: - 分类编辑 Sheet

enum CategoryEditMode: Identifiable {
    case add
    case edit(name: String, icon: String)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let name, _): return "edit_\(name)"
        }
    }
}

struct CategoryEditSheet: View {
    let mode: CategoryEditMode
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedIcon: String = "tag.fill"
    @State private var showDuplicateError = false

    /// 可选图标列表
    private let availableIcons: [(group: String, icons: [String])] = [
        ("常用", ["tag.fill", "heart.fill", "gift.fill", "star.fill", "moon.fill", "house.fill"]),
        ("人物", ["figure.and.child.holdinghands", "person.2.fill", "figure.stand", "person.crop.circle.fill"]),
        ("事件", ["birthday.cake.fill", "graduationcap.fill", "leaf.fill", "fireworks", "sailboat.fill"]),
        ("节日", ["moon.haze.fill", "sun.max.fill", "snowflake", "flame.fill", "sparkles"]),
        ("其他", ["ellipsis.circle.fill", "cup.and.saucer.fill", "book.fill", "briefcase.fill", "music.note"]),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("输入分类名称", text: $name)
                        .onChange(of: name) { _, _ in
                            showDuplicateError = false
                        }

                    if showDuplicateError {
                        Text("该名称已存在，请更换")
                            .font(.caption)
                            .foregroundStyle(Color.theme.sent)
                    }
                }

                Section("图标") {
                    ForEach(availableIcons, id: \.group) { group in
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                            Text(group.group)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(group.icons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                        HapticManager.shared.selection()
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .frame(width: 44, height: 44)
                                            .background(selectedIcon == icon ? Color.theme.primary : Color.theme.primary.opacity(0.1))
                                            .foregroundStyle(selectedIcon == icon ? .white : Color.theme.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                    }
                }

                // 预览
                Section("预览") {
                    HStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: selectedIcon)
                            .font(.body)
                            .foregroundStyle(Color.theme.primary)
                            .frame(width: 28, height: 28)
                            .background(Color.theme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(name.isEmpty ? "分类名称" : name)
                            .font(.body)
                            .foregroundStyle(name.isEmpty ? Color.theme.textSecondary : Color.theme.textPrimary)

                        Spacer()

                        LSJTag(
                            text: name.isEmpty ? "分类名称" : name,
                            color: Color.theme.primary,
                            isSelected: true,
                            icon: selectedIcon
                        )
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑分类" : "新增分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let editName, let editIcon) = mode {
                    name = editName
                    selectedIcon = editIcon
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        onSave(trimmedName, selectedIcon)
        dismiss()
    }
}
