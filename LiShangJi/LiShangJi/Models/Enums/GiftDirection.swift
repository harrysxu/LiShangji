//
//  GiftDirection.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

// MARK: - 收送方向
enum GiftDirection: String, CaseIterable, Codable {
    case sent = "sent"           // 送出
    case received = "received"   // 收到

    var displayName: String {
        switch self {
        case .sent: return "送出"
        case .received: return "收到"
        }
    }

    var icon: String {
        switch self {
        case .sent: return "arrow.up.circle.fill"
        case .received: return "arrow.down.circle.fill"
        }
    }
}
