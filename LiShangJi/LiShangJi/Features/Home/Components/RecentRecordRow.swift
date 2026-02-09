//
//  RecentRecordRow.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 最近记录列表行
struct RecentRecordRow: View {
    let record: GiftRecord

    private var isReceived: Bool {
        record.direction == GiftDirection.received.rawValue
    }

    var body: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            // 方向指示圆点
            Circle()
                .fill(isReceived ? Color.theme.received : Color.theme.sent)
                .frame(width: 8, height: 8)

            // 联系人 & 事件
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppConstants.Spacing.xs) {
                    Text(record.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.theme.textPrimary)
                    Text("·")
                        .foregroundStyle(Color.theme.textSecondary)
                    Text(record.eventName)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.textSecondary)
                }

                HStack(spacing: AppConstants.Spacing.xs) {
                    Text(isReceived ? "收到" : "送出")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text(record.eventDate.chineseMonthDay)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }

            Spacer()

            // 金额
            Text(record.amount.currencyString)
                .font(.body.bold().monospacedDigit())
                .foregroundStyle(isReceived ? Color.theme.received : Color.theme.sent)
        }
        .padding(.vertical, AppConstants.Spacing.sm)
    }
}
