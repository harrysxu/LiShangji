//
//  RecordType.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

// MARK: - 记录类型
enum RecordType: String, CaseIterable, Codable {
    case gift = "gift"       // 赠与（随礼）
    case loan = "loan"       // 借贷

    var displayName: String {
        switch self {
        case .gift: return "随礼"
        case .loan: return "借贷"
        }
    }

    var icon: String {
        switch self {
        case .gift: return "gift.fill"
        case .loan: return "banknote.fill"
        }
    }
}
