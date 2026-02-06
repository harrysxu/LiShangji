//
//  ContactRepositoryProtocol.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 联系人数据访问协议
protocol ContactRepositoryProtocol {
    func fetchAll(context: ModelContext) throws -> [Contact]
    func fetchByRelation(_ relation: String, context: ModelContext) throws -> [Contact]
    func search(query: String, context: ModelContext) throws -> [Contact]
    func create(name: String, relation: String, phone: String, context: ModelContext) throws -> Contact
    func update(_ contact: Contact, context: ModelContext) throws
    func delete(_ contact: Contact, context: ModelContext) throws
}
