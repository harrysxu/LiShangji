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

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack(path: $router.booksPath) {
                GiftBookListView()
            }
            .tabItem {
                Label("账本", systemImage: "book.closed.fill")
            }
            .tag(AppTab.books)

            NavigationStack(path: $router.statisticsPath) {
                StatisticsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(AppTab.statistics)

            NavigationStack(path: $router.profilePath) {
                SettingsView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(AppTab.profile)
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
        .sheet(isPresented: $router.showingEventEntry) {
            EventFormView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }
}
