//
//  LSJTag.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 标签组件
struct LSJTag: View {
    let text: String
    var color: Color = Color.theme.primary
    var isSelected: Bool = false
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            isSelected ? color : color.opacity(0.1)
        )
        .foregroundStyle(
            isSelected ? .white : color
        )
        .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        LSJTag(text: "婚礼", isSelected: true, icon: "heart.fill")
        LSJTag(text: "生日", icon: "gift.fill")
        LSJTag(text: "春节", color: .orange)
    }
}
