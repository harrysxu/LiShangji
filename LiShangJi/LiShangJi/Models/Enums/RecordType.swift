//
//  RecordType.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

// MARK: - 记录类型
enum RecordType: String, CaseIterable, Codable {
    case gift = "gift"       // 随礼/礼金
    case item = "item"       // 实物礼品
    case favor = "favor"     // 无形人情
    case loan = "loan"       // 借贷

    var displayName: String {
        switch self {
        case .gift:
            return "随礼"
        case .item:
            return "礼品"
        case .favor:
            return "人情"
        case .loan:
            return "借贷"
        }
    }

    var icon: String {
        switch self {
        case .gift:
            return "gift.fill"
        case .item:
            return "shippingbox.fill"
        case .favor:
            return "hands.sparkles.fill"
        case .loan:
            return "banknote.fill"
        }
    }

    var countsInGiftBalanceByDefault: Bool {
        switch self {
        case .gift, .item, .favor:
            return true
        case .loan:
            return false
        }
    }
}
