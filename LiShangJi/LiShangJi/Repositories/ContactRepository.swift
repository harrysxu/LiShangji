//
//  ContactRepository.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 联系人数据访问实现
struct ContactRepository: ContactRepositoryProtocol {

    func fetchAll(context: ModelContext) throws -> [Contact] {
        let descriptor = FetchDescriptor<Contact>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchByRelation(_ relation: String, context: ModelContext) throws -> [Contact] {
        let predicate = #Predicate<Contact> { contact in
            contact.relation == relation
        }
        let descriptor = FetchDescriptor<Contact>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func search(query: String, context: ModelContext) throws -> [Contact] {
        guard !query.isEmpty else {
            return try fetchAll(context: context)
        }
        let predicate = #Predicate<Contact> { contact in
            contact.name.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<Contact>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func create(name: String, relation: String, phone: String, context: ModelContext) throws -> Contact {
        let contact = Contact(name: name, relation: relation)
        contact.phone = phone
        context.insert(contact)
        try context.save()
        return contact
    }

    func update(_ contact: Contact, context: ModelContext) throws {
        contact.updatedAt = Date()
        try context.save()
    }

    func delete(_ contact: Contact, context: ModelContext) throws {
        context.delete(contact)
        try context.save()
    }
}
