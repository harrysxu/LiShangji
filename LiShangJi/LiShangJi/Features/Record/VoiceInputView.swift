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
    @State private var editableResults: [EditableVoiceResult] = []
    @State private var showToast = false
    @State private var errorMessage: String?
    @State private var showPermissionAlert = false
    @State private var contactPickerIndex: Int?  // 当前正在选择联系人的条目索引
    @State private var showingBatchCreateConfirmation = false
    @State private var isCreatingContacts = false  // 防止重复点击
    @State private var showCreateToast = false
    @State private var createToastMessage = ""

    @Query(sort: \GiftBook.sortOrder) private var books: [GiftBook]
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 语音波形区域
                    voiceWaveArea

                    // 识别文字显示
                    recognizedTextArea

                    // 解析结果
                    if showingConfirmation {
                        parsedResultForm
                    }

                    // 操作按钮
                    actionButtons
                }
                .padding(AppConstants.Spacing.lg)
            }
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
            .toast(isPresented: $showToast, message: "\(editableResults.count)条记录保存成功")
            .toast(isPresented: $showCreateToast, message: createToastMessage)
            .sheet(item: Binding(
                get: { contactPickerIndex.map { IdentifiableInt(value: $0) } },
                set: { contactPickerIndex = $0?.value }
            )) { item in
                RecordContactPickerView { contact in
                    editableResults[item.value].matchedContact = contact
                    editableResults[item.value].contactName = contact.name
                    contactPickerIndex = nil
                }
            }
            .alert("确认创建联系人", isPresented: $showingBatchCreateConfirmation) {
                Button("确认创建") {
                    batchCreateContacts()
                }
                Button("取消", role: .cancel) { }
            } message: {
                let count = editableResults.filter { $0.matchedContact == nil && !$0.contactName.trimmingCharacters(in: .whitespaces).isEmpty }.count
                Text("将为 \(count) 个未关联的姓名创建新联系人")
            }
            .alert("错误", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
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
            .onChange(of: voiceService.lastError) { _, newError in
                if let error = newError {
                    errorMessage = error
                    voiceService.lastError = nil
                }
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
        VStack(spacing: AppConstants.Spacing.md) {
            HStack {
                Text("解析结果")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)
                Spacer()
                Text("共\(editableResults.count)条")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
            }

            // 一键创建联系人按钮
            let unmatchedCount = editableResults.filter { $0.matchedContact == nil && !$0.contactName.trimmingCharacters(in: .whitespaces).isEmpty }.count
            if unmatchedCount > 0 {
                Button {
                    showingBatchCreateConfirmation = true
                } label: {
                    HStack(spacing: AppConstants.Spacing.sm) {
                        if isCreatingContacts {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(.white)
                                .font(.subheadline)
                        }
                        Text(isCreatingContacts ? "正在创建..." : "一键创建 \(unmatchedCount) 个联系人")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.Spacing.sm)
                    .background(isCreatingContacts ? Color.theme.primary.opacity(0.5) : Color.theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
                }
                .buttonStyle(.plain)
                .disabled(isCreatingContacts)
            }

            ForEach(editableResults.indices, id: \.self) { index in
                singleResultCard(index: index)
            }
        }
    }

    private func singleResultCard(index: Int) -> some View {
        LSJCard {
            VStack(spacing: AppConstants.Spacing.sm) {
                HStack {
                    Text("记录 \(index + 1)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.theme.textSecondary)
                    Spacer()
                    if editableResults.count > 1 {
                        Button {
                            withAnimation {
                                _ = editableResults.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                    }
                }

                // 方向
                Picker("方向", selection: $editableResults[index].direction) {
                    ForEach(GiftDirection.allCases, id: \.self) { dir in
                        Text(dir.displayName).tag(dir)
                    }
                }
                .pickerStyle(.segmented)

                // 联系人
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.theme.primary)
                    TextField("联系人", text: $editableResults[index].contactName)
                        .onChange(of: editableResults[index].contactName) { _, newName in
                            // 姓名变化时重新匹配联系人
                            let trimmed = newName.trimmingCharacters(in: .whitespaces)
                            editableResults[index].matchedContact = allContacts.first(where: { $0.name == trimmed })
                        }
                }

                // 联系人匹配状态
                HStack(spacing: AppConstants.Spacing.sm) {
                    if let contact = editableResults[index].matchedContact {
                        // 已匹配联系人
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill.checkmark")
                                .font(.caption2)
                                .foregroundStyle(Color.theme.received)
                            Text(contact.name)
                                .font(.caption)
                                .foregroundStyle(Color.theme.textPrimary)
                            if contact.name != editableResults[index].contactName.trimmingCharacters(in: .whitespaces) {
                                Text("(模糊匹配)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.warning)
                            }
                            Button {
                                editableResults[index].matchedContact = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.textSecondary.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.theme.received.opacity(0.1))
                        .clipShape(Capsule())
                    } else if !editableResults[index].contactName.trimmingCharacters(in: .whitespaces).isEmpty {
                        // 未关联
                        HStack(spacing: 4) {
                            Image(systemName: "person.slash")
                                .font(.caption2)
                                .foregroundStyle(Color.theme.textSecondary)
                            Text("未关联联系人")
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                    }

                    Spacer()

                    Button {
                        contactPickerIndex = index
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "person.crop.rectangle.stack")
                                .font(.caption)
                            Text("选择")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.theme.primary)
                    }
                    .buttonStyle(.plain)
                }

                // 金额
                HStack {
                    Image(systemName: "yensign.circle.fill")
                        .foregroundStyle(Color.theme.primary)
                    TextField("金额", text: $editableResults[index].amountString)
                        .keyboardType(.decimalPad)
                }

                // 事件类型
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.theme.primary)
                    Picker("事件类型", selection: $editableResults[index].eventCategory) {
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
                LSJButton(title: "保存全部记录（\(editableResults.count)条）", style: .primary, icon: "checkmark") {
                    saveRecords()
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
            let permissionStatus = voiceService.checkPermissionStatus()
            switch permissionStatus {
            case .authorized:
                startRecordingDirectly()
            case .notDetermined:
                Task {
                    let granted = await voiceService.requestPermission()
                    if granted {
                        startRecordingDirectly()
                    } else {
                        showPermissionAlert = true
                    }
                }
            case .denied:
                showPermissionAlert = true
            }
        }
    }
    
    private func startRecordingDirectly() {
        do {
            try voiceService.startRecording()
        } catch {
            errorMessage = "无法启动录音: \(error.localizedDescription)"
        }
    }

    private func confirmAndParse() {
        let results = voiceService.parseMultipleRecords(voiceService.recognizedText)

        editableResults = results.map { result in
            EditableVoiceResult(
                contactName: result.contactName ?? "",
                amountString: result.amount.map { String(Int($0)) } ?? "",
                direction: GiftDirection(rawValue: result.direction ?? "sent") ?? .sent,
                eventCategory: EventCategory(rawValue: result.eventCategory ?? "other") ?? .other
            )
        }

        // 如果没解析出任何结果，至少提供一条空记录供手动填写
        if editableResults.isEmpty {
            editableResults = [EditableVoiceResult()]
        }

        // 自动匹配联系人
        autoMatchContacts()

        showingConfirmation = true
        HapticManager.shared.successNotification()
    }

    private func saveRecords() {
        // 校验所有记录
        for (index, result) in editableResults.enumerated() {
            guard let amount = Double(result.amountString), amount > 0 else {
                errorMessage = "第\(index + 1)条记录：请输入有效金额"
                return
            }
            guard !result.contactName.isEmpty else {
                errorMessage = "第\(index + 1)条记录：请输入联系人"
                return
            }
        }

        let recordRepository = GiftRecordRepository()

        do {
            for result in editableResults {
                let amount = Double(result.amountString) ?? 0
                let eventName = "\(result.contactName)\(result.eventCategory.displayName)"

                // 使用已匹配的联系人（可为 nil），不再自动创建
                try recordRepository.create(
                    amount: amount,
                    direction: result.direction.rawValue,
                    eventName: eventName,
                    eventCategory: result.eventCategory.rawValue,
                    eventDate: Date(),
                    note: "语音录入: \(voiceService.recognizedText)",
                    contactName: result.contactName,
                    book: books.first,
                    contact: result.matchedContact,
                    context: modelContext
                )
            }

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

    // MARK: - 联系人匹配

    /// 自动匹配联系人（精确匹配优先，其次模糊匹配）
    private func autoMatchContacts() {
        for index in editableResults.indices {
            let name = editableResults[index].contactName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            // 精确匹配优先
            if let exactMatch = allContacts.first(where: { $0.name == name }) {
                editableResults[index].matchedContact = exactMatch
            } else if let fuzzyMatch = allContacts.first(where: { $0.name.contains(name) || name.contains($0.name) }) {
                // 模糊匹配：包含关系
                editableResults[index].matchedContact = fuzzyMatch
            }
        }
    }

    /// 批量创建未匹配的联系人
    private func batchCreateContacts() {
        guard !isCreatingContacts else { return }
        isCreatingContacts = true

        let contactRepository = ContactRepository()
        var createdCount = 0

        for index in editableResults.indices {
            let result = editableResults[index]
            let trimmedName = result.contactName.trimmingCharacters(in: .whitespaces)
            guard result.matchedContact == nil, !trimmedName.isEmpty else { continue }
            do {
                let newContact = try contactRepository.create(
                    name: trimmedName,
                    relation: RelationType.other.rawValue,
                    phone: "",
                    context: modelContext
                )
                editableResults[index].matchedContact = newContact
                createdCount += 1
            } catch {
                continue
            }
        }

        if createdCount > 0 {
            try? modelContext.save()
            HapticManager.shared.successNotification()
            createToastMessage = "成功创建 \(createdCount) 个联系人"
            withAnimation {
                showCreateToast = true
            }
        }

        isCreatingContacts = false
    }

    private func resetState() {
        showingConfirmation = false
        voiceService.recognizedText = ""
        voiceService.parsedResults = []
        editableResults = []
    }
}

/// 用于 sheet(item:) 绑定的可识别整数包装
private struct IdentifiableInt: Identifiable {
    let id: Int
    let value: Int
    init(value: Int) {
        self.id = value
        self.value = value
    }
}

/// 可编辑的语音识别结果
struct EditableVoiceResult {
    var contactName: String = ""
    var amountString: String = ""
    var direction: GiftDirection = .sent
    var eventCategory: EventCategory = .other
    var matchedContact: Contact?  // 关联的联系人
}
