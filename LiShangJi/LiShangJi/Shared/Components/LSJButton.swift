//
//  LSJButton.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 按钮样式枚举
enum LSJButtonStyle {
    case primary    // 朱砂红背景 + 白色文字
    case secondary  // 白色背景 + 朱砂红文字 + 边框
    case text       // 无背景 + 朱砂红文字
}

/// 通用按钮组件
struct LSJButton: View {
    let title: String
    let style: LSJButtonStyle
    var icon: String? = nil
    var isFullWidth: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: AppConstants.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(.headline)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, isFullWidth ? 0 : 20)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Radius.sm)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return Color.theme.primary
        case .secondary: return Color.theme.card
        case .text: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary, .text: return Color.theme.primary
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return Color.theme.primary
        default: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LSJButton(title: "保存记录", style: .primary) {}
        LSJButton(title: "取消", style: .secondary) {}
        LSJButton(title: "查看全部", style: .text, isFullWidth: false) {}
        LSJButton(title: "加载中", style: .primary, isLoading: true) {}
    }
    .padding()
}
