//
//  QuickEntryButton.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 快捷操作按钮
struct QuickEntryButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            VStack(spacing: AppConstants.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.Spacing.md)
            .background(Color.theme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    HStack {
        QuickEntryButton(icon: "square.and.pencil", title: "记一笔", color: Color.theme.primary) {}
        QuickEntryButton(icon: "camera.viewfinder", title: "扫一扫", color: Color.theme.info) {}
        QuickEntryButton(icon: "mic.fill", title: "说一说", color: Color.theme.warning) {}
    }
    .padding()
    .background(Color.theme.background)
}
