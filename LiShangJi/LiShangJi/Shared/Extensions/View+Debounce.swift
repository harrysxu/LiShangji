//
//  View+Debounce.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/8.
//

import SwiftUI

/// 防抖 ViewModifier，防止按钮短时间内被重复点击
private struct DebounceModifier: ViewModifier {
    let interval: TimeInterval
    @State private var debouncing = false

    func body(content: Content) -> some View {
        content
            .allowsHitTesting(!debouncing)
            .simultaneousGesture(TapGesture().onEnded {
                debouncing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    debouncing = false
                }
            })
    }
}

extension View {
    /// 为视图添加防抖功能，防止短时间内重复点击
    /// - Parameter interval: 防抖间隔（秒），默认 0.5 秒
    func debounced(_ interval: TimeInterval = 0.5) -> some View {
        modifier(DebounceModifier(interval: interval))
    }
}
