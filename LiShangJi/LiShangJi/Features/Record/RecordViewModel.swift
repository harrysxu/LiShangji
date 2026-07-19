//
//  RecordViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 记录 ViewModel
@Observable
class RecordViewModel {
    // 表单数据
    var amount: String = ""
    var direction: GiftDirection = .sent
    var contactName: String = ""
    var selectedContact: Contact?
    var eventName: String = ""
    var selectedCategoryName: String = "婚礼"
    var eventDate: Date = Date()
    var selectedBook: GiftBook?
    var note: String = ""
    var recordType: RecordType = .gift
    var familySideCode = "unspecified"
    var reciprocitySource: GiftRecord?

    // 联系人搜索
    var contactSuggestions: [Contact] = []

    // 状态
    var errorMessage: String?
    var isSaved = false

    private let recordCommands = RecordCommandService()
    private let contactRepository = ContactRepository()

    /// 计算解析后的金额
    var parsedAmount: Double {
        Double(amount) ?? 0
    }

    /// 搜索联系人
    func searchContacts(query: String, context: ModelContext) {
        guard !query.isEmpty else {
            contactSuggestions = []
            return
        }
        do {
            contactSuggestions = try contactRepository.search(query: query, context: context)
        } catch {
            contactSuggestions = []
        }
    }

    /// 选择联系人
    func selectContact(_ contact: Contact) {
        selectedContact = contact
        contactName = contact.name
        contactSuggestions = []
    }

    /// 清除已选联系人
    func clearSelectedContact() {
        selectedContact = nil
        contactName = ""
        contactSuggestions = []
    }

    /// 保存记录
    func saveRecord(context: ModelContext) -> Bool {
        let trimmedAmount = parsedAmount
        guard trimmedAmount > 0 else {
            errorMessage = "请输入金额"
            return false
        }

        let trimmedName = contactName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "请输入联系人"
            return false
        }

        do {
            // 生成事件名称
            let finalEventName = eventName.isEmpty
                ? "\(trimmedName)\(selectedCategoryName)"
                : eventName

            // 创建记录
            try recordCommands.create(RecordDraft(
                amount: trimmedAmount,
                direction: direction,
                contactName: trimmedName,
                eventName: finalEventName,
                eventCategory: selectedCategoryName,
                eventDate: eventDate,
                note: note,
                recordType: recordType,
                familySideCode: familySideCode,
                contact: selectedContact,
                book: selectedBook,
                reciprocitySource: reciprocitySource
            ), context: context)

            isSaved = true
            HapticManager.shared.successNotification()
            return true
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            HapticManager.shared.errorNotification()
            return false
        }
    }

    /// 重置表单
    func reset() {
        amount = ""
        direction = .sent
        contactName = ""
        selectedContact = nil
        eventName = ""
        selectedCategoryName = "婚礼"
        eventDate = Date()
        note = ""
        errorMessage = nil
        isSaved = false
    }
}
