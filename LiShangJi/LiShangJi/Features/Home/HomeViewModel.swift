//
//  HomeViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 首页 ViewModel
@Observable
class HomeViewModel {
    var totalReceived: Double = 0
    var totalSent: Double = 0
    var recentRecords: [GiftRecord] = []
    var errorMessage: String?

    var balance: Double {
        totalReceived - totalSent
    }

    private let recordRepository = GiftRecordRepository()

    /// 加载首页数据
    func loadData(context: ModelContext) {
        do {
            // 获取本月数据
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

            let monthRecords = try recordRepository.fetchByDateRange(from: startOfMonth, to: startOfNextMonth, context: context)

            totalReceived = monthRecords
                .filter { $0.direction == GiftDirection.received.rawValue }
                .reduce(0) { $0 + $1.amount }

            totalSent = monthRecords
                .filter { $0.direction == GiftDirection.sent.rawValue }
                .reduce(0) { $0 + $1.amount }

            // 获取最近记录
            recentRecords = try recordRepository.fetchRecent(limit: 10, context: context)

            errorMessage = nil
        } catch {
            errorMessage = "加载数据失败: \(error.localizedDescription)"
        }
    }
}
