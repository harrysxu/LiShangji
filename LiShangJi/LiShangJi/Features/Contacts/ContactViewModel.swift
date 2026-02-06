//
//  ContactViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 联系人 ViewModel
@Observable
class ContactViewModel {
    // MARK: - 筛选状态（View 通过 @Query 获取数据，ViewModel 只管理筛选状态）
    var searchQuery: String = ""
    var selectedRelation: RelationType? = nil
    var errorMessage: String?

    private let repository = ContactRepository()

    /// 删除联系人
    func deleteContact(_ contact: Contact, context: ModelContext) {
        do {
            try repository.delete(contact, context: context)
            HapticManager.shared.warningNotification()
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
    }
}
