//
//  HapticManager.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import UIKit

/// 触觉反馈管理器
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    /// 冲击反馈
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// 通知反馈
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// 选择反馈
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - 便捷方法（无需 UIKit 类型引用）

    func lightImpact() {
        impact(style: .light)
    }

    func mediumImpact() {
        impact(style: .medium)
    }

    func heavyImpact() {
        impact(style: .heavy)
    }

    func successNotification() {
        notification(type: .success)
    }

    func warningNotification() {
        notification(type: .warning)
    }

    func errorNotification() {
        notification(type: .error)
    }
}
