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
        // 在所有视图创建之前配置 UIKit 外观，确保 TabBar / NavigationBar 背景色统一
        AppearanceConfigurator.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GiftBook.self,
            GiftRecord.self,
            Contact.self,
            GiftEvent.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
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
    @State private var isLocked = false
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "system"

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
                MainTabView()
                    .onAppear {
                        // 初始化预设事件模板
                        let context = sharedModelContainer.mainContext
                        SeedDataService.seedBuiltInEvents(context: context)

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
            }
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
