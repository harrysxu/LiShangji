import SwiftUI
import SwiftData

@main
struct LiShangJiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var launchState: AppLaunchState = .loading
    @State private var modelContainer: ModelContainer?
    @State private var isPrivacyCovered = false
    @State private var isLocked = UserDefaults.standard.bool(forKey: "isAppLockEnabled")
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "system"
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false

    init() {
        UserDefaults.standard.register(defaults: ["iCloudSyncEnabled": false])
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") {
            UserDefaults.standard.set(!arguments.contains("-ui-testing-onboarding"), forKey: "hasAgreedToTerms")
            UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")
            UserDefaults.standard.set(false, forKey: "isPremiumUnlocked")
        }
        AppearanceConfigurator.configure()
        _ = PremiumManager.shared
        _ = NotificationService.shared
    }

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let modelContainer, launchState == .ready {
                    appContent
                        .modelContainer(modelContainer)
                } else if case let .recoveryRequired(message) = launchState {
                    AppRecoveryView(message: message, retry: bootstrap)
                } else {
                    VStack(spacing: AppConstants.Spacing.lg) {
                        ProgressView()
                        Text(launchState == .migrating ? "正在安全升级数据…" : "正在打开礼小记…")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .preferredColorScheme(preferredColorScheme)
            .task { if modelContainer == nil { bootstrap() } }
            .onChange(of: scenePhase, handleScenePhase)
        }
    }

    private var appContent: some View {
        ZStack {
            if hasAgreedToTerms {
                MainTabView()
                    .onAppear { initializeData() }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"))) { _ in
                        guard let context = modelContainer?.mainContext else { return }
                        SeedDataService.deduplicateCategories(context: context)
                        try? CompatibilityBackfillService.runIfNeeded(context: context)
                    }
            } else {
                OnboardingView(hasAgreedToTerms: $hasAgreedToTerms)
            }

            if isPrivacyCovered || isLocked {
                LSJBlurOverlay()
                    .contentShape(Rectangle())
                    .onTapGesture { if isLocked { authenticateUser() } }
                    .accessibilityLabel(isLocked ? "应用已锁定，轻点解锁" : "隐私保护")
            }
        }
    }

    @MainActor
    private func bootstrap() {
        launchState = .migrating
        do {
            modelContainer = try AppModelContainerFactory.makeContainer()
            launchState = .ready
        } catch {
            modelContainer = nil
            launchState = .recoveryRequired(error.localizedDescription)
        }
    }

    @MainActor
    private func initializeData() {
        guard let context = modelContainer?.mainContext else { return }
        SeedDataService.seedBuiltInCategories(context: context)
        SeedDataService.seedBuiltInEvents(context: context)
        do {
            try CompatibilityBackfillService.runIfNeeded(context: context)
        } catch {
            launchState = .recoveryRequired(error.localizedDescription)
        }

        #if DEBUG
        scheduleNotificationDeliveryTestIfRequested(context: context)
        #endif
    }

    #if DEBUG
    @MainActor
    private func scheduleNotificationDeliveryTestIfRequested(context: ModelContext) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let titleIndex = arguments.firstIndex(of: "-notification-test-event-title"),
              arguments.indices.contains(titleIndex + 1) else { return }

        let eventTitle = arguments[titleIndex + 1]
        let delay: TimeInterval
        if let delayIndex = arguments.firstIndex(of: "-notification-test-delay"),
           arguments.indices.contains(delayIndex + 1) {
            delay = TimeInterval(arguments[delayIndex + 1]) ?? 5
        } else {
            delay = 5
        }

        let events = try? context.fetch(FetchDescriptor<EventReminder>())
        let eventID = events?.first(where: { $0.title == eventTitle })?.id ?? UUID()

        Task {
            _ = await NotificationService.shared.scheduleDeliveryTest(
                eventID: eventID,
                eventTitle: eventTitle,
                delay: delay
            )
        }
    }
    #endif

    private func handleScenePhase(_ oldValue: ScenePhase, _ newValue: ScenePhase) {
        switch newValue {
        case .background, .inactive:
            isPrivacyCovered = true
            if isAppLockEnabled { isLocked = true }
        case .active:
            if isLocked && isAppLockEnabled {
                authenticateUser()
            } else {
                isPrivacyCovered = false
                isLocked = false
            }
        @unknown default:
            break
        }
    }

    private func authenticateUser() {
        Task {
            let success = await BiometricAuthService.shared.authenticate()
            await MainActor.run {
                if success {
                    withAnimation(AppConstants.Animation.defaultSpring) {
                        isLocked = false
                        isPrivacyCovered = false
                    }
                }
            }
        }
    }
}
