//
//  TestDataGeneratorView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

#if DEBUG

import SwiftUI
import SwiftData

// MARK: - 数据量预设

enum TestDataVolume: String, CaseIterable {
    case small = "少量"
    case medium = "中等"
    case large = "大量"

    var description: String {
        switch self {
        case .small: return "10 联系人 · 3 账本 · 30 条记录"
        case .medium: return "30 联系人 · 6 账本 · 180 条记录"
        case .large: return "50 联系人 · 10 账本 · 600 条记录"
        }
    }

    var config: TestDataGeneratorService.GenerationConfig {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}

// MARK: - 测试数据生成页面

struct TestDataGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // 配置状态
    @State private var selectedVolume: TestDataVolume = .medium
    @State private var monthsRange: Double = 12
    @State private var includeContacts = true
    @State private var includeBooks = true
    @State private var includeRecords = true
    @State private var includeLoanRecords = true
    @State private var includeOCRRecords = true
    @State private var includeVoiceRecords = true

    // 操作状态
    @State private var isGenerating = false
    @State private var showClearConfirmation = false
    @State private var generationResult: TestDataGeneratorService.GenerationResult?
    @State private var showResult = false
    @State private var clearCompleted = false

    var body: some View {
        NavigationStack {
            List {
                // 数据量选择
                volumeSection

                // 时间范围
                timeRangeSection

                // 数据类型开关
                dataTypeSection

                // 操作按钮
                actionSection

                // 生成结果摘要
                if let result = generationResult, showResult {
                    resultSection(result)
                }
            }
            .lsjPageBackground()
            .scrollContentBackground(.hidden)
            .navigationTitle("测试数据生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("确认清除", isPresented: $showClearConfirmation) {
                Button("取消", role: .cancel) {}
                Button("清除所有数据", role: .destructive) {
                    clearData()
                }
            } message: {
                Text("此操作将删除所有联系人、账本、记录和自定义事件数据，内置事件模板会被重新初始化。此操作不可撤销。")
            }
            .alert("清除完成", isPresented: $clearCompleted) {
                Button("确定") {}
            } message: {
                Text("所有数据已清除，内置事件模板已重新初始化。")
            }
        }
    }

    // MARK: - 数据量选择

    private var volumeSection: some View {
        Section {
            Picker("数据量", selection: $selectedVolume) {
                ForEach(TestDataVolume.allCases, id: \.self) { volume in
                    Text(volume.rawValue).tag(volume)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedVolume.description)
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)
        } header: {
            Label("数据量", systemImage: "slider.horizontal.3")
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 时间范围

    private var timeRangeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                HStack {
                    Text("时间跨度")
                    Spacer()
                    Text("过去 \(Int(monthsRange)) 个月")
                        .font(.headline)
                        .foregroundStyle(Color.theme.primary)
                }

                Slider(value: $monthsRange, in: 1...24, step: 1)
                    .tint(Color.theme.primary)

                HStack {
                    Text("1 个月")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.textSecondary)
                    Spacer()
                    Text("24 个月")
                        .font(.caption2)
                        .foregroundStyle(Color.theme.textSecondary)
                }
            }
        } header: {
            Label("时间范围", systemImage: "calendar")
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 数据类型

    private var dataTypeSection: some View {
        Section {
            Toggle(isOn: $includeContacts) {
                Label("联系人（含生日信息）", systemImage: "person.2.fill")
            }
            .tint(Color.theme.primary)

            Toggle(isOn: $includeBooks) {
                Label("账本", systemImage: "book.closed.fill")
            }
            .tint(Color.theme.primary)

            Toggle(isOn: $includeRecords) {
                Label("礼金记录", systemImage: "yensign.circle.fill")
            }
            .tint(Color.theme.primary)

            Toggle(isOn: $includeLoanRecords) {
                Label("借贷记录", systemImage: "banknote.fill")
            }
            .tint(Color.theme.primary)
            .disabled(!includeRecords)

            Toggle(isOn: $includeOCRRecords) {
                Label("OCR 来源记录", systemImage: "camera.viewfinder")
            }
            .tint(Color.theme.primary)
            .disabled(!includeRecords)

            Toggle(isOn: $includeVoiceRecords) {
                Label("语音来源记录", systemImage: "mic.fill")
            }
            .tint(Color.theme.primary)
            .disabled(!includeRecords)
        } header: {
            Label("数据类型", systemImage: "checklist")
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 操作按钮

    private var actionSection: some View {
        Section {
            // 生成按钮
            Button {
                generateData()
            } label: {
                HStack {
                    Spacer()
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                        Text("生成中...")
                            .font(.headline)
                    } else {
                        Image(systemName: "wand.and.stars")
                        Text("生成测试数据")
                            .font(.headline)
                    }
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 6)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppConstants.Radius.sm)
                    .fill(isGenerating ? Color.theme.primary.opacity(0.6) : Color.theme.primary)
            )
            .disabled(isGenerating)

            // 清除按钮
            Button {
                showClearConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "trash.fill")
                    Text("清除所有数据")
                        .font(.headline)
                    Spacer()
                }
                .foregroundStyle(.red)
                .padding(.vertical, 6)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppConstants.Radius.sm)
                    .fill(Color.red.opacity(0.1))
            )
            .disabled(isGenerating)
        } header: {
            Label("操作", systemImage: "gearshape.fill")
        }
    }

    // MARK: - 结果摘要

    private func resultSection(_ result: TestDataGeneratorService.GenerationResult) -> some View {
        Section {
            resultRow(icon: "person.2.fill", title: "联系人", count: result.contactsCreated)
            resultRow(icon: "book.closed.fill", title: "账本", count: result.booksCreated)
            resultRow(icon: "list.bullet.rectangle.fill", title: "记录", count: result.recordsCreated)
        } header: {
            Label("生成结果", systemImage: "checkmark.circle.fill")
        }
        .listRowBackground(Color.theme.card)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func resultRow(icon: String, title: String, count: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.primary)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text("\(count) 条")
                .font(.headline)
                .foregroundStyle(Color.theme.primary)
        }
    }

    // MARK: - 操作方法

    private func generateData() {
        isGenerating = true
        showResult = false
        generationResult = nil

        // 构建配置
        var config = selectedVolume.config
        config.monthsRange = Int(monthsRange)
        config.includeLoanRecords = includeLoanRecords && includeRecords
        config.includeOCRRecords = includeOCRRecords && includeRecords
        config.includeVoiceRecords = includeVoiceRecords && includeRecords

        if !includeContacts {
            config.contactCount = 0
        }
        if !includeBooks {
            config.bookCount = 0
        }
        if !includeRecords {
            config.recordsPerBook = 0
        }

        // 延迟执行以显示加载状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let result = TestDataGeneratorService.generate(config: config, context: modelContext)

            withAnimation(AppConstants.Animation.defaultSpring) {
                generationResult = result
                showResult = true
                isGenerating = false
            }

            HapticManager.shared.notification(type: .success)
        }
    }

    private func clearData() {
        TestDataGeneratorService.clearAllData(context: modelContext)
        generationResult = nil
        showResult = false
        clearCompleted = true
        HapticManager.shared.notification(type: .warning)
    }
}

#Preview {
    TestDataGeneratorView()
}

#endif
