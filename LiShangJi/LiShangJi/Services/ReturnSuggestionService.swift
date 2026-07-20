//
//  ReturnSuggestionService.swift
//  LiShangJi
//
//  基于个人历史记录的回礼建议
//

import Foundation

enum ReturnActionStatus: String {
    case none = "无需处理"
    case watch = "建议留意"
    case shouldReturn = "建议回礼"
    case loanPending = "借贷待结清"
}

struct ReturnSuggestion {
    let status: ReturnActionStatus
    let suggestedAmount: Double?
    let latestReceived: GiftRecord?
    let latestSent: GiftRecord?
    let message: String
}

final class ReturnSuggestionService {
    static let shared = ReturnSuggestionService()
    private init() {}

    func suggestion(for contact: Contact) -> ReturnSuggestion {
        let records = (contact.records ?? []).sorted { $0.eventDate > $1.eventDate }
        let giftRecords = records.filter { $0.giftRecordType != .loan }
        let latestReceived = giftRecords.first { $0.direction == GiftDirection.received.rawValue }
        let latestSent = giftRecords.first { $0.direction == GiftDirection.sent.rawValue }
        let pendingLoan = records.contains { $0.giftRecordType == .loan && !$0.isLoanSettled }

        if pendingLoan {
            return ReturnSuggestion(
                status: .loanPending,
                suggestedAmount: nil,
                latestReceived: latestReceived,
                latestSent: latestSent,
                message: "存在未结清借贷，建议优先处理借贷关系。"
            )
        }

        guard let latestReceived else {
            return ReturnSuggestion(
                status: .none,
                suggestedAmount: nil,
                latestReceived: nil,
                latestSent: latestSent,
                message: "暂无收到记录，当前没有明确回礼压力。"
            )
        }

        if let latestSent, latestSent.eventDate >= latestReceived.eventDate {
            return ReturnSuggestion(
                status: .none,
                suggestedAmount: nil,
                latestReceived: latestReceived,
                latestSent: latestSent,
                message: "最近一次往来已回礼，可继续留意后续事件。"
            )
        }

        let similarRecords = giftRecords
            .filter { $0.eventCategory == latestReceived.eventCategory && $0.giftStatsAmount > 0 }
            .prefix(3)
            .map(\.giftStatsAmount)
        let baseAmount = median(Array(similarRecords)) ?? latestReceived.giftStatsAmount
        let amount = nearestLuckyAmount(baseAmount)

        return ReturnSuggestion(
            status: contact.balance > 0 ? .shouldReturn : .watch,
            suggestedAmount: amount,
            latestReceived: latestReceived,
            latestSent: latestSent,
            message: "建议金额仅基于你和该联系人的历史记录参考。"
        )
    }

    private func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    private func nearestLuckyAmount(_ amount: Double) -> Double {
        let options: [Double] = [200, 500, 600, 666, 800, 888, 1000, 1200, 1666, 1888, 2000, 2600, 2888, 3000, 5000, 6600, 8888, 10000]
        return options.first { $0 >= amount } ?? amount.rounded(.up)
    }
}
