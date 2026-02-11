//
//  VoiceInputView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 语音识别结果确认 & 编辑视图
struct VoiceInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceService = VoiceRecordingService.shared
    @State private var editableResults: [EditableVoiceResult] = []
    @State private var hasParsed = false
    @State private var showToast = false
    @State private var errorMessage: String?
    @State private var contactPickerIndex: Int?
    @State private var showingBatchCreateConfirmation = false
    @State private var isCreatingContacts = false
    @State private var showCreateToast = false
    @State private var createToastMessage = ""

    @Query(sort: \GiftBook.sortOrder) private var books: [GiftBook]
    @Query(sort: \Contact.name) private var allContacts: [Contact]
    @Query(filter: #Predicate<CategoryItem> { $0.isVisible == true }, sort: \CategoryItem.sortOrder)
    private var categories: [CategoryItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.Spacing.xl) {
                    // 识别文字显示
                    recognizedTextArea

                    // 解析中 / 解析结果
                    if voiceService.isParsing {
                        parsingIndicator
                    } else if hasParsed {
                        parsedResultForm
                    }

                    // 操作按钮
                    if hasParsed {
                        actionButtons
                    }
                }
                .padding(AppConstants.Spacing.lg)
            }
            .lsjPageBackground()
            .navigationTitle("语音记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
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
            .task {
                await parseRecognizedText()
            }
        }
    }

    // MARK: - 识别文字

    private var recognizedTextArea: some View {
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
    }

    // MARK: - 解析中指示器

    private var parsingIndicator: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("正在智能解析...")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.Spacing.xxxl)
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
                            let trimmed = newName.trimmingCharacters(in: .whitespaces)
                            editableResults[index].matchedContact = allContacts.first(where: { $0.name == trimmed })
                        }
                }

                // 联系人匹配状态
                HStack(spacing: AppConstants.Spacing.sm) {
                    if let contact = editableResults[index].matchedContact {
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
                    Picker("事件类型", selection: $editableResults[index].eventCategoryName) {
                        ForEach(categories, id: \.name) { cat in
                            Text(cat.name).tag(cat.name)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            LSJButton(title: "保存全部记录（\(editableResults.count)条）", style: .primary, icon: "checkmark") {
                saveRecords()
            }
        }
        .padding(.bottom, AppConstants.Spacing.lg)
    }

    // MARK: - 操作方法

    /// 打开 Sheet 后自动调用智能解析
    private func parseRecognizedText() async {
        let text = voiceService.recognizedText
        guard !text.isEmpty else {
            hasParsed = true
            editableResults = [EditableVoiceResult()]
            return
        }

        voiceService.isParsing = true

        let results = await voiceService.smartParse(text)

        voiceService.isParsing = false

        editableResults = results.map { result in
            EditableVoiceResult(
                contactName: result.contactName ?? "",
                amountString: result.amount.map { String(Int($0)) } ?? "",
                direction: GiftDirection(rawValue: result.direction ?? "sent") ?? .sent,
                eventCategoryName: result.eventCategory ?? "其他"
            )
        }

        if editableResults.isEmpty {
            editableResults = [EditableVoiceResult()]
        }

        autoMatchContacts()
        hasParsed = true
        HapticManager.shared.successNotification()
    }

    private func saveRecords() {
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
                let eventName = "\(result.contactName)\(result.eventCategoryName)"

                try recordRepository.create(
                    amount: amount,
                    direction: result.direction.rawValue,
                    eventName: eventName,
                    eventCategory: result.eventCategoryName,
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

    private func autoMatchContacts() {
        for index in editableResults.indices {
            let name = editableResults[index].contactName.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            if let exactMatch = allContacts.first(where: { $0.name == name }) {
                editableResults[index].matchedContact = exactMatch
            } else if let fuzzyMatch = allContacts.first(where: { $0.name.contains(name) || name.contains($0.name) }) {
                editableResults[index].matchedContact = fuzzyMatch
            }
        }
    }

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
    var eventCategoryName: String = "其他"
    var matchedContact: Contact?
}
