//
//  LiShangJiApp.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

@main
struct LiShangJiApp: App {
    init() {
        // 注册 UserDefaults 默认值（iCloud 同步默认关闭，用户可手动开启）
        UserDefaults.standard.register(defaults: ["iCloudSyncEnabled": false])
        // 在所有视图创建之前配置 UIKit 外观，确保 TabBar / NavigationBar 背景色统一
        AppearanceConfigurator.configure()
        // 初始化高级版购买管理器（触发 StoreKit 交易监听和权限检查）
        _ = PremiumManager.shared
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GiftBook.self,
            GiftRecord.self,
            Contact.self,
            GiftEvent.self,
            EventReminder.self,
        ])

        // 根据用户偏好决定是否启用 iCloud 同步（默认关闭）
        // 注意：object(forKey:) 返回 nil 表示用户从未设置过，此时默认关闭
        let iCloudEnabled: Bool
        if let value = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool {
            iCloudEnabled = value
        } else {
            iCloudEnabled = false
        }
        let cloudKitDB: ModelConfiguration.CloudKitDatabase = iCloudEnabled ? .automatic : .none

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitDB
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase
    @State private var isLocked = UserDefaults.standard.bool(forKey: "isAppLockEnabled")
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "system"
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasAgreedToTerms {
                    MainTabView()
                        .onAppear {
                            let context = sharedModelContainer.mainContext

                            // 初始化预设事件模板
                            SeedDataService.seedBuiltInEvents(context: context)

                            // 一次性迁移：为已有数据重算缓存聚合字段
                            migrateCachedAggregatesIfNeeded(context: context)

                            // 请求通知权限
                            Task {
                                _ = await NotificationService.shared.requestPermission()
                            }
                        }
                    if isLocked && isAppLockEnabled {
                        LSJBlurOverlay()
                            .onTapGesture {
                                authenticateUser()
                            }
                    }
                } else {
                    OnboardingView(hasAgreedToTerms: $hasAgreedToTerms)
                }
            }
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .preferredColorScheme(preferredColorScheme)
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background, .inactive:
                    if isAppLockEnabled {
                        isLocked = true
                    }
                case .active:
                    if isLocked && isAppLockEnabled {
                        authenticateUser()
                    }
                @unknown default:
                    break
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    /// 一次性迁移：为已有数据重算缓存聚合字段
    private func migrateCachedAggregatesIfNeeded(context: ModelContext) {
        let migrationKey = "didMigrateCachedAggregates_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        do {
            let contacts = try context.fetch(FetchDescriptor<Contact>())
            for contact in contacts {
                contact.recalculateCachedAggregates()
            }

            let books = try context.fetch(FetchDescriptor<GiftBook>())
            for book in books {
                book.recalculateCachedAggregates()
            }

            try context.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            print("缓存聚合迁移失败: \(error)")
        }
    }

    private func authenticateUser() {
        Task {
            let success = await BiometricAuthService.shared.authenticate()
            await MainActor.run {
                if success {
                    withAnimation(AppConstants.Animation.defaultSpring) {
                        isLocked = false
                    }
                }
            }
        }
    }
}
