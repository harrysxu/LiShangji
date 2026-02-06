//
//  View+Haptics.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

extension View {
    /// 轻触觉反馈
    func hapticLight() {
        HapticManager.shared.impact(style: .light)
    }

    /// 中等触觉反馈
    func hapticMedium() {
        HapticManager.shared.impact(style: .medium)
    }

    /// 成功触觉反馈
    func hapticSuccess() {
        HapticManager.shared.notification(type: .success)
    }

    /// 警告触觉反馈
    func hapticWarning() {
        HapticManager.shared.notification(type: .warning)
    }

    /// 错误触觉反馈
    func hapticError() {
        HapticManager.shared.notification(type: .error)
    }
}
