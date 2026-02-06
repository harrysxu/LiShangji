//
//  View+PageBackground.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

extension View {
    /// 统一页面背景修饰符
    /// 1. frame(maxWidth/maxHeight) 确保视图撑满全屏（解决 VStack 等不自动撑满的问题）
    /// 2. background 使用 ShapeStyle 重载，默认 ignoresSafeAreaEdges: .all，覆盖安全区域
    /// 注意：导航栏和标签栏的 UIKit 外观已在 AppearanceConfigurator 中全局配置
    func lsjPageBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.theme.background)
    }
}

// MARK: - 全局 UIKit 外观配置

/// 统一配置 UIKit 组件（TabBar / NavigationBar）的外观
/// 需要在 App 启动时尽早调用，确保在所有视图创建之前生效
enum AppearanceConfigurator {
    static func configure() {
        let bgColor = UIColor(Color("Background"))
        let textColor = UIColor(Color("TextPrimary"))

        // TabBar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = bgColor
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // NavigationBar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = bgColor
        navBarAppearance.shadowColor = .clear
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: textColor]
        navBarAppearance.titleTextAttributes = [.foregroundColor: textColor]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
}
