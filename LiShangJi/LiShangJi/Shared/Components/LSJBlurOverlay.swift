//
//  LSJBlurOverlay.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 隐私模糊遮罩 - 当 App 进入后台时覆盖界面
struct LSJBlurOverlay: View {
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()

            VStack(spacing: AppConstants.Spacing.lg) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.theme.primary)

                Text(AppConstants.Brand.appName)
                    .font(.title2.bold())
                    .foregroundStyle(Color.theme.textPrimary)

                Text("请验证身份以继续使用")
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.textSecondary)
            }
        }
    }
}

#Preview {
    LSJBlurOverlay()
}
