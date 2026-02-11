//
//  ChineseNumberParser.swift
//  LiShangJi
//
//  中文数字解析工具 - 将中文数字转换为阿拉伯数字
//

import Foundation

/// 中文数字解析工具
enum ChineseNumberParser {
    
    /// 中文大写/小写数字转阿拉伯数字
    /// - Parameter chinese: 中文数字字符串，如 "一千"、"八百八十八"、"壹仟伍佰"
    /// - Returns: 对应的 Double 值，无法解析时返回 nil
    static func parse(_ chinese: String) -> Double? {
        let cleaned = chinese.replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "圆", with: "")
            .replacingOccurrences(of: "整", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        guard !cleaned.isEmpty else { return nil }
        
        // 中文数字映射（含 "两" = 2）
        let digitMap: [String: Int] = [
            "零": 0, "一": 1, "二": 2, "两": 2, "三": 3, "四": 4,
            "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
            "壹": 1, "贰": 2, "叁": 3, "肆": 4, "伍": 5,
            "陆": 6, "柒": 7, "捌": 8, "玖": 9
        ]
        
        let unitMap: [String: Int] = [
            "十": 10, "拾": 10,
            "百": 100, "佰": 100,
            "千": 1000, "仟": 1000,
            "万": 10000, "萬": 10000
        ]
        
        var result: Double = 0
        var currentNumber = 0
        
        let characters = Array(cleaned)
        var i = 0
        
        while i < characters.count {
            let char = String(characters[i])
            
            if let digit = digitMap[char] {
                currentNumber = digit
                i += 1
                
                // 检查后面是否有单位
                if i < characters.count {
                    let nextChar = String(characters[i])
                    if let unit = unitMap[nextChar] {
                        result += Double(currentNumber * unit)
                        currentNumber = 0
                        i += 1
                    } else {
                        // 没有单位，直接加数字
                        result += Double(currentNumber)
                        currentNumber = 0
                    }
                } else {
                    // 最后一个字符是数字
                    result += Double(currentNumber)
                    currentNumber = 0
                }
            } else if let unit = unitMap[char] {
                // 单独的单位，如"十"、"百"等
                if currentNumber == 0 {
                    currentNumber = 1
                }
                result += Double(currentNumber * unit)
                currentNumber = 0
                i += 1
            } else {
                i += 1
            }
        }
        
        // 处理剩余的数字
        if currentNumber > 0 {
            result += Double(currentNumber)
        }
        
        return result > 0 ? result : nil
    }
}
