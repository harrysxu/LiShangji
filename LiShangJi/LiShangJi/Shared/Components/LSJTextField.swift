//
//  LSJTextField.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 带图标的输入框组件
struct LSJTextField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var placeholder: String = ""
    var isRequired: Bool = false

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    if isRequired {
                        Text("*")
                            .font(.caption)
                            .foregroundStyle(Color.theme.primary)
                    }
                }
                TextField(placeholder, text: $text)
                    .font(.body)
            }
        }
        .padding(AppConstants.Spacing.md)
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
    }
}

/// 带图标的只读行（用于导航到选择器等）
struct LSJFieldRow: View {
    let label: String
    let icon: String
    let value: String
    var valueColor: Color = Color.theme.textPrimary

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundStyle(valueColor)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .padding(AppConstants.Spacing.md)
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
    }
}

#Preview {
    VStack(spacing: 12) {
        LSJTextField(label: "联系人", icon: "person.fill", text: .constant("张三"), isRequired: true)
        LSJFieldRow(label: "日期", icon: "calendar", value: "2026年2月6日")
    }
    .padding()
    .background(Color.theme.background)
}
