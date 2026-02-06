//
//  VoiceRecordingService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import Combine
import Speech
import AVFoundation

/// 语音识别结果
struct VoiceRecordResult {
    var contactName: String?
    var amount: Double?
    var direction: String?    // "sent" / "received"
    var eventCategory: String?
    var rawText: String
}

/// 语音记账服务
class VoiceRecordingService: ObservableObject {
    static let shared = VoiceRecordingService()
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var parsedResult: VoiceRecordResult?
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    private init() {
        // 初始化中文语音识别器
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hans"))
    }
    
    /// 请求权限
    func requestPermission() async -> Bool {
        // 请求语音识别权限
        let speechAuth = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechAuth == .authorized else {
            return false
        }

        // 请求麦克风权限
        let micAuth = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        return micAuth
    }
    
    /// 开始录音识别
    func startRecording() throws {
        // 检查权限
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw VoiceRecordingError.permissionDenied
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw VoiceRecordingError.recognizerUnavailable
        }
        
        // 停止之前的任务
        stopRecording()
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceRecordingError.requestCreationFailed
        }
        
        // 尝试使用设备端识别（更快、更私密）
        recognitionRequest.requiresOnDeviceRecognition = true
        
        // 配置输入节点
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 启动音频引擎
        audioEngine.prepare()
        try audioEngine.start()
        
        // 开始识别任务
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let result = result {
                    let bestTranscription = result.bestTranscription.formattedString
                    self.recognizedText = bestTranscription
                    
                    // 实时解析结果
                    if result.isFinal {
                        self.parsedResult = self.parseNaturalLanguage(bestTranscription)
                    }
                }
                
                if let error = error {
                    // 识别完成或出错
                    if error.localizedDescription.contains("cancelled") {
                        // 用户取消，不处理
                    } else {
                        print("语音识别错误: \(error.localizedDescription)")
                    }
                    self.stopRecording()
                }
            }
        }
        
        isRecording = true
    }
    
    /// 停止录音识别
    func stopRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isRecording = false
    }
    
    /// 解析自然语言
    func parseNaturalLanguage(_ text: String) -> VoiceRecordResult {
        var result = VoiceRecordResult(rawText: text)
        
        // 解析方向（送/收到）
        if let direction = parseDirection(text) {
            result.direction = direction
        }
        
        // 解析联系人姓名
        if let name = parseContactName(text) {
            result.contactName = name
        }
        
        // 解析金额
        if let amount = parseAmount(text) {
            result.amount = amount
        }
        
        // 解析事件类型
        if let category = parseEventCategory(text) {
            result.eventCategory = category
        }
        
        return result
    }
    
    /// 解析方向：sent / received
    private func parseDirection(_ text: String) -> String? {
        let sentKeywords = ["送", "给", "随", "随礼", "送礼", "给", "赠"]
        let receivedKeywords = ["收到", "收", "收到", "接", "接到"]
        
        for keyword in sentKeywords {
            if text.contains(keyword) {
                return "sent"
            }
        }
        
        for keyword in receivedKeywords {
            if text.contains(keyword) {
                return "received"
            }
        }
        
        return nil
    }
    
    /// 解析联系人姓名（2-4个中文字符）
    private func parseContactName(_ text: String) -> String? {
        // 匹配2-4个连续的中文字符
        let pattern = #"[\u4e00-\u9fa5]{2,4}"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        // 过滤掉常见词汇
        let excludeWords = ["结婚", "生日", "满月", "收到", "收到", "随礼", "送礼", "礼金", "婚礼", "周岁", "百岁"]
        
        for match in matches {
            let nameRange = Range(match.range, in: text)!
            let name = String(text[nameRange])
            
            // 排除常见词汇
            if !excludeWords.contains(name) {
                return name
            }
        }
        
        return nil
    }
    
    /// 解析金额
    private func parseAmount(_ text: String) -> Double? {
        // 先尝试解析阿拉伯数字
        let arabicPattern = #"(\d+\.?\d*)[万千百十]?[元圆]?"#
        if let regex = try? NSRegularExpression(pattern: arabicPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
           let amountRange = Range(match.range(at: 1), in: text) {
            if let amount = Double(String(text[amountRange])) {
                // 检查是否有单位
                let unitRange = Range(match.range, in: text)!
                let fullMatch = String(text[unitRange])
                
                if fullMatch.contains("万") {
                    return amount * 10000
                } else if fullMatch.contains("千") {
                    return amount * 1000
                } else if fullMatch.contains("百") {
                    return amount * 100
                } else if fullMatch.contains("十") {
                    return amount * 10
                }
                return amount
            }
        }
        
        // 解析中文数字
        return parseChineseAmount(text)
    }
    
    /// 解析中文金额
    private func parseChineseAmount(_ text: String) -> Double? {
        // 提取包含数字的部分
        let pattern = #"([零一二三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟萬]+)[元圆]?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
              let amountRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        let chineseAmount = String(text[amountRange])
        return chineseNumberToDouble(chineseAmount)
    }
    
    /// 中文数字转阿拉伯数字
    private func chineseNumberToDouble(_ chinese: String) -> Double? {
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
        
        var result: Double = 0
        var currentNumber = 0
        var tempResult = 0
        
        let characters = Array(chinese)
        var i = 0
        
        while i < characters.count {
            let char = String(characters[i])
            
            if let digit = digitMap[char] {
                currentNumber = digit
                i += 1
            } else if let unit = unitMap[char] {
                if currentNumber == 0 {
                    currentNumber = 1
                }
                tempResult += currentNumber * unit
                currentNumber = 0
                i += 1
            } else {
                i += 1
            }
        }
        
        result = Double(tempResult + currentNumber)
        
        return result > 0 ? result : nil
    }
    
    /// 解析事件类型
    private func parseEventCategory(_ text: String) -> String? {
        let eventMap: [String: String] = [
            "结婚": "wedding",
            "婚礼": "wedding",
            "婚宴": "wedding",
            "生日": "birthday",
            "寿宴": "birthday",
            "满月": "full_moon",
            "满月酒": "full_moon",
            "周岁": "first_birthday",
            "百岁": "hundred_days",
            "升学": "education",
            "乔迁": "housewarming",
            "开业": "opening",
            "开业典礼": "opening",
            "丧事": "funeral",
            "白事": "funeral"
        ]
        
        for (keyword, category) in eventMap {
            if text.contains(keyword) {
                return category
            }
        }
        
        return nil
    }
}

/// 语音识别错误
enum VoiceRecordingError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case requestCreationFailed
    case audioEngineError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "未授权语音识别权限"
        case .recognizerUnavailable:
            return "语音识别器不可用"
        case .requestCreationFailed:
            return "创建识别请求失败"
        case .audioEngineError:
            return "音频引擎错误"
        }
    }
}
