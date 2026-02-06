//
//  GiftBookRepositoryProtocol.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 账本数据访问协议
protocol GiftBookRepositoryProtocol {
    func fetchAll(context: ModelContext) throws -> [GiftBook]
    func fetchActive(context: ModelContext) throws -> [GiftBook]
    func fetchArchived(context: ModelContext) throws -> [GiftBook]
    func create(name: String, icon: String, colorHex: String, context: ModelContext) throws -> GiftBook
    func update(_ book: GiftBook, context: ModelContext) throws
    func archive(_ book: GiftBook, context: ModelContext) throws
    func delete(_ book: GiftBook, context: ModelContext) throws
}
