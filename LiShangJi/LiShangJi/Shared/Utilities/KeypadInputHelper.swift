//
//  KeypadInputHelper.swift
//  LiShangJi
//
//  金额键盘输入验证逻辑（从 AmountKeypadView 提取，方便测试）
//

import Foundation

/// 键盘输入辅助工具 - 处理金额输入的验证与格式化
struct KeypadInputHelper {

    /// 追加数字/小数点到金额字符串，返回新字符串
    /// - Parameters:
    ///   - digit: 要追加的字符（"0"-"9"、"."、"00"、"000"）
    ///   - amount: 当前金额字符串
    /// - Returns: 追加后的新金额字符串
    static func appendDigit(_ digit: String, to amount: String) -> String {
        var result = amount

        // 小数点处理
        if digit == "." {
            guard !result.contains(".") else { return result }
            if result.isEmpty { result = "0" }
        }

        // 限制小数点后两位
        if result.contains(".") {
            let parts = result.split(separator: ".")
            if parts.count > 1 && parts[1].count >= 2 { return result }
        }

        // 限制整数位数（最多8位）
        if !result.contains(".") && result.count >= 8 && digit != "." { return result }

        result += digit
        return result
    }

    /// 删除最后一个字符
    static func deleteDigit(from amount: String) -> String {
        guard !amount.isEmpty else { return amount }
        return String(amount.dropLast())
    }

    /// 清空金额
    static func clear() -> String {
        return ""
    }
}
