//
//  HomeView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 首页 - 人情仪表盘
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @State private var viewModel = HomeViewModel()
    @State private var showingAllRecords = false
    @State private var showingEventList = false
    @State private var showPurchaseView = false

    // 语音录入相关状态
    @StateObject private var voiceService = VoiceRecordingService.shared
    @State private var isVoiceRecording = false
    @State private var showPermissionAlert = false
    @State private var voiceErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 页面标题
                HStack(alignment: .bottom) {
                    Text("首页")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                }
                .padding(.top, AppConstants.Spacing.sm)

                // 收支概览卡片
                DashboardCardView(
                    totalReceived: viewModel.totalReceived,
                    totalSent: viewModel.totalSent
                )

                // 快捷操作
                quickActions

                // 即将到来的事件
                upcomingEventsSection

                // 最近记录
                recentRecordsSection
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            viewModel.loadData(context: modelContext)
        }
        .onAppear {
            viewModel.loadData(context: modelContext)
        }
        .navigationDestination(isPresented: $showingAllRecords) {
            AllRecordsListView()
        }
        .navigationDestination(isPresented: $showingEventList) {
            EventListView()
        }
        .overlay(alignment: .bottomTrailing) {
            fabButton
        }
        .overlay {
            if isVoiceRecording {
                voiceRecordingOverlay
            }
        }
        .alert("出错了", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("需要语音识别权限", isPresented: $showPermissionAlert) {
            Button("前往设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请在设置中开启语音识别和麦克风权限，以使用语音记账功能")
        }
        .alert("语音识别错误", isPresented: Binding(
            get: { voiceErrorMessage != nil },
            set: { if !$0 { voiceErrorMessage = nil } }
        )) {
            Button("确定") { voiceErrorMessage = nil }
        } message: {
            Text(voiceErrorMessage ?? "")
        }
        .sheet(isPresented: $showPurchaseView) {
            PurchaseView()
        }
    }

    // MARK: - 快捷操作区

    private var quickActions: some View {
        HStack(spacing: AppConstants.Spacing.md) {
            QuickEntryButton(
                icon: "square.and.pencil",
                title: "记一笔",
                color: Color.theme.primary
            ) {
                router.showingRecordEntry = true
            }

            QuickEntryButton(
                icon: "camera.viewfinder",
                title: "扫一扫",
                color: Color.theme.info
            ) {
                if PremiumManager.shared.isPremium {
                    router.showingOCRScanner = true
                } else {
                    showPurchaseView = true
                }
            }
            .premiumBadge(isPremium: PremiumManager.shared.isPremium)

            voiceInputButton
                .premiumBadge(isPremium: PremiumManager.shared.isPremium)
        }
    }

    // MARK: - 语音输入按钮（按住说话）

    private var voiceInputButton: some View {
        VStack(spacing: AppConstants.Spacing.sm) {
            Image(systemName: isVoiceRecording ? "waveform" : "mic.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(isVoiceRecording ? Color.theme.sent : Color.theme.warning)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
                .symbolEffect(.variableColor, isActive: isVoiceRecording)
                .scaleEffect(isVoiceRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isVoiceRecording)

            Text(isVoiceRecording ? "松开结束" : "按住说话")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isVoiceRecording else { return }
                    startVoiceRecording()
                }
                .onEnded { _ in
                    stopVoiceRecording()
                }
        )
    }

    // MARK: - 录音覆盖层

    private var voiceRecordingOverlay: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: AppConstants.Spacing.xl) {
                // 波纹动画
                ZStack {
                    Circle()
                        .fill(Color.theme.primary.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .scaleEffect(isVoiceRecording ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isVoiceRecording)

                    Circle()
                        .fill(Color.theme.primary.opacity(0.2))
                        .frame(width: 110, height: 110)
                        .scaleEffect(isVoiceRecording ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isVoiceRecording)

                    Circle()
                        .fill(Color.theme.primary)
                        .frame(width: 80, height: 80)

                    Image(systemName: "waveform")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor, isActive: isVoiceRecording)
                }

                Text("正在聆听...")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)

                // 实时识别文本预览
                if !voiceService.recognizedText.isEmpty {
                    Text(voiceService.recognizedText)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppConstants.Spacing.xl)
                        .lineLimit(3)
                }

                Text("松开结束录音")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, AppConstants.Spacing.md)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isVoiceRecording)
    }

    // MARK: - 语音录入方法

    private func startVoiceRecording() {
        // 检查会员
        guard PremiumManager.shared.isPremium else {
            showPurchaseView = true
            return
        }

        let permissionStatus = voiceService.checkPermissionStatus()
        switch permissionStatus {
        case .authorized:
            beginRecording()
        case .notDetermined:
            Task {
                let granted = await voiceService.requestPermission()
                if granted {
                    beginRecording()
                } else {
                    showPermissionAlert = true
                }
            }
        case .denied:
            showPermissionAlert = true
        }
    }

    private func beginRecording() {
        // 清空上次识别结果
        voiceService.recognizedText = ""
        do {
            try voiceService.startRecording()
            HapticManager.shared.mediumImpact()
            withAnimation {
                isVoiceRecording = true
            }
        } catch {
            voiceErrorMessage = "无法启动录音: \(error.localizedDescription)"
        }
    }

    private func stopVoiceRecording() {
        guard isVoiceRecording else { return }

        voiceService.stopRecording()
        HapticManager.shared.lightImpact()
        withAnimation {
            isVoiceRecording = false
        }

        // 有识别文本时弹出结果确认 Sheet
        if !voiceService.recognizedText.isEmpty {
            // 短延迟确保录音状态已清理完毕
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                router.showingVoiceInput = true
            }
        }
    }

    // MARK: - 即将到来的事件

    private var upcomingEventsSection: some View {
        Group {
            if !viewModel.upcomingEvents.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text("即将到来的事件")
                            .font(.headline)
                            .foregroundStyle(Color.theme.textPrimary)
                        Spacer()
                        Button("查看全部") {
                            showingEventList = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.primary)
                        .debounced()
                    }

                    LSJCard {
                        VStack(spacing: 0) {
                            ForEach(viewModel.upcomingEvents) { event in
                                HStack(spacing: AppConstants.Spacing.md) {
                                    Image(systemName: CategoryItem.iconForName(event.eventCategory))
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.primary)
                                        .frame(width: 28, height: 28)
                                        .background(Color.theme.primary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(event.title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color.theme.textPrimary)
                                            .lineLimit(1)
                                        Text(eventDateText(event))
                                            .font(.caption)
                                            .foregroundStyle(Color.theme.textSecondary)
                                    }

                                    Spacer()

                                    let days = event.daysUntilEvent
                                    Text(days == 0 ? "今天" : "\(days)天后")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(days <= 3 ? Color.theme.primary.opacity(0.15) : Color.theme.warning.opacity(0.15))
                                        .foregroundStyle(days <= 3 ? Color.theme.primary : Color.theme.warning)
                                        .clipShape(Capsule())
                                }
                                .padding(.vertical, AppConstants.Spacing.sm)

                                if event.id != viewModel.upcomingEvents.last?.id {
                                    Divider()
                                        .foregroundStyle(Color.theme.divider)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func eventDateText(_ event: EventReminder) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: event.eventDate)
    }

    // MARK: - 最近记录区

    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            HStack {
                Text("最近记录")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Spacer()
                if !viewModel.recentRecords.isEmpty {
                    Button("查看全部") {
                        showingAllRecords = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.primary)
                    .debounced()
                }
            }

            if viewModel.recentRecords.isEmpty {
                LSJEmptyStateView(
                    icon: "book.closed",
                    title: "开始记录你的第一笔人情",
                    subtitle: AppConstants.Brand.slogan,
                    actionTitle: "记录第一笔"
                ) {
                    router.showingRecordEntry = true
                }
                .frame(maxWidth: .infinity)
            } else {
                LSJCard {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.recentRecords, id: \.id) { record in
                            NavigationLink {
                                RecordDetailView(record: record)
                            } label: {
                                RecentRecordRow(record: record)
                            }
                            .buttonStyle(.plain)
                            if record.id != viewModel.recentRecords.last?.id {
                                Divider()
                                    .foregroundStyle(Color.theme.divider)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 悬浮按钮

    private var fabButton: some View {
        Button {
            HapticManager.shared.mediumImpact()
            router.showingRecordEntry = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.theme.primary)
                .clipShape(Circle())
                .shadow(color: Color.theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .debounced()
        .accessibilityIdentifier("fab_add_record")
        .padding(.trailing, AppConstants.Spacing.xl)
        .padding(.bottom, AppConstants.Spacing.xl)
    }
}
