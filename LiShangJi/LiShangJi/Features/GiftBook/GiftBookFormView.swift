//
//  GiftBookFormView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 创建/编辑账本 Sheet
struct GiftBookFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "book.closed.fill"
    @State private var selectedColor = "#C04851"
    @State private var showToast = false

    var editingBook: GiftBook? = nil

    private let iconOptions = [
        "book.closed.fill", "book.fill", "heart.fill", "gift.fill",
        "house.fill", "star.fill", "moon.fill", "sun.max.fill",
        "leaf.fill", "flame.fill", "bolt.fill", "sparkles"
    ]

    private let colorOptions = [
        "#C04851", "#4A9B7F", "#6B7280", "#D4915E",
        "#8B7EC8", "#3B82F6", "#EC4899", "#10B981",
        "#F59E0B", "#6366F1", "#EF4444", "#14B8A6"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xxl) {
                    // 名称输入
                    LSJTextField(
                        label: "账本名称",
                        icon: "pencil",
                        text: $name,
                        placeholder: "例如：我的婚礼、2026春节",
                        isRequired: true
                    )

                    // 图标选择
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                        Text("选择图标")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textPrimary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    HapticManager.shared.selection()
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Color.theme.primary.opacity(0.1) : Color.theme.card)
                                        .foregroundStyle(selectedIcon == icon ? Color.theme.primary : Color.theme.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppConstants.Radius.sm)
                                                .strokeBorder(selectedIcon == icon ? Color.theme.primary : .clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }

                    // 颜色选择
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                        Text("选择颜色")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textPrimary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    HapticManager.shared.selection()
                                    selectedColor = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .gray)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(.white, lineWidth: selectedColor == hex ? 3 : 0)
                                        )
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color(hex: hex)?.opacity(0.5) ?? .clear, lineWidth: selectedColor == hex ? 1 : 0)
                                                .padding(-2)
                                        )
                                }
                            }
                        }
                    }

                    // 预览
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                        Text("预览")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.theme.textPrimary)

                        LSJColoredCard(colorHex: selectedColor) {
                            HStack {
                                Image(systemName: selectedIcon)
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: selectedColor) ?? Color.theme.primary)
                                Text(name.isEmpty ? "账本名称" : name)
                                    .font(.headline)
                                    .foregroundStyle(name.isEmpty ? Color.theme.textSecondary : Color.theme.textPrimary)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(AppConstants.Spacing.lg)
            }
            .lsjPageBackground()
            .navigationTitle(editingBook == nil ? "新建账本" : "编辑账本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveBook()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let book = editingBook {
                    name = book.name
                    selectedIcon = book.icon
                    selectedColor = book.colorHex
                }
            }
        }
    }

    private func saveBook() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let book = editingBook {
            book.name = trimmedName
            book.icon = selectedIcon
            book.colorHex = selectedColor
            book.updatedAt = Date()
            try? modelContext.save()
        } else {
            let book = GiftBook(name: trimmedName, icon: selectedIcon, colorHex: selectedColor)
            modelContext.insert(book)
            try? modelContext.save()
        }

        HapticManager.shared.successNotification()
        dismiss()
    }
}
