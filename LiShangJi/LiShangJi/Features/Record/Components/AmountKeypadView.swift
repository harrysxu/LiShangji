//
//  AmountKeypadView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 自定义大数字金额键盘
struct AmountKeypadView: View {
    @Binding var amount: String
    let onSave: () -> Void

    /// 快捷金额选项
    private let quickAmounts: [String] = [
        "200", "500", "600", "666", "800", "888", "1000", "1200", "1666", "1888", "2000"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 快捷金额条
            quickAmountBar

            // 数字键盘
            keypadGrid
        }
    }

    // MARK: - 快捷金额条

    private var quickAmountBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                ForEach(quickAmounts, id: \.self) { value in
                    Button {
                        HapticManager.shared.lightImpact()
                        amount = value
                    } label: {
                        Text(value)
                            .font(.caption.weight(.medium).monospacedDigit())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(amount == value ? Color.theme.primary.opacity(0.15) : Color.theme.card)
                            .foregroundStyle(amount == value ? Color.theme.primary : Color.theme.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.theme.divider, lineWidth: amount == value ? 0 : 0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.sm)
        }
    }

    // MARK: - 键盘网格

    private var keypadGrid: some View {
        VStack(spacing: AppConstants.Keypad.keySpacing) {
            HStack(spacing: AppConstants.Keypad.keySpacing) {
                keyButton("7") { appendDigit("7") }
                keyButton("8") { appendDigit("8") }
                keyButton("9") { appendDigit("9") }
                actionButton(icon: "delete.left", color: Color.theme.textSecondary) { deleteDigit() }
            }
            HStack(spacing: AppConstants.Keypad.keySpacing) {
                keyButton("4") { appendDigit("4") }
                keyButton("5") { appendDigit("5") }
                keyButton("6") { appendDigit("6") }
                actionButton(text: "C", color: Color.theme.warning) { clearAmount() }
            }
            HStack(spacing: AppConstants.Keypad.keySpacing) {
                keyButton("1") { appendDigit("1") }
                keyButton("2") { appendDigit("2") }
                keyButton("3") { appendDigit("3") }
                actionButton(text: ".", color: Color.theme.textSecondary) { appendDigit(".") }
            }
            HStack(spacing: AppConstants.Keypad.keySpacing) {
                keyButton("00") { appendDigit("00") }
                keyButton("0") { appendDigit("0") }
                keyButton("000") { appendDigit("000") }
                saveButton
            }
        }
        .padding(AppConstants.Spacing.md)
    }

    // MARK: - 按钮组件

    private func keyButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Text(text)
                .font(.title3.bold().monospacedDigit())
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.Keypad.keyMinSize)
                .background(Color.theme.card)
                .foregroundStyle(Color.theme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
        }
    }

    private func actionButton(text: String? = nil, icon: String? = nil, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Group {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                } else if let text {
                    Text(text)
                        .font(.title3.bold())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppConstants.Keypad.keyMinSize)
            .background(Color.theme.card)
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
        }
    }

    private var saveButton: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            onSave()
        }) {
            Text("保存")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.Keypad.keyMinSize)
                .background(Color.theme.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
        }
    }

    // MARK: - 输入逻辑

    private func appendDigit(_ digit: String) {
        amount = KeypadInputHelper.appendDigit(digit, to: amount)
    }

    private func deleteDigit() {
        amount = KeypadInputHelper.deleteDigit(from: amount)
    }

    private func clearAmount() {
        amount = KeypadInputHelper.clear()
    }
}
