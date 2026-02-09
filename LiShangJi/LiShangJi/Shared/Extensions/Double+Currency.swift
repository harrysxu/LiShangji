//
//  Double+Currency.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

extension Double {
    // MARK: - 缓存的 NumberFormatter（避免每次调用都重新创建，NumberFormatter 创建开销约 1-5ms）

    private static let _currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "¥"
        return f
    }()

    private static let _decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    /// 格式化为人民币字符串，如 "¥1,000"
    var currencyString: String {
        let formatter = Self._currencyFormatter
        formatter.maximumFractionDigits = (self.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? "¥0"
    }

    /// 格式化为简洁金额字符串，如 "1,000"
    var amountString: String {
        let formatter = Self._decimalFormatter
        formatter.maximumFractionDigits = (self.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }

    /// 格式化为带正负号的差额字符串
    var balanceString: String {
        let prefix = self > 0 ? "+" : ""
        return "\(prefix)\(currencyString)"
    }

    /// 将阿拉伯数字金额转为中文大写
    var chineseUppercase: String {
        let digits = ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"]
        let units = ["", "拾", "佰", "仟"]
        let bigUnits = ["", "万", "亿"]

        let intPart = Int(self)
        if intPart == 0 { return "零元整" }

        var result = ""
        var remaining = intPart
        var groupIndex = 0

        while remaining > 0 {
            let group = remaining % 10000
            if group > 0 {
                var groupStr = ""
                var g = group
                for i in 0..<4 {
                    let digit = g % 10
                    if digit > 0 {
                        groupStr = digits[digit] + units[i] + groupStr
                    } else if !groupStr.isEmpty && !groupStr.hasPrefix("零") {
                        groupStr = "零" + groupStr
                    }
                    g /= 10
                }
                result = groupStr + bigUnits[groupIndex] + result
            }
            remaining /= 10000
            groupIndex += 1
        }

        // 移除最高位多余的零
        while result.hasPrefix("零") {
            result = String(result.dropFirst())
        }

        return result + "元整"
    }
}
