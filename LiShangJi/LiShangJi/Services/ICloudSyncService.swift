//
//  ICloudSyncService.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/8.
//

import Foundation
import CloudKit
import Combine
import SwiftUI

/// iCloud 同步状态枚举
enum ICloudSyncStatus: Equatable {
    case syncing        // 同步中
    case synced         // 已同步
    case error(String)  // 同步出错
    case disabled       // 未启用
    case noAccount      // 未登录 iCloud
    case restricted     // 受限
    case unknown        // 未知

    var displayName: String {
        switch self {
        case .syncing: return "同步中..."
        case .synced: return "已同步"
        case .error: return "同步异常"
        case .disabled: return "未启用"
        case .noAccount: return "未登录 iCloud"
        case .restricted: return "受限"
        case .unknown: return "检查中..."
        }
    }

    var icon: String {
        switch self {
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.icloud.fill"
        case .error: return "exclamationmark.icloud.fill"
        case .disabled: return "icloud.slash.fill"
        case .noAccount: return "person.crop.circle.badge.questionmark.fill"
        case .restricted: return "lock.icloud.fill"
        case .unknown: return "icloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .syncing: return .blue
        case .synced: return Color.theme.received
        case .error: return Color.theme.warning
        case .disabled: return Color.theme.textSecondary
        case .noAccount: return Color.theme.warning
        case .restricted: return Color.theme.textSecondary
        case .unknown: return Color.theme.textSecondary
        }
    }
}

/// iCloud 同步事件记录
struct SyncEvent: Identifiable {
    let id = UUID()
    let date: Date
    let type: SyncEventType
    let message: String

    enum SyncEventType {
        case info
        case success
        case warning
        case error

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .info: return Color.theme.info
            case .success: return Color.theme.received
            case .warning: return Color.theme.warning
            case .error: return Color.theme.primary
            }
        }
    }
}

/// iCloud 同步服务 —— 监控 CloudKit 同步状态
@Observable
class ICloudSyncService {
    static let shared = ICloudSyncService()

    /// 当前同步状态
    var syncStatus: ICloudSyncStatus = .unknown

    /// iCloud 是否启用
    var isICloudEnabled: Bool {
        UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? false
    }

    /// iCloud 账户状态
    var accountStatus: CKAccountStatus = .couldNotDetermine

    /// 最后同步时间
    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastICloudSyncDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastICloudSyncDate") }
    }

    /// 同步事件日志（最多保留 20 条）
    var syncEvents: [SyncEvent] = []

    /// iCloud 存储使用情况描述
    var storageDescription: String = "检查中..."

    /// 是否正在刷新
    var isRefreshing: Bool = false

    private var notificationObservers: [Any] = []

    private init() {
        setupNotificationObservers()
        if isICloudEnabled {
            Task {
                await checkAccountStatus()
            }
        } else {
            syncStatus = .disabled
            addEvent(.info, message: "iCloud 同步已关闭")
        }
    }

    // MARK: - 公开方法

    /// 手动刷新同步状态
    func refreshStatus() async {
        await MainActor.run {
            isRefreshing = true
        }

        guard isICloudEnabled else {
            await MainActor.run {
                syncStatus = .disabled
                isRefreshing = false
            }
            return
        }

        await checkAccountStatus()

        // 模拟检测同步状态
        if case .noAccount = syncStatus {
            // 未登录就不继续
        } else if case .restricted = syncStatus {
            // 受限不继续
        } else {
            await MainActor.run {
                syncStatus = .syncing
            }
            addEvent(.info, message: "正在检查同步状态...")

            // 尝试执行一次 CloudKit 操作来验证连接
            await verifySyncConnection()
        }

        await MainActor.run {
            isRefreshing = false
        }
    }

    // MARK: - 私有方法

    /// 设置通知监听
    private func setupNotificationObservers() {
        // 监听 CloudKit 远程通知（数据变更）
        let importObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.lastSyncDate = Date()
            self.syncStatus = .synced
            self.addEvent(.success, message: "收到远程数据变更，已同步")
        }
        notificationObservers.append(importObserver)

        // 监听 iCloud 账户变更
        let accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.checkAccountStatus()
            }
        }
        notificationObservers.append(accountObserver)
    }

    /// 检查 iCloud 账户状态
    private func checkAccountStatus() async {
        do {
            let status = try await CKContainer(identifier: "iCloud.com.xxl.LiShangJi").accountStatus()
            await MainActor.run {
                self.accountStatus = status
                switch status {
                case .available:
                    if self.syncStatus != .synced && self.syncStatus != .syncing {
                        self.syncStatus = .synced
                        self.addEvent(.success, message: "iCloud 账户正常，同步已就绪")
                    }
                case .noAccount:
                    self.syncStatus = .noAccount
                    self.addEvent(.warning, message: "未登录 iCloud 账户")
                case .restricted:
                    self.syncStatus = .restricted
                    self.addEvent(.warning, message: "iCloud 访问受限")
                case .couldNotDetermine:
                    self.syncStatus = .unknown
                    self.addEvent(.warning, message: "无法确定 iCloud 账户状态")
                case .temporarilyUnavailable:
                    self.syncStatus = .error("iCloud 暂时不可用")
                    self.addEvent(.warning, message: "iCloud 暂时不可用，请稍后重试")
                @unknown default:
                    self.syncStatus = .unknown
                    self.addEvent(.info, message: "未知的账户状态")
                }
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
                self.addEvent(.error, message: "检查账户失败: \(error.localizedDescription)")
            }
        }
    }

    /// 验证同步连接
    private func verifySyncConnection() async {
        let container = CKContainer(identifier: "iCloud.com.xxl.LiShangJi")
        do {
            // 尝试获取用户记录 ID 以验证连接
            _ = try await container.userRecordID()
            await MainActor.run {
                self.syncStatus = .synced
                self.lastSyncDate = Date()
                self.addEvent(.success, message: "iCloud 连接正常，同步功能可用")
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
                self.addEvent(.error, message: "连接验证失败: \(error.localizedDescription)")
            }
        }
    }

    /// 添加同步事件到日志
    private func addEvent(_ type: SyncEvent.SyncEventType, message: String) {
        let event = SyncEvent(date: Date(), type: type, message: message)
        Task { @MainActor in
            syncEvents.insert(event, at: 0)
            // 保留最近 20 条
            if syncEvents.count > 20 {
                syncEvents = Array(syncEvents.prefix(20))
            }
        }
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
