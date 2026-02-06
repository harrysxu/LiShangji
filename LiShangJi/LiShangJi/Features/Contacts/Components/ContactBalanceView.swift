//
//  ContactBalanceView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 人情差额展示组件
struct ContactBalanceView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: AppConstants.Spacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text("收到")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Text(contact.totalReceived.currencyString)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.theme.received)
            }

            VStack(alignment: .center, spacing: 2) {
                Text("差额")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Text(contact.balance.balanceString)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(contact.balance >= 0 ? Color.theme.received : Color.theme.sent)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("送出")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Text(contact.totalSent.currencyString)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.theme.sent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.Spacing.md)
        .background(Color.theme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
    }
}
