//
//  MainTabView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 主 Tab 导航视图
struct MainTabView: View {
    @State private var router = NavigationRouter()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }

    // MARK: - iPhone 布局（底部 Tab）

    private var compactLayout: some View {
        TabView(selection: $router.selectedTab) {
            Tab("首页", systemImage: "house.fill", value: .home) {
                NavigationStack(path: $router.homePath) {
                    HomeView()
                }
            }

            Tab("账本", systemImage: "book.closed.fill", value: .books) {
                NavigationStack(path: $router.booksPath) {
                    GiftBookListView()
                }
            }

            Tab("统计", systemImage: "chart.bar.fill", value: .statistics) {
                NavigationStack(path: $router.statisticsPath) {
                    StatisticsView()
                }
            }

            Tab("我的", systemImage: "person.fill", value: .profile) {
                NavigationStack(path: $router.profilePath) {
                    SettingsView()
                }
            }
        }
        .tint(Color.theme.primary)
        .environment(router)
        .sheet(isPresented: $router.showingRecordEntry) {
            RecordEntryView(preselectedBook: router.selectedBookForEntry)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .fullScreenCover(isPresented: $router.showingOCRScanner) {
            OCRScanView()
        }
        .sheet(isPresented: $router.showingVoiceInput) {
            VoiceInputView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - iPad 布局（侧边栏 + 详情）

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        router.selectedTab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .listRowBackground(router.selectedTab == tab ? Color.theme.primary.opacity(0.1) : Color.clear)
                    .foregroundStyle(router.selectedTab == tab ? Color.theme.primary : Color.theme.textPrimary)
                }
            }
            .navigationTitle(AppConstants.Brand.appName)
        } detail: {
            switch router.selectedTab {
            case .home:
                NavigationStack(path: $router.homePath) {
                    HomeView()
                }
            case .books:
                NavigationStack(path: $router.booksPath) {
                    GiftBookListView()
                }
            case .statistics:
                NavigationStack(path: $router.statisticsPath) {
                    StatisticsView()
                }
            case .profile:
                NavigationStack(path: $router.profilePath) {
                    SettingsView()
                }
            }
        }
        .tint(Color.theme.primary)
        .environment(router)
        .sheet(isPresented: $router.showingRecordEntry) {
            RecordEntryView(preselectedBook: router.selectedBookForEntry)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .fullScreenCover(isPresented: $router.showingOCRScanner) {
            OCRScanView()
        }
        .sheet(isPresented: $router.showingVoiceInput) {
            VoiceInputView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
