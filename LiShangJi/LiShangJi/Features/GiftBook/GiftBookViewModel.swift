//
//  GiftBookViewModel.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import Foundation
import SwiftData

/// 账本 ViewModel
@Observable
class GiftBookViewModel {
    var books: [GiftBook] = []
    var archivedBooks: [GiftBook] = []
    var isLoading = false
    var errorMessage: String?

    private let repository = GiftBookRepository()

    /// 加载活跃账本
    func loadBooks(context: ModelContext) {
        do {
            books = try repository.fetchActive(context: context)
            archivedBooks = try repository.fetchArchived(context: context)
            errorMessage = nil
        } catch {
            errorMessage = "加载账本失败: \(error.localizedDescription)"
        }
    }

    /// 创建账本
    func createBook(name: String, icon: String, colorHex: String, context: ModelContext) {
        do {
            try repository.create(name: name, icon: icon, colorHex: colorHex, context: context)
            loadBooks(context: context)
            HapticManager.shared.successNotification()
        } catch {
            errorMessage = "创建账本失败: \(error.localizedDescription)"
            HapticManager.shared.errorNotification()
        }
    }

    /// 归档账本
    func archiveBook(_ book: GiftBook, context: ModelContext) {
        do {
            try repository.archive(book, context: context)
            loadBooks(context: context)
        } catch {
            errorMessage = "归档失败: \(error.localizedDescription)"
        }
    }

    /// 删除账本
    func deleteBook(_ book: GiftBook, context: ModelContext) {
        do {
            try repository.delete(book, context: context)
            loadBooks(context: context)
            HapticManager.shared.warningNotification()
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
    }
}
