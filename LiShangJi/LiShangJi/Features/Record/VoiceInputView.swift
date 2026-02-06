//
//  VoiceInputView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 语音记账输入视图
struct VoiceInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceService = VoiceRecordingService.shared
    @State private var showingConfirmation = false
    @State private var editableResult = EditableVoiceResult()
    @State private var showToast = false
    @State private var errorMessage: String?

    @Query(sort: \GiftBook.sortOrder) private var books: [GiftBook]

    var body: some View {
        NavigationStack {
            VStack(spacing: AppConstants.Spacing.xl) {
                Spacer()

                // 语音波形区域
                voiceWaveArea

                // 识别文字显示
                recognizedTextArea

                // 解析结果
                if showingConfirmation {
                    parsedResultForm
                }

                Spacer()

                // 操作按钮
                actionButtons
            }
            .padding(AppConstants.Spacing.lg)
            .lsjPageBackground()
            .navigationTitle("语音记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        voiceService.stopRecording()
                        dismiss()
                    }
                }
            }
            .toast(isPresented: $showToast, message: "记录保存成功")
            .alert("错误", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - 语音波形区域

    private var voiceWaveArea: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.theme.primary.opacity(voiceService.isRecording ? 0.15 : 0.05))
                    .frame(width: 140, height: 140)
                    .scaleEffect(voiceService.isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: voiceService.isRecording)

                Circle()
                    .fill(Color.theme.primary.opacity(voiceService.isRecording ? 0.25 : 0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: voiceService.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.theme.primary)
                    .symbolEffect(.variableColor, isActive: voiceService.isRecording)
            }

            Text(voiceService.isRecording ? "正在聆听..." : "点击开始说话")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
        }
    }

    // MARK: - 识别文字

    private var recognizedTextArea: some View {
        Group {
            if !voiceService.recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Text("识别内容")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text(voiceService.recognizedText)
                        .font(.body)
                        .foregroundStyle(Color.theme.textPrimary)
                        .padding(AppConstants.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
                }
            } else if !voiceService.isRecording {
                VStack(spacing: AppConstants.Spacing.sm) {
                    Text("试试说")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                    Text("「张三结婚随礼一千元」")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.primary)
                    Text("「收到李四婚礼礼金两千」")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.primary)
                }
            }
        }
    }

    // MARK: - 解析结果表单

    private var parsedResultForm: some View {
        LSJCard {
            VStack(spacing: AppConstants.Spacing.md) {
                HStack {
                    Text("解析结果")
                        .font(.headline)
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                }

                // 方向
                Picker("方向", selection: $editableResult.direction) {
                    ForEach(GiftDirection.allCases, id: \.self) { dir in
                        Text(dir.displayName).tag(dir)
                    }
                }
                .pickerStyle(.segmented)

                // 联系人
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.theme.primary)
                    TextField("联系人", text: $editableResult.contactName)
                }

                // 金额
                HStack {
                    Image(systemName: "yensign.circle.fill")
                        .foregroundStyle(Color.theme.primary)
                    TextField("金额", text: $editableResult.amountString)
                        .keyboardType(.decimalPad)
                }

                // 事件类型
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.theme.primary)
                    Picker("事件类型", selection: $editableResult.eventCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            if showingConfirmation {
                LSJButton(title: "保存记录", style: .primary, icon: "checkmark") {
                    saveRecord()
                }

                LSJButton(title: "重新录音", style: .secondary, icon: "arrow.counterclockwise") {
                    resetState()
                }
            } else {
                Button {
                    HapticManager.shared.mediumImpact()
                    toggleRecording()
                } label: {
                    Text(voiceService.isRecording ? "停止录音" : "开始录音")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(voiceService.isRecording ? Color.theme.sent : Color.theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.sm))
                }

                if !voiceService.recognizedText.isEmpty && !voiceService.isRecording {
                    LSJButton(title: "确认并解析", style: .primary, icon: "text.magnifyingglass") {
                        confirmAndParse()
                    }
                }
            }
        }
        .padding(.bottom, AppConstants.Spacing.lg)
    }

    // MARK: - 操作方法

    private func toggleRecording() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            do {
                try voiceService.startRecording()
            } catch {
                errorMessage = "无法启动录音: \(error.localizedDescription)"
            }
        }
    }

    private func confirmAndParse() {
        let result = voiceService.parseNaturalLanguage(voiceService.recognizedText)

        editableResult.contactName = result.contactName ?? ""
        editableResult.amountString = result.amount.map { String(Int($0)) } ?? ""
        editableResult.direction = GiftDirection(rawValue: result.direction ?? "sent") ?? .sent
        editableResult.eventCategory = EventCategory(rawValue: result.eventCategory ?? "other") ?? .other

        showingConfirmation = true
        HapticManager.shared.successNotification()
    }

    private func saveRecord() {
        guard let amount = Double(editableResult.amountString), amount > 0 else {
            errorMessage = "请输入有效金额"
            return
        }
        guard !editableResult.contactName.isEmpty else {
            errorMessage = "请输入联系人"
            return
        }

        let contactRepository = ContactRepository()
        let recordRepository = GiftRecordRepository()

        do {
            // 查找或创建联系人
            let existing = try contactRepository.search(query: editableResult.contactName, context: modelContext)
            let contact = existing.first ?? {
                let c = Contact(name: editableResult.contactName)
                modelContext.insert(c)
                return c
            }()

            let eventName = "\(editableResult.contactName)\(editableResult.eventCategory.displayName)"

            try recordRepository.create(
                amount: amount,
                direction: editableResult.direction.rawValue,
                eventName: eventName,
                eventCategory: editableResult.eventCategory.rawValue,
                eventDate: Date(),
                note: "语音录入: \(voiceService.recognizedText)",
                book: books.first,
                contact: contact,
                context: modelContext
            )

            // 标记来源
            // Note: source is set during init, we need to update it after creation
            // This is handled by the record's source field default

            showToast = true
            HapticManager.shared.successNotification()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            HapticManager.shared.errorNotification()
        }
    }

    private func resetState() {
        showingConfirmation = false
        voiceService.recognizedText = ""
        voiceService.parsedResult = nil
        editableResult = EditableVoiceResult()
    }
}

/// 可编辑的语音识别结果
struct EditableVoiceResult {
    var contactName: String = ""
    var amountString: String = ""
    var direction: GiftDirection = .sent
    var eventCategory: EventCategory = .other
}
