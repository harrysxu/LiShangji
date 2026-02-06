//
//  Color+Theme.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

extension Color {
    struct Theme {
        // MARK: - 主色
        let primary = Color("LSJPrimary")         // 朱砂红
        let background = Color("Background")     // 宣纸白
        let textPrimary = Color("TextPrimary")   // 墨色
        let textSecondary = Color("TextSecondary") // 淡墨

        // MARK: - 辅助色
        let received = Color("Received")         // 青竹 - 收到
        let sent = Color("Sent")                 // 烟灰 - 送出
        let warning = Color("Warning")           // 琥珀
        let info = Color("Info")                 // 浅丁香

        // MARK: - 表面色
        let card = Color("CardBackground")
        let cardElevated = Color("CardElevated")
        let divider = Color("Divider")

        // MARK: - 渐变
        var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [Color("LSJPrimary"), Color("LSJPrimary").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        var warmGradient: LinearGradient {
            LinearGradient(
                colors: [Color("Background"), Color("Background").opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static let theme = Theme()
}
