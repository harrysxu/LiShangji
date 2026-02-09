//
//  ICloudSyncView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/8.
//

import SwiftUI
import SwiftData

/// iCloud 同步状态页面
struct ICloudSyncView: View {
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var syncService = ICloudSyncService.shared
    @State private var showDisableAlert = false
    @State private var showEnableAlert = false

    @Environment(\.modelContext) private var modelContext
    @State private var recordsCount: Int = 0
    @State private var contactsCount: Int = 0
    @State private var booksCount: Int = 0
    @State private var eventsCount: Int = 0

    var body: some View {
        List {
            // 同步状态概览
            syncStatusSection

            // 数据统计
            dataOverviewSection

            // 同步开关
            syncToggleSection

            // 同步日志
            syncLogSection

            // 帮助提示
            helpSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .lsjPageBackground()
        .navigationTitle("iCloud 同步")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await syncService.refreshStatus()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundStyle(Color.theme.primary)
                        .rotationEffect(.degrees(syncService.isRefreshing ? 360 : 0))
                        .animation(
                            syncService.isRefreshing
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: syncService.isRefreshing
                        )
                }
                .disabled(syncService.isRefreshing)
            }
        }
        .alert("关闭 iCloud 同步", isPresented: $showDisableAlert) {
            Button("取消", role: .cancel) {
                iCloudSyncEnabled = true
            }
            Button("关闭并重启", role: .destructive) {
                iCloudSyncEnabled = false
            }
        } message: {
            Text("关闭后数据仅保存在本地设备，不再同步到 iCloud。需要重新启动应用以使更改生效。")
        }
        .alert("开启 iCloud 同步", isPresented: $showEnableAlert) {
            Button("取消", role: .cancel) {
                iCloudSyncEnabled = false
            }
            Button("开启并重启") {
                iCloudSyncEnabled = true
            }
        } message: {
            Text("开启后数据将自动同步到 iCloud，在您的所有设备间保持一致。需要重新启动应用以使更改生效。")
        }
        .onAppear {
            loadCounts()
            Task {
                await syncService.refreshStatus()
            }
        }
    }

    /// 使用轻量 fetchCount 获取各实体数量
    private func loadCounts() {
        do {
            recordsCount = try modelContext.fetchCount(FetchDescriptor<GiftRecord>())
            contactsCount = try modelContext.fetchCount(FetchDescriptor<Contact>())
            booksCount = try modelContext.fetchCount(FetchDescriptor<GiftBook>())
            eventsCount = try modelContext.fetchCount(FetchDescriptor<EventReminder>())
        } catch {
            // 静默失败，保持 0
        }
    }

    // MARK: - 同步状态概览

    private var syncStatusSection: some View {
        Section {
            VStack(spacing: AppConstants.Spacing.lg) {
                // 状态图标
                ZStack {
                    Circle()
                        .fill(syncService.syncStatus.color.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Image(systemName: syncService.syncStatus.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(syncService.syncStatus.color)
                        .symbolEffect(.pulse, isActive: syncService.syncStatus == .syncing)
                }

                // 状态文字
                VStack(spacing: AppConstants.Spacing.xs) {
                    Text(syncService.syncStatus.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(Color.theme.textPrimary)

                    if let lastSync = syncService.lastSyncDate {
                        Text("上次同步: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }

                    if case .error(let msg) = syncService.syncStatus {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(Color.theme.warning)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppConstants.Spacing.lg)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.Spacing.xl)
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 数据统计

    private var dataOverviewSection: some View {
        Section {
            dataRow(icon: "book.closed.fill", title: "账本", count: booksCount, color: Color.theme.primary)
            dataRow(icon: "doc.text.fill", title: "记录", count: recordsCount, color: Color.theme.info)
            dataRow(icon: "person.2.fill", title: "联系人", count: contactsCount, color: Color.theme.received)
            dataRow(icon: "bell.badge.fill", title: "事件提醒", count: eventsCount, color: Color.theme.warning)
        } header: {
            Text("同步数据概览")
        } footer: {
            if iCloudSyncEnabled {
                Text("以上数据已通过 iCloud 在您的设备间同步")
            } else {
                Text("iCloud 同步已关闭，数据仅保存在本地")
            }
        }
        .listRowBackground(Color.theme.card)
    }

    private func dataRow(icon: String, title: String, count: Int, color: Color) -> some View {
        HStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(.body)
                .foregroundStyle(Color.theme.textPrimary)

            Spacer()

            Text("\(count)")
                .font(.body.monospacedDigit().bold())
                .foregroundStyle(Color.theme.textPrimary)

            if iCloudSyncEnabled {
                Image(systemName: "icloud.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.theme.received.opacity(0.6))
            }
        }
    }

    // MARK: - 同步开关

    private var syncToggleSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { iCloudSyncEnabled },
                set: { newValue in
                    if newValue {
                        showEnableAlert = true
                    } else {
                        showDisableAlert = true
                    }
                }
            )) {
                HStack(spacing: AppConstants.Spacing.md) {
                    Image(systemName: "icloud.fill")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud 同步")
                            .font(.body)
                            .foregroundStyle(Color.theme.textPrimary)
                        Text(iCloudSyncEnabled ? "数据自动同步到 iCloud" : "数据仅保存在本地")
                            .font(.caption)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                }
            }
            .tint(Color.theme.primary)
        } footer: {
            Text("切换同步状态需要重启应用才能生效")
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 同步日志

    private var syncLogSection: some View {
        Section {
            if syncService.syncEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AppConstants.Spacing.sm) {
                        Image(systemName: "text.page.slash")
                            .font(.title3)
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                        Text("暂无同步记录")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .padding(.vertical, AppConstants.Spacing.lg)
                    Spacer()
                }
            } else {
                ForEach(syncService.syncEvents) { event in
                    HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
                        Image(systemName: event.type.icon)
                            .font(.caption)
                            .foregroundStyle(event.type.color)
                            .frame(width: 20, alignment: .center)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.message)
                                .font(.subheadline)
                                .foregroundStyle(Color.theme.textPrimary)
                                .lineLimit(2)

                            Text(event.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(Color.theme.textSecondary)
                        }

                        Spacer()
                    }
                }
            }
        } header: {
            HStack {
                Text("同步日志")
                Spacer()
                if !syncService.syncEvents.isEmpty {
                    Button("清除") {
                        withAnimation {
                            syncService.syncEvents.removeAll()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                }
            }
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 帮助提示

    private var helpSection: some View {
        Section {
            helpRow(icon: "questionmark.circle.fill", title: "同步未生效？", detail: "请确保已登录 iCloud 并开启了 iCloud Drive")
            helpRow(icon: "wifi.slash", title: "同步速度慢？", detail: "请检查网络连接，首次同步可能需要较长时间")
            helpRow(icon: "arrow.triangle.2.circlepath", title: "数据不一致？", detail: "请确保所有设备已更新到最新版本")
            helpRow(icon: "lock.shield.fill", title: "数据安全", detail: "所有数据通过 Apple iCloud 加密传输，仅您本人可访问")
        } header: {
            Text("常见问题")
        }
        .listRowBackground(Color.theme.card)
    }

    private func helpRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.theme.info)
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.theme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ICloudSyncView()
    }
}
