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

#if canImport(FoundationModels)
import FoundationModels

// MARK: - AI 解析数据模型 (Foundation Models)

@available(iOS 26.0, *)
@Generable(description: "从语音文本中解析出的所有人情往来/礼金记录")
struct AIGiftParseResult {
    @Guide(description: "从文本中识别出的所有人情往来记录，每条包含姓名、金额、方向和事件类型")
    var records: [AIGiftRecord]
}

@available(iOS 26.0, *)
@Generable(description: "一条人情往来记录，包含联系人、金额、方向和事件")
struct AIGiftRecord {
    @Guide(description: "联系人姓名，一般为2-4个中文字的人名")
    var contactName: String
    
    @Guide(description: "礼金金额，转为阿拉伯数字（如一千=1000，五百=500）")
    var amount: Double
    
    @Guide(description: "礼金方向：sent表示送出给别人（随礼、送、给），received表示收到别人的（收到、接到）")
    var direction: AIGiftDirection
    
    @Guide(description: "事件类别")
    var eventCategory: AIEventCategoryType
}

@available(iOS 26.0, *)
@Generable(description: "礼金方向：送出或收到")
enum AIGiftDirection {
    /// 送出给别人的，包括：随礼、送礼、给、赠送
    case sent
    /// 收到别人给的，包括：收到、接到、收
    case received
}

@available(iOS 26.0, *)
@Generable(description: "人情往来的事件类别")
enum AIEventCategoryType {
    /// 结婚、婚礼、婚宴
    case wedding
    /// 新生儿、生孩子
    case babyBorn
    /// 满月、满月酒
    case fullMoon
    /// 周岁
    case firstBirthday
    /// 生日、寿宴
    case birthday
    /// 丧事、白事、葬礼
    case funeral
    /// 乔迁、搬家、新居
    case housewarming
    /// 升学、考上、金榜题名
    case graduation
    /// 升职、晋升
    case promotion
    /// 春节、过年
    case springFestival
    /// 中秋、中秋节
    case midAutumn
    /// 端午、端午节
    case dragonBoat
    /// 其他
    case other
}
#endif

// MARK: - 语音识别结果

/// 语音识别结果
struct VoiceRecordResult {
    var contactName: String?
    var amount: Double?
    var direction: String?    // "sent" / "received"
    var eventCategory: String?
    var rawText: String
}

/// 语音权限状态
enum VoicePermissionStatus {
    case authorized
    case notDetermined
    case denied
}

/// 语音记账服务
class VoiceRecordingService: ObservableObject {
    static let shared = VoiceRecordingService()
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var lastError: String?
    @Published var isParsing = false
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    private init() {
        // 初始化中文语音识别器
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hans"))
    }
    
    /// 检查当前权限状态
    func checkPermissionStatus() -> VoicePermissionStatus {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechStatus {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        default:
            return .denied
        }
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
        if #available(iOS 17.0, *) {
            let micAuth = await AVAudioApplication.requestRecordPermission()
            return micAuth
        } else {
            let micAuth = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            return micAuth
        }
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
        
        // 优先使用设备端识别（更快、更私密），不可用时回退到服务端识别
        if recognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
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
                    self.recognizedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    // 过滤预期内的错误（用户主动停止录音时产生）
                    let nsError = error as NSError
                    let isExpectedError = nsError.domain == "kAFAssistantErrorDomain"
                        && [216, 1110].contains(nsError.code)  // 216=取消, 1110=无语音
                    let isKnownMessage = error.localizedDescription.contains("cancelled")
                        || error.localizedDescription.contains("canceled")
                        || error.localizedDescription.lowercased().contains("no speech")
                        || error.localizedDescription.lowercased().contains("nospeech")
                    
                    if !isExpectedError && !isKnownMessage {
                        self.lastError = "语音识别错误: \(error.localizedDescription)"
                    }
                    self.stopRecording()
                }
            }
        }
        
        isRecording = true
    }
    
    /// 停止录音识别
    func stopRecording() {
        // 防止重入（错误回调中也会调用 stopRecording）
        guard isRecording || recognitionTask != nil else { return }
        
        // 1. 先停止音频输入
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 2. 通知识别请求音频已结束（让识别器处理缓冲区中剩余音频）
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // 3. 使用 finish() 而非 cancel()，让识别任务优雅结束并返回最终结果
        recognitionTask?.finish()
        recognitionTask = nil
        
        // 4. 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isRecording = false
    }
    
    // MARK: - 智能解析（优先AI，回退正则）
    
    /// 智能解析：优先使用 Foundation Models AI 解析，不可用时回退到正则解析
    func smartParse(_ text: String) async -> [VoiceRecordResult] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let aiResults = await aiParseMultipleRecords(text), !aiResults.isEmpty {
                return aiResults
            }
        }
        #endif
        // 回退到正则解析
        return parseMultipleRecords(text)
    }
    
    // MARK: - AI 解析 (Foundation Models)
    
    #if canImport(FoundationModels)
    /// 使用 Foundation Models 进行 AI 解析
    @available(iOS 26.0, *)
    private func aiParseMultipleRecords(_ text: String) async -> [VoiceRecordResult]? {
        do {
            let session = LanguageModelSession {
                """
                你是一个中文人情往来/礼金记录解析助手。你的任务是从用户的语音输入文本中，
                准确提取出每一条礼金记录，包括：联系人姓名、金额、方向（送出/收到）和事件类型。
                
                注意事项：
                - "随礼"、"送"、"给"、"赠" 表示送出(sent)
                - "收到"、"收"、"接到" 表示收到(received)
                - 如果没有明确方向关键词，默认为送出(sent)
                - 中文数字请转为阿拉伯数字（如：一千=1000，八百=800，两千=2000）
                - 带分隔符的数字也要正确识别（如：1,000=1000）
                - 文本中可能包含多条记录，请全部提取
                """
            }
            
            let prompt = "请解析以下语音识别文本中的所有礼金记录：\(text)"
            
            let response = try await session.respond(
                to: prompt,
                generating: AIGiftParseResult.self
            )
            
            let aiResult = response.content
            return aiResult.records.map { record in
                VoiceRecordResult(
                    contactName: record.contactName,
                    amount: record.amount,
                    direction: record.direction == .sent ? "sent" : "received",
                    eventCategory: mapAIEventCategory(record.eventCategory),
                    rawText: text
                )
            }
        } catch {
            print("AI解析失败，回退到正则解析: \(error)")
            return nil
        }
    }
    
    /// 将 AI 事件类型映射为分类中文名
    @available(iOS 26.0, *)
    private func mapAIEventCategory(_ aiCategory: AIEventCategoryType) -> String {
        switch aiCategory {
        case .wedding: return "婚礼"
        case .babyBorn: return "新生儿"
        case .fullMoon: return "满月酒"
        case .firstBirthday: return "周岁"
        case .birthday: return "生日"
        case .funeral: return "丧事"
        case .housewarming: return "乔迁"
        case .graduation: return "升学"
        case .promotion: return "升职"
        case .springFestival: return "春节"
        case .midAutumn: return "中秋"
        case .dragonBoat: return "端午"
        case .other: return "其他"
        }
    }
    #endif
    
    // MARK: - 正则解析（改进版，同时作为 AI 不可用时的回退方案）
    
    /// 将语音文本拆分为多条记录并逐条解析
    func parseMultipleRecords(_ text: String) -> [VoiceRecordResult] {
        // 预处理：移除数字中的千位分隔符
        let cleanedText = removeNumberSeparators(text)
        
        // 第一步：按标点和连接词分隔
        let separatorPattern = #"[，,。.；;、\n]|还有|然后|另外|以及|再有"#
        let segments = splitText(cleanedText, by: separatorPattern)
        
        // 第二步：对每个片段，尝试检测是否包含多条记录（无分隔符的情况）
        var allSegments: [String] = []
        for segment in segments {
            let subSegments = splitByRecordBoundary(segment)
            allSegments.append(contentsOf: subSegments)
        }
        
        // 逐段解析，过滤掉无效片段（至少需要姓名或金额）
        var results: [VoiceRecordResult] = []
        for segment in allSegments {
            let result = parseSingleRecord(segment)
            if result.contactName != nil || result.amount != nil {
                results.append(result)
            }
        }
        
        // 如果分段后没有有效结果，尝试整体解析
        if results.isEmpty {
            let wholeResult = parseSingleRecord(cleanedText)
            if wholeResult.contactName != nil || wholeResult.amount != nil {
                results.append(wholeResult)
            }
        }
        
        return results
    }
    
    /// 解析单条自然语言记录
    func parseSingleRecord(_ text: String) -> VoiceRecordResult {
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
    
    // MARK: - 文本预处理
    
    /// 移除数字中的千位分隔符（如 "1,000" → "1000", "10,000" → "10000"）
    private func removeNumberSeparators(_ text: String) -> String {
        let pattern = #"(\d),(\d{3})"#
        var result = text
        // 循环处理，因为 "1,000,000" 需要多次替换
        while let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) != nil {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1$2"
            )
        }
        return result
    }
    
    /// 按正则模式分割文本
    private func splitText(_ text: String, by pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [text]
        }
        let nsText = text as NSString
        var parts: [String] = []
        var lastEnd = 0
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        for match in matches {
            let partRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
            let part = nsText.substring(with: partRange).trimmingCharacters(in: .whitespaces)
            if !part.isEmpty {
                parts.append(part)
            }
            lastEnd = match.range.location + match.range.length
        }
        let remaining = nsText.substring(from: lastEnd).trimmingCharacters(in: .whitespaces)
        if !remaining.isEmpty {
            parts.append(remaining)
        }
        return parts.isEmpty ? [text] : parts
    }
    
    /// 检测并分割无分隔符的多条记录
    /// 支持: "张三结婚一千元李四生日五百元" / "张三结婚2000李四生日500"
    private func splitByRecordBoundary(_ text: String) -> [String] {
        // 查找所有金额结束位置
        // 阿拉伯数字: "2000元" 或 "2000"（不带单位也能识别边界）
        let arabicAmountPattern = #"\d+[元圆块钱]?"#
        // 中文数字: 必须带单位才能准确识别（避免误匹配）
        let chineseAmountPattern = #"[零一二三四五六七八九十百千万两壹贰叁肆伍陆柒捌玖拾佰仟萬]+[元圆块钱]"#
        let combinedPattern = "(?:\(arabicAmountPattern)|\(chineseAmountPattern))"
        
        guard let regex = try? NSRegularExpression(pattern: combinedPattern) else {
            return [text]
        }
        
        let nsText = text as NSString
        let amountMatches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        guard !amountMatches.isEmpty else { return [text] }
        
        let nameExcludeWords: Set<String> = [
            "结婚", "婚礼", "婚宴", "生日", "寿宴", "满月", "周岁", "百岁",
            "升学", "乔迁", "开业", "丧事", "白事", "收到", "送出", "随礼",
            "送礼", "礼金", "还有", "然后", "另外", "以及", "再有"
        ]
        
        var splitPoints: [Int] = []
        
        for match in amountMatches {
            let afterAmount = match.range.location + match.range.length
            if afterAmount >= nsText.length { continue }
            
            // 检查金额后面是否紧跟2-3个中文字符（可能是人名）
            let remaining = nsText.substring(from: afterAmount)
            let namePattern = #"^([\u4e00-\u9fa5]{2,3})"#
            if let nameRegex = try? NSRegularExpression(pattern: namePattern),
               let nameMatch = nameRegex.firstMatch(in: remaining, range: NSRange(location: 0, length: (remaining as NSString).length)),
               let nameRange = Range(nameMatch.range(at: 1), in: remaining) {
                let potentialName = String(remaining[nameRange])
                if !nameExcludeWords.contains(potentialName) && !containsChineseNumber(potentialName) {
                    splitPoints.append(afterAmount)
                }
            }
        }
        
        guard !splitPoints.isEmpty else { return [text] }
        
        var segments: [String] = []
        var lastStart = 0
        for point in splitPoints {
            if point > lastStart {
                let segment = nsText.substring(with: NSRange(location: lastStart, length: point - lastStart))
                    .trimmingCharacters(in: .whitespaces)
                if !segment.isEmpty {
                    segments.append(segment)
                }
            }
            lastStart = point
        }
        let remaining = nsText.substring(from: lastStart).trimmingCharacters(in: .whitespaces)
        if !remaining.isEmpty {
            segments.append(remaining)
        }
        
        return segments.isEmpty ? [text] : segments
    }
    
    // MARK: - 各字段解析
    
    /// 解析方向：sent / received
    private func parseDirection(_ text: String) -> String? {
        // 优先匹配长关键词
        let receivedKeywords = ["收到", "接到"]
        for keyword in receivedKeywords {
            if text.contains(keyword) {
                return "received"
            }
        }
        
        let sentKeywords = ["随礼", "送礼", "赠送", "送", "给", "随", "赠"]
        for keyword in sentKeywords {
            if text.contains(keyword) {
                return "sent"
            }
        }
        
        // 单独的"收"要排在后面，避免误匹配"收到"的"收"
        if text.contains("收") {
            return "received"
        }
        
        return nil
    }
    
    /// 解析联系人姓名（改进版：上下文感知，避免贪婪匹配错误）
    private func parseContactName(_ text: String) -> String? {
        // 所有需要排除的关键词（事件、方向、金额相关词）
        let excludeWords: Set<String> = [
            "结婚", "婚礼", "婚宴", "生日", "寿宴", "满月", "周岁", "百岁", "百日", "百天",
            "升学", "乔迁", "开业", "丧事", "白事", "葬礼",
            "收到", "送出", "随礼", "送礼", "礼金", "赠送",
            "新生", "端午", "中秋", "春节", "过年",
            "一百", "两百", "三百", "四百", "五百", "六百", "七百", "八百", "九百",
            "一千", "两千", "三千", "四千", "五千", "六千", "七千", "八千", "九千",
            "一万", "两万", "三万", "还有", "然后", "另外"
        ]
        
        // 事件关键词（用于定位姓名位置 - 姓名一般出现在事件关键词之前）
        let eventKeywords = ["结婚", "婚礼", "婚宴", "生日", "寿宴", "满月", "满月酒",
                             "周岁", "百岁", "百日", "百天", "升学", "乔迁", "开业",
                             "开业典礼", "丧事", "白事", "葬礼",
                             "随礼", "送礼", "礼金"]
        
        // 策略1: 在事件关键词前面查找姓名
        for keyword in eventKeywords {
            if let keywordRange = text.range(of: keyword) {
                let beforeEvent = String(text[text.startIndex..<keywordRange.lowerBound])
                if !beforeEvent.isEmpty {
                    // 从末尾提取2-4个中文字符作为姓名
                    let namePattern = #"([\u4e00-\u9fa5]{2,4})$"#
                    if let regex = try? NSRegularExpression(pattern: namePattern),
                       let match = regex.firstMatch(in: beforeEvent, range: NSRange(beforeEvent.startIndex..., in: beforeEvent)),
                       let nameRange = Range(match.range(at: 1), in: beforeEvent) {
                        let candidate = String(beforeEvent[nameRange])
                        // 如果候选词超过2个字，尝试截取后2-3个字（避免 "送给张三" 匹配 "给张三"）
                        let name = trimToName(candidate, excludeWords: excludeWords)
                        if let name = name {
                            return name
                        }
                    }
                }
            }
        }
        
        // 策略2: 在"给"、"送给"后面找姓名
        let prefixKeywords = ["送给", "给"]
        for keyword in prefixKeywords {
            if let keywordRange = text.range(of: keyword) {
                let afterKeyword = String(text[keywordRange.upperBound...])
                let namePattern = #"^([\u4e00-\u9fa5]{2,4})"#
                if let regex = try? NSRegularExpression(pattern: namePattern),
                   let match = regex.firstMatch(in: afterKeyword, range: NSRange(afterKeyword.startIndex..., in: afterKeyword)),
                   let nameRange = Range(match.range(at: 1), in: afterKeyword) {
                    let candidate = String(afterKeyword[nameRange])
                    let name = trimToName(candidate, excludeWords: excludeWords)
                    if let name = name {
                        return name
                    }
                }
            }
        }
        
        // 策略3: 在"收到"前面或后面找姓名
        if let receivedRange = text.range(of: "收到") {
            // 收到前面
            let before = String(text[text.startIndex..<receivedRange.lowerBound])
            if !before.isEmpty {
                if let regex = try? NSRegularExpression(pattern: #"([\u4e00-\u9fa5]{2,4})$"#),
                   let match = regex.firstMatch(in: before, range: NSRange(before.startIndex..., in: before)),
                   let nameRange = Range(match.range(at: 1), in: before) {
                    let candidate = String(before[nameRange])
                    let name = trimToName(candidate, excludeWords: excludeWords)
                    if let name = name {
                        return name
                    }
                }
            }
            // 收到后面
            let after = String(text[receivedRange.upperBound...])
            if !after.isEmpty {
                if let regex = try? NSRegularExpression(pattern: #"^([\u4e00-\u9fa5]{2,4})"#),
                   let match = regex.firstMatch(in: after, range: NSRange(after.startIndex..., in: after)),
                   let nameRange = Range(match.range(at: 1), in: after) {
                    let candidate = String(after[nameRange])
                    let name = trimToName(candidate, excludeWords: excludeWords)
                    if let name = name {
                        return name
                    }
                }
            }
        }
        
        // 策略4: 回退 - 扫描文本中所有2-3字中文词，返回第一个非排除词
        let pattern = #"[\u4e00-\u9fa5]{2,3}"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let word = String(text[range])
                    if !excludeWords.contains(word) && !containsChineseNumber(word) {
                        return word
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 从候选词中提取有效姓名（处理贪婪匹配导致的过长词）
    private func trimToName(_ candidate: String, excludeWords: Set<String>) -> String? {
        // 如果候选词本身不含排除词且不含中文数字，直接返回
        if !excludeWords.contains(candidate) && !containsChineseNumber(candidate) {
            // 但如果超过3个字，尝试进一步截短（常见中文姓名2-3字）
            if candidate.count > 3 {
                // 尝试取后3个字
                let suffix3 = String(candidate.suffix(3))
                if !excludeWords.contains(suffix3) && !containsChineseNumber(suffix3) {
                    return suffix3
                }
                // 尝试取后2个字
                let suffix2 = String(candidate.suffix(2))
                if !excludeWords.contains(suffix2) && !containsChineseNumber(suffix2) {
                    return suffix2
                }
            }
            return candidate
        }
        
        // 候选词包含排除词，尝试截取有效部分
        // 如 "张三结婚" → 尝试 "张三"
        for length in [2, 3] {
            if candidate.count > length {
                let prefix = String(candidate.prefix(length))
                if !excludeWords.contains(prefix) && !containsChineseNumber(prefix) {
                    return prefix
                }
            }
        }
        
        return nil
    }
    
    /// 检查字符串是否包含中文数字
    private func containsChineseNumber(_ text: String) -> Bool {
        let chineseNumbers: Set<Character> = [
            "零", "一", "二", "三", "四", "五", "六", "七", "八", "九",
            "十", "百", "千", "万", "两",
            "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖",
            "拾", "佰", "仟", "萬"
        ]
        return text.contains(where: { chineseNumbers.contains($0) })
    }
    
    /// 解析金额（改进版：处理数字分隔符）
    private func parseAmount(_ text: String) -> Double? {
        // 预处理：移除数字中的千位分隔符
        let cleanedText = removeNumberSeparators(text)
        
        // 先尝试解析阿拉伯数字
        let arabicPattern = #"(\d+\.?\d*)\s*[万千百十]?\s*[元圆块钱]?"#
        if let regex = try? NSRegularExpression(pattern: arabicPattern, options: []),
           let match = regex.firstMatch(in: cleanedText, options: [], range: NSRange(cleanedText.startIndex..., in: cleanedText)),
           let amountRange = Range(match.range(at: 1), in: cleanedText) {
            if let amount = Double(String(cleanedText[amountRange])) {
                // 检查是否有单位
                let unitRange = Range(match.range, in: cleanedText)!
                let fullMatch = String(cleanedText[unitRange])
                
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
        return parseChineseAmount(cleanedText)
    }
    
    /// 解析中文金额
    private func parseChineseAmount(_ text: String) -> Double? {
        // 提取包含数字的部分（含"两"字，如"两千"、"两百"）
        let pattern = #"([零一二三四五六七八九十百千万两壹贰叁肆伍陆柒捌玖拾佰仟萬]+)[元圆块钱]?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              let amountRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        let chineseAmount = String(text[amountRange])
        return ChineseNumberParser.parse(chineseAmount)
    }
    
    /// 解析事件类型（改进版：覆盖更多关键词，返回分类中文名）
    private func parseEventCategory(_ text: String) -> String? {
        // 映射到分类中文名，优先匹配长关键词
        let eventMap: [(keyword: String, category: String)] = [
            ("开业典礼", "其他"),
            ("满月酒", "满月酒"),
            ("金榜题名", "升学"),
            ("结婚", "婚礼"),
            ("婚礼", "婚礼"),
            ("婚宴", "婚礼"),
            ("生日", "生日"),
            ("寿宴", "生日"),
            ("满月", "满月酒"),
            ("周岁", "周岁"),
            ("百岁", "其他"),
            ("百日", "其他"),
            ("百天", "其他"),
            ("升学", "升学"),
            ("考学", "升学"),
            ("乔迁", "乔迁"),
            ("搬家", "乔迁"),
            ("新居", "乔迁"),
            ("开业", "其他"),
            ("丧事", "丧事"),
            ("白事", "丧事"),
            ("葬礼", "丧事"),
            ("新生", "新生儿"),
            ("生孩子", "新生儿"),
            ("春节", "春节"),
            ("过年", "春节"),
            ("中秋", "中秋"),
            ("端午", "端午"),
            ("升职", "升职"),
            ("晋升", "升职"),
        ]
        
        for entry in eventMap {
            if text.contains(entry.keyword) {
                return entry.category
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
