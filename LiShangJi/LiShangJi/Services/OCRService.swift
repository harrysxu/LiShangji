//
//  OCRService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import Vision
import UIKit

/// OCR 识别结果
struct OCRRecognizedItem: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
    var confidence: Float  // 0-1 置信度
    var isVerified: Bool = false
    var isSelected: Bool = true  // 默认选中，用户可取消勾选
    var matchedContact: Contact?  // 自动匹配或手动选择的联系人
}

/// OCR 识别服务
class OCRService {
    static let shared = OCRService()
    private init() {}
    
    /// 从图片识别文字并解析为姓名-金额对
    func recognizeGiftList(from image: UIImage) async throws -> [OCRRecognizedItem] {
        let textLines = try await recognizeText(from: image)
        return parseNameAmountPairs(from: textLines)
    }
    
    /// 纯文字识别
    func recognizeText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var lines: [String] = []
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else {
                        continue
                    }
                    lines.append(topCandidate.string)
                }
                
                continuation.resume(returning: lines)
            }
            
            // 配置识别参数
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 解析识别到的文字行为姓名-金额对
    func parseNameAmountPairs(from lines: [String]) -> [OCRRecognizedItem] {
        var items: [OCRRecognizedItem] = []
        
        // 正则表达式：匹配姓名和金额
        // 支持格式：姓名：金额、姓名 金额、姓名:金额 等
        let pattern = #"([\u4e00-\u9fa5]{2,4})\s*[：:]*\s*([\d,.]+\d*|[\u4e00-\u9fa5]+[元圆]?)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return items
        }
        
        for line in lines {
            let nsString = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                guard match.numberOfRanges >= 3 else { continue }
                
                let nameRange = match.range(at: 1)
                let amountRange = match.range(at: 2)
                
                guard nameRange.location != NSNotFound,
                      amountRange.location != NSNotFound else {
                    continue
                }
                
                let name = nsString.substring(with: nameRange).trimmingCharacters(in: .whitespaces)
                let amountString = nsString.substring(with: amountRange).trimmingCharacters(in: .whitespaces)
                
                // 解析金额
                var amount: Double = 0
                var confidence: Float = 0.8
                
                // 尝试解析阿拉伯数字
                if let arabicAmount = parseArabicAmount(amountString) {
                    amount = arabicAmount
                    confidence = 0.9
                } else if let chineseAmount = chineseNumberToDouble(amountString) {
                    amount = chineseAmount
                    confidence = 0.85
                } else {
                    // 无法解析金额，跳过
                    continue
                }
                
                if !name.isEmpty && amount > 0 {
                    items.append(OCRRecognizedItem(
                        name: name,
                        amount: amount,
                        confidence: confidence,
                        isVerified: false
                    ))
                }
            }
        }
        
        return items
    }
    
    /// 解析阿拉伯数字金额（支持千分位逗号）
    private func parseArabicAmount(_ text: String) -> Double? {
        // 移除千分位逗号和空格
        let cleaned = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "圆", with: "")
        
        return Double(cleaned)
    }
    
    /// 中文大写数字转阿拉伯数字
    func chineseNumberToDouble(_ chinese: String) -> Double? {
        let cleaned = chinese.replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "圆", with: "")
            .replacingOccurrences(of: "整", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // 中文数字映射
        let digitMap: [String: Int] = [
            "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
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
        
        // 处理简单格式：直接数字 + 单位
        // 例如："一千"、"八百"、"陆佰"
        var result: Double = 0
        var currentNumber = 0
        var lastUnit = 1
        
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
                        lastUnit = unit
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
                lastUnit = unit
                i += 1
            } else {
                i += 1
            }
        }
        
        // 处理剩余的数字
        if currentNumber > 0 {
            result += Double(currentNumber)
        }
        
        // 如果结果大于0，返回结果
        return result > 0 ? result : nil
    }
}

/// OCR 服务错误
enum OCRServiceError: LocalizedError {
    case invalidImage
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .recognitionFailed:
            return "文字识别失败"
        }
    }
}
