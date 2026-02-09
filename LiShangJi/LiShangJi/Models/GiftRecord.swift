//
//  GiftRecord.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

@Model
final class GiftRecord {
    // MARK: - 基本属性
    var id: UUID = UUID()
    var amount: Double = 0.0                       // 金额
    var direction: String = "sent"                 // "sent"(送出) / "received"(收到)
    var recordType: String = "gift"                // "gift"(赠与) / "loan"(借贷)
    var eventName: String = ""                     // 事件名称，如"张三婚礼"
    var eventCategory: String = "wedding"          // 事件类别
    var eventDate: Date = Date()                   // 事件日期
    var note: String = ""                          // 备注
    var contactName: String = ""                   // 独立姓名，不依赖联系人
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - OCR/语音来源标记
    var source: String = "manual"                  // "manual" / "ocr" / "voice"
    @Attribute(.externalStorage)
    var ocrImageData: Data = Data()                // OCR 原图（压缩后存储）

    // MARK: - 借贷专用字段
    var isLoanSettled: Bool = false                 // 借贷是否已结清
    var loanDueDate: Date = Date()                 // 借贷到期日

    // MARK: - 关系
    var book: GiftBook?                            // 所属账本
    var contact: Contact?                          // 关联联系人

    init(amount: Double, direction: String, eventName: String) {
        self.id = UUID()
        self.amount = amount
        self.direction = direction
        self.eventName = eventName
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - 便利计算属性

    /// 方向枚举
    var giftDirection: GiftDirection {
        GiftDirection(rawValue: direction) ?? .sent
    }

    /// 事件类别枚举
    var giftEventCategory: EventCategory {
        EventCategory(rawValue: eventCategory) ?? .other
    }

    /// 记录类型枚举
    var giftRecordType: RecordType {
        RecordType(rawValue: recordType) ?? .gift
    }

    /// 是否为收到
    var isReceived: Bool {
        direction == GiftDirection.received.rawValue
    }

    /// 显示名称：优先使用联系人名称，其次使用独立姓名
    var displayName: String {
        if let name = contact?.name, !name.isEmpty {
            return name
        }
        return contactName.isEmpty ? "未知" : contactName
    }

    /// 来源显示名称
    var sourceDisplayName: String {
        switch source {
        case "ocr": return "OCR 识别"
        case "voice": return "语音输入"
        default: return "手动"
        }
    }
}
