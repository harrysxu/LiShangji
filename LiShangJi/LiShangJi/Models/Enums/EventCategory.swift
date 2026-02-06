//
//  EventCategory.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation

// MARK: - 事件类别
enum EventCategory: String, CaseIterable, Codable {
    case wedding = "wedding"               // 婚礼
    case babyBorn = "baby_born"            // 新生儿
    case fullMoon = "full_moon"            // 满月酒
    case firstBirthday = "first_birthday"  // 周岁
    case birthday = "birthday"             // 生日
    case funeral = "funeral"               // 丧事
    case housewarming = "housewarming"     // 乔迁
    case graduation = "graduation"         // 升学
    case promotion = "promotion"           // 升职
    case springFestival = "spring_festival" // 春节
    case midAutumn = "mid_autumn"          // 中秋
    case dragonBoat = "dragon_boat"        // 端午
    case other = "other"                   // 其他

    var displayName: String {
        switch self {
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

    var icon: String {
        switch self {
        case .wedding: return "heart.fill"
        case .babyBorn: return "figure.and.child.holdinghands"
        case .fullMoon: return "moon.fill"
        case .firstBirthday: return "birthday.cake.fill"
        case .birthday: return "gift.fill"
        case .funeral: return "leaf.fill"
        case .housewarming: return "house.fill"
        case .graduation: return "graduationcap.fill"
        case .promotion: return "star.fill"
        case .springFestival: return "fireworks"
        case .midAutumn: return "moon.haze.fill"
        case .dragonBoat: return "sailboat.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
