//
//  LSJEmptyStateView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 空状态视图组件
struct LSJEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.theme.textSecondary.opacity(0.5))

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.theme.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                LSJButton(title: actionTitle, style: .primary, isFullWidth: false, action: action)
                    .frame(width: 200)
            }
        }
        .padding(AppConstants.Spacing.xxxl)
    }
}

#Preview {
    LSJEmptyStateView(
        icon: "book.closed",
        title: "还没有账本",
        subtitle: "创建你的第一个人情账本吧",
        actionTitle: "创建账本"
    ) {
        print("创建账本")
    }
}
