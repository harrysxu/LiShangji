//
//  LSJCard.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 通用卡片容器组件
struct LSJCard<Content: View>: View {
    var padding: CGFloat = AppConstants.Spacing.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Color.theme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

/// 带彩色顶部标记条的卡片
struct LSJColoredCard<Content: View>: View {
    let colorHex: String
    var padding: CGFloat = AppConstants.Spacing.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: colorHex) ?? Color.theme.primary)
                .frame(height: 4)

            content()
                .padding(padding)
        }
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Color HEX 初始化扩展

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    VStack(spacing: 16) {
        LSJCard {
            VStack(alignment: .leading) {
                Text("我的婚礼")
                    .font(.headline)
                Text("收到 ¥58,800")
                    .font(.title2.bold())
                    .foregroundStyle(Color.theme.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        LSJColoredCard(colorHex: "#C04851") {
            Text("带颜色标记的卡片")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
    .background(Color.theme.background)
}
