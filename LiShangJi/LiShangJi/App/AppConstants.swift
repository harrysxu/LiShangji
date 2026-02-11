//
//  AppConstants.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 全局设计 Token 和常量
enum AppConstants {

    // MARK: - 间距系统 (基于 4pt 栅格)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - 圆角系统

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - 页面边距

    enum PagePadding {
        static let iPhone: CGFloat = 16
        static let iPad: CGFloat = 20
    }

    // MARK: - 动画

    enum Animation {
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.8
        static let quickDuration: Double = 0.2
        static let normalDuration: Double = 0.3

        static var defaultSpring: SwiftUI.Animation {
            .spring(response: springResponse, dampingFraction: springDamping)
        }
    }

    // MARK: - 键盘

    enum Keypad {
        static let keyMinSize: CGFloat = 52
        static let keySpacing: CGFloat = 8
    }

    // MARK: - 品牌信息

    enum Brand {
        static let appName = "随手礼"
        static let slogan = "懂礼数，更懂你"
        static let version = "1.0"
        static let developerEmail = "ailehuoquan@163.com"
        static let privacyPolicyURL = "https://harrysxu.github.io/LiShangji/pages/privacy-policy.html"
        static let termsOfServiceURL = "https://harrysxu.github.io/LiShangji/pages/terms-of-service.html"
    }
}
