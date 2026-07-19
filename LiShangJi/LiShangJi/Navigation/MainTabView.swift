import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var router = NavigationRouter()
    @State private var notificationEvent: EventReminder?
    @State private var splitViewVisibility: NavigationSplitViewVisibility = .all
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView(columnVisibility: $splitViewVisibility) {
                    List(AppTab.allCases, id: \.self) { tab in
                        Button { router.selectedTab = tab } label: {
                            Label(tab.rawValue, systemImage: tab.icon)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(router.selectedTab == tab ? Color.theme.primary : Color.primary)
                    }
                    .navigationTitle("礼小记")
                } detail: {
                    selectedRoot
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                phoneTabs
            }
        }
        .tint(Color.theme.primary)
        .environment(router)
        .sheet(isPresented: $router.showingRecordEntry) {
            RecordEntryView(preselectedBook: router.selectedBookForEntry, returnSource: router.selectedRecordForReturn)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(12)
        }
        .fullScreenCover(isPresented: $router.showingOCRScanner) { OCRScanView() }
        .sheet(isPresented: $router.showingVoiceInput) {
            VoiceInputView().presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $router.showingEventEntry) {
            EventFormView().presentationDetents([.large]).presentationDragIndicator(.visible).presentationCornerRadius(12)
        }
        .onChange(of: router.showingRecordEntry) { _, showing in
            if !showing { router.selectedBookForEntry = nil; router.selectedRecordForReturn = nil }
        }
        .onAppear {
            if let eventID = NotificationService.shared.consumePendingEventID() {
                openNotificationEvent(eventID)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .lsjNotificationResponse)) { note in
            guard let eventIDString = note.userInfo?["eventID"] as? String,
                  let eventID = UUID(uuidString: eventIDString) else { return }
            openNotificationEvent(eventID)
        }
        .sheet(item: $notificationEvent) { event in
            EventDetailView(event: event)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }

    private var phoneTabs: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) { HomeView() }
                .tabItem { Label("首页", systemImage: "house.fill") }.tag(AppTab.home)
            NavigationStack(path: $router.interactionsPath) { InteractionHubView() }
                .tabItem { Label("往来", systemImage: "person.2.fill") }.tag(AppTab.interactions)
            NavigationStack(path: $router.booksPath) { GiftBookListView() }
                .tabItem { Label("账本", systemImage: "book.closed.fill") }.tag(AppTab.books)
            NavigationStack(path: $router.profilePath) { SettingsView() }
                .tabItem { Label("我的", systemImage: "person.crop.circle.fill") }.tag(AppTab.profile)
        }
    }

    @ViewBuilder
    private var selectedRoot: some View {
        switch router.selectedTab {
        case .home: NavigationStack(path: $router.homePath) { HomeView() }
        case .interactions: NavigationStack(path: $router.interactionsPath) { InteractionHubView() }
        case .books: NavigationStack(path: $router.booksPath) { GiftBookListView() }
        case .profile: NavigationStack(path: $router.profilePath) { SettingsView() }
        }
    }

    @MainActor
    private func openNotificationEvent(_ eventID: UUID) {
        guard let event = try? modelContext.fetch(FetchDescriptor<EventReminder>())
            .first(where: { $0.id == eventID }) else { return }
        router.selectedTab = .interactions
        notificationEvent = event
    }
}
