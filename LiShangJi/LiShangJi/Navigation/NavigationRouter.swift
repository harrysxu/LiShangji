//
//  NavigationRouter.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

// MARK: - 类型安全的导航 ID（避免多个 navigationDestination(for: UUID.self) 冲突）

/// 账本导航 ID
struct BookNavigationID: Hashable {
    let id: UUID
}

/// 记录导航 ID
struct RecordNavigationID: Hashable {
    let id: UUID
}

/// Tab 导航枚举
enum AppTab: String, CaseIterable {
    case home = "首页"
    case interactions = "往来"
    case books = "账本"
    case profile = "我的"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .interactions: return "person.2.fill"
        case .books: return "book.closed.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

/// 路由状态管理
@Observable
class NavigationRouter {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var interactionsPath = NavigationPath()
    var booksPath = NavigationPath()
    var profilePath = NavigationPath()

    /// 显示录入 Sheet
    var showingRecordEntry = false

    /// 显示 OCR 扫描
    var showingOCRScanner = false

    /// 显示语音输入
    var showingVoiceInput = false

    /// 从全局入口请求开始一次语音采集
    var voiceCaptureRequested = false

    /// 显示新建事件 Sheet
    var showingEventEntry = false

    /// 当前选中的账本（用于从录入回到账本详情）
    var selectedBookForEntry: GiftBook?
    var selectedRecordForReturn: GiftRecord?

    /// 重置导航
    func resetToRoot() {
        homePath = NavigationPath()
        interactionsPath = NavigationPath()
        booksPath = NavigationPath()
        profilePath = NavigationPath()
    }
}
