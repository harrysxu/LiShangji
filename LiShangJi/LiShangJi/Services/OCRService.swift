//
//  OCRService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import Vision
import UIKit

#if canImport(FoundationModels)
import FoundationModels

// MARK: - AI 解析数据模型 (Foundation Models)

@available(iOS 26.0, *)
@Generable(description: "从礼单/人情簿OCR文本中解析出的所有姓名-金额记录")
struct AIOCRParseResult {
    @Guide(description: "从OCR文本中识别出的所有姓名和金额记录")
    var items: [AIOCRItem]
}

@available(iOS 26.0, *)
@Generable(description: "礼单中的一条记录，包含姓名和金额")
struct AIOCRItem {
    @Guide(description: "联系人姓名，通常2-4个中文字")
    var name: String
    
    @Guide(description: "礼金金额，阿拉伯数字")
    var amount: Double
}
#endif

// MARK: - OCR 识别结果

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
    
    // MARK: - 智能识别（AI 优先，正则回退）
    
    /// 从图片识别文字并智能解析为姓名-金额对
    /// 优先使用 Foundation Models AI 解析，不可用时回退到正则解析
    func smartRecognizeGiftList(from image: UIImage) async throws -> [OCRRecognizedItem] {
        let textLines = try await recognizeText(from: image)
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let aiResults = await aiParseGiftList(textLines: textLines) {
                return aiResults
            }
        }
        #endif
        
        // 回退到正则解析
        return regexParseNameAmountPairs(from: textLines)
    }
    
    /// 从图片识别文字并解析为姓名-金额对（仅正则，兼容旧调用）
    func recognizeGiftList(from image: UIImage) async throws -> [OCRRecognizedItem] {
        let textLines = try await recognizeText(from: image)
        return regexParseNameAmountPairs(from: textLines)
    }
    
    // MARK: - 文字识别 (Vision)
    
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
    
    // MARK: - AI 解析 (Foundation Models)
    
    #if canImport(FoundationModels)
    /// 使用 Foundation Models 解析 OCR 文本
    @available(iOS 26.0, *)
    private func aiParseGiftList(textLines: [String]) async -> [OCRRecognizedItem]? {
        let fullText = textLines.joined(separator: "\n")
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        do {
            let session = LanguageModelSession {
                """
                你是一个礼单/人情簿文字识别助手。你的任务是从 OCR 识别的文字中，
                准确提取每一条姓名和金额记录。
                
                注意事项：
                - 姓名通常是 2-4 个中文字
                - 金额可能是阿拉伯数字（如 1000、2,000）或中文数字（如 一千、两百）
                - 中文数字请转为阿拉伯数字
                - 带千位分隔符的数字要正确识别（如 1,000 = 1000）
                - 忽略表头、标题、合计等非记录行
                - 如果文字排版混乱，请尽量根据上下文判断哪些是姓名、哪些是金额
                - 每条记录只需要姓名和金额
                """
            }
            
            let prompt = "请从以下 OCR 识别文本中提取所有姓名-金额记录：\n\(fullText)"
            
            let response = try await session.respond(
                to: prompt,
                generating: AIOCRParseResult.self
            )
            
            let aiResult = response.content
            let items = aiResult.items.compactMap { item -> OCRRecognizedItem? in
                let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, item.amount > 0 else { return nil }
                return OCRRecognizedItem(
                    name: name,
                    amount: item.amount,
                    confidence: 0.95,  // AI 解析置信度较高
                    isVerified: false
                )
            }
            
            return items.isEmpty ? nil : items
        } catch {
            print("AI OCR解析失败，回退到正则解析: \(error)")
            return nil
        }
    }
    #endif
    
    // MARK: - 正则解析（回退方案）
    
    /// 解析识别到的文字行为姓名-金额对（正则方式）
    func regexParseNameAmountPairs(from lines: [String]) -> [OCRRecognizedItem] {
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
    
    /// 兼容旧方法名
    func parseNameAmountPairs(from lines: [String]) -> [OCRRecognizedItem] {
        return regexParseNameAmountPairs(from: lines)
    }
    
    // MARK: - 金额解析工具
    
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
        ChineseNumberParser.parse(chinese)
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
