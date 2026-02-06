//
//  LSJToast.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// Toast 提示类型
enum ToastType {
    case success, error, info

    var color: Color {
        switch self {
        case .success: return Color.theme.received
        case .error: return Color.theme.primary
        case .info: return Color.theme.info
        }
    }

    var defaultIcon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

/// Toast 提示组件
struct LSJToast: View {
    let message: String
    var icon: String? = nil
    let type: ToastType

    var body: some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            Image(systemName: icon ?? type.defaultIcon)
                .foregroundStyle(type.color)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.theme.textPrimary)
        }
        .padding(.horizontal, AppConstants.Spacing.lg)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

/// Toast 修饰器 - 用于在视图上层展示 Toast
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastType
    var duration: Double = 2.0

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    LSJToast(message: message, type: type)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }
                        }
                    Spacer()
                }
                .padding(.top, 50)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, type: ToastType = .success) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, message: message, type: type))
    }
}

#Preview {
    VStack(spacing: 16) {
        LSJToast(message: "记录保存成功", type: .success)
        LSJToast(message: "保存失败，请重试", type: .error)
        LSJToast(message: "数据同步中...", type: .info)
    }
}
