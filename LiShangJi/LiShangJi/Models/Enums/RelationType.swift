//
//  RelationType.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

// MARK: - 关系类型
enum RelationType: String, CaseIterable, Codable {
    case family = "family"           // 亲戚
    case colleague = "colleague"     // 同事
    case classmate = "classmate"     // 同学
    case friend = "friend"           // 朋友
    case neighbor = "neighbor"       // 邻居
    case business = "business"       // 商务
    case other = "other"             // 其他

    var displayName: String {
        switch self {
        case .family: return "亲戚"
        case .colleague: return "同事"
        case .classmate: return "同学"
        case .friend: return "朋友"
        case .neighbor: return "邻居"
        case .business: return "商务"
        case .other: return "其他"
        }
    }

    var icon: String {
        switch self {
        case .family: return "figure.and.child.holdinghands"
        case .colleague: return "briefcase.fill"
        case .classmate: return "book.fill"
        case .friend: return "person.2.fill"
        case .neighbor: return "house.and.flag.fill"
        case .business: return "building.2.fill"
        case .other: return "person.fill.questionmark"
        }
    }
}
