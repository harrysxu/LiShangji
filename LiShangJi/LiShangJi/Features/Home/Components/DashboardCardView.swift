//
//  DashboardCardView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 收支概览大卡片
struct DashboardCardView: View {
    let totalReceived: Double
    let totalSent: Double

    private var balance: Double {
        totalReceived - totalSent
    }

    private var total: Double {
        totalReceived + totalSent
    }

    private var receivedRatio: CGFloat {
        guard total > 0 else { return 0.5 }
        return CGFloat(totalReceived / total)
    }

    var body: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // 标题
            HStack {
                Text("本月人情概览")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }

            // 收到 / 送出
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("收到")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(totalReceived.currencyString)
                        .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("送出")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(totalSent.currencyString)
                        .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }

            // 结余
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.white.opacity(0.3))
                Text("结余 \(balance.balanceString)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .fixedSize()
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.white.opacity(0.3))
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.8))
                        .frame(width: max(geometry.size.width * receivedRatio, 4), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(AppConstants.Spacing.xl)
        .background(
            LinearGradient(
                colors: [Color.theme.primary, Color.theme.primary.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.lg))
        .shadow(color: Color.theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    DashboardCardView(totalReceived: 12800, totalSent: 8600)
        .padding()
        .background(Color.theme.background)
}
