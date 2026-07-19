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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = HomeViewModel()
    @State private var showingAllRecords = false
    @State private var showingEventList = false
    @State private var showingStatistics = false
    @State private var showPurchaseView = false

    // 语音录入相关状态
    @StateObject private var voiceService = VoiceRecordingService.shared
    @State private var isVoiceStartPending = false
    @State private var showPermissionAlert = false
    @State private var voiceErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 页面标题
                HStack(alignment: .center) {
                    Text("首页")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                    GlobalAddMenu()
                }
                .padding(.top, AppConstants.Spacing.sm)

                // 即将到来的事件
                upcomingEventsSection

                // 快捷操作
                quickActions

                // 最近记录
                recentRecordsSection

                HStack {
                    Text("本月概览").font(.headline)
                    Spacer()
                    Button("查看分析") { showingStatistics = true }.font(.subheadline)
                }
                DashboardCardView(totalReceived: viewModel.totalReceived, totalSent: viewModel.totalSent)
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.bottom, AppConstants.Spacing.xxxl + 100)
        }
        .lsjPageBackground()
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            viewModel.loadData(context: modelContext)
        }
        .onAppear {
            viewModel.loadData(context: modelContext)
            handleVoiceCaptureRequest()
        }
        .navigationDestination(isPresented: $showingAllRecords) {
            AllRecordsListView()
        }
        .navigationDestination(isPresented: $showingEventList) {
            EventListView()
        }
        .navigationDestination(isPresented: $showingStatistics) {
            StatisticsView()
        }
        .overlay {
            if voiceService.isRecording {
                voiceRecordingOverlay
                    .transition(.opacity)
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
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                cancelVoiceRecording()
            }
        }
        .onChange(of: voiceService.lastError) { _, error in
            if let error {
                voiceErrorMessage = error
            }
        }
        .onChange(of: router.voiceCaptureRequested) { _, requested in
            if requested {
                handleVoiceCaptureRequest()
            }
        }
        .onDisappear {
            cancelVoiceRecording()
        }
    }

    // MARK: - 快捷操作区

    private var quickActions: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: AppConstants.Spacing.sm))
            : AnyLayout(HStackLayout(spacing: AppConstants.Spacing.md))
        return layout {
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

    // MARK: - 语音输入按钮

    private var voiceInputButton: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(HStackLayout(spacing: AppConstants.Spacing.md))
            : AnyLayout(VStackLayout(spacing: AppConstants.Spacing.sm))
        return Button {
            if voiceService.isRecording {
                stopVoiceRecording()
            } else {
                startVoiceRecording()
            }
        } label: {
            layout {
                Image(systemName: voiceService.isRecording ? "waveform" : "mic.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(voiceService.isRecording ? Color.theme.sent : Color.theme.warning)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
                    .symbolEffect(.variableColor, isActive: voiceService.isRecording)
                    .scaleEffect(voiceService.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: voiceService.isRecording)

                Text(voiceInputButtonTitle)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.Spacing.md)
            .background(Color.theme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isVoiceStartPending)
        .accessibilityIdentifier("home_voice_input")
    }

    private var voiceInputButtonTitle: String {
        if isVoiceStartPending { return "准备中..." }
        return voiceService.isRecording ? "点击结束" : "点击开始"
    }

    // MARK: - 录音覆盖层

    private var voiceRecordingOverlay: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)
                .allowsHitTesting(false)

            VStack(spacing: AppConstants.Spacing.xl) {
                // 波纹动画
                ZStack {
                    Circle()
                        .fill(Color.theme.primary.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .scaleEffect(voiceService.isRecording ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: voiceService.isRecording)

                    Circle()
                        .fill(Color.theme.primary.opacity(0.2))
                        .frame(width: 110, height: 110)
                        .scaleEffect(voiceService.isRecording ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: voiceService.isRecording)

                    Circle()
                        .fill(Color.theme.primary)
                        .frame(width: 80, height: 80)

                    Image(systemName: "waveform")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor, isActive: voiceService.isRecording)
                }
                .allowsHitTesting(false)

                Text("正在聆听...")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .allowsHitTesting(false)

                // 实时识别文本预览
                if !voiceService.recognizedText.isEmpty {
                    Text(voiceService.recognizedText)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppConstants.Spacing.xl)
                        .lineLimit(3)
                        .allowsHitTesting(false)
                }

                Text("点击下方按钮结束录音")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, AppConstants.Spacing.md)
                    .allowsHitTesting(false)

                Button {
                    stopVoiceRecording()
                } label: {
                    Label("结束录音", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppConstants.Spacing.xl)
                        .padding(.vertical, AppConstants.Spacing.md)
                        .background(Color.theme.sent)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("voice_stop_button")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: voiceService.isRecording)
    }

    // MARK: - 语音录入方法

    private func startVoiceRecording() {
        // 检查会员
        guard PremiumManager.shared.isPremium else {
            showPurchaseView = true
            return
        }
        guard !voiceService.isRecording, !isVoiceStartPending else { return }

        let permissionStatus = voiceService.checkPermissionStatus()
        switch permissionStatus {
        case .authorized:
            beginRecording()
        case .notDetermined:
            isVoiceStartPending = true
            Task {
                let granted = await voiceService.requestPermission()
                guard isVoiceStartPending else { return }
                isVoiceStartPending = false
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
        guard !voiceService.isRecording else { return }

        // 清空上次识别结果
        voiceService.recognizedText = ""
        voiceService.lastError = nil
        do {
            try voiceService.startRecording()
            HapticManager.shared.mediumImpact()
        } catch {
            isVoiceStartPending = false
            voiceErrorMessage = "无法启动录音: \(error.localizedDescription)"
        }
    }

    private func stopVoiceRecording() {
        guard voiceService.isRecording else { return }

        voiceService.stopRecording()
        HapticManager.shared.lightImpact()

        // 给识别器一点时间提交最后一段转写，再决定是否进入确认页。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if !voiceService.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                router.showingVoiceInput = true
            } else if let error = voiceService.lastError {
                voiceErrorMessage = error
            }
        }
    }

    private func cancelVoiceRecording() {
        isVoiceStartPending = false
        voiceService.stopRecording()
    }

    private func handleVoiceCaptureRequest() {
        guard router.voiceCaptureRequested else { return }
        router.voiceCaptureRequested = false
        startVoiceRecording()
    }

    // MARK: - 即将到来的事件

    private var upcomingEventsSection: some View {
        Group {
            if !viewModel.upcomingEvents.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                    HStack {
                        Text("今天要处理")
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
