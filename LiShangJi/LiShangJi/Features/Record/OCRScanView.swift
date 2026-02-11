//
//  OCRScanView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData

/// OCR 扫描识别视图
struct OCRScanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var recognizedItems: [OCRRecognizedItem] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingResults = false
    @State private var selectedBook: GiftBook?
    @State private var contactPickerIndex: Int?  // 当前正在选择联系人的条目索引
    @State private var showingBatchCreateConfirmation = false
    @State private var isCreatingContacts = false  // 防止重复点击
    @State private var showCreateToast = false
    @State private var createToastMessage = ""

    @Query(sort: \GiftBook.sortOrder) private var books: [GiftBook]
    @Query(sort: \Contact.name) private var allContacts: [Contact]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showingResults {
                    resultsList
                } else {
                    sourceSelection
                }
            }
            .lsjPageBackground()
            .navigationTitle(showingResults ? "识别结果" : "OCR 识别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                if showingResults && !recognizedItems.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        let selectedCount = recognizedItems.filter(\.isSelected).count
                        Button("保存(\(selectedCount))") {
                            saveAllRecords()
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedCount == 0)
                        .debounced()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
            .onAppear {
                // 默认选中第一个账本
                if selectedBook == nil {
                    selectedBook = books.first
                }
            }
            .alert("识别失败", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: Binding(
                get: { contactPickerIndex != nil },
                set: { if !$0 { contactPickerIndex = nil } }
            )) {
                RecordContactPickerView { contact in
                    if let index = contactPickerIndex, index < recognizedItems.count {
                        recognizedItems[index].matchedContact = contact
                    }
                    contactPickerIndex = nil
                }
            }
            .alert("一键创建联系人", isPresented: $showingBatchCreateConfirmation) {
                Button("确认创建") {
                    batchCreateContacts()
                }
                Button("取消", role: .cancel) {}
            } message: {
                let allNames = recognizedItems
                    .filter { $0.isSelected && $0.matchedContact == nil && !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                    .map { $0.name.trimmingCharacters(in: .whitespaces) }
                let displayNames = allNames.prefix(5).joined(separator: "、")
                let suffix = allNames.count > 5 ? " 等\(allNames.count)人" : ""
                Text("将为 \(allNames.count) 人创建联系人：\n\(displayNames)\(suffix)")
            }
            .toast(isPresented: $showCreateToast, message: createToastMessage, type: .success)
        }
    }

    // MARK: - 来源选择

    private var sourceSelection: some View {
        VStack(spacing: AppConstants.Spacing.xxl) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color.theme.primary.opacity(0.6))

            Text("拍照或选择图片识别礼单")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.theme.textPrimary)

            Text("支持识别姓名和金额，建议逐行对准拍摄")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: AppConstants.Spacing.md) {
                LSJButton(title: "拍照识别", style: .primary, icon: "camera.fill") {
                    showingCamera = true
                }

                LSJButton(title: "从相册选择", style: .secondary, icon: "photo.on.rectangle") {
                    showingImagePicker = true
                }
            }
            .padding(.horizontal, AppConstants.Spacing.xxxl)

            if isProcessing {
                ProgressView("正在识别中...")
                    .foregroundStyle(Color.theme.textSecondary)
            }

            Spacer()
        }
        .padding(AppConstants.Spacing.lg)
    }

    // MARK: - 识别结果列表

    private var resultsList: some View {
        VStack(spacing: 0) {
            // 提示栏
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.theme.info)
                Text("点击勾选框可取消不需要的条目")
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Spacer()
                Button("重新扫描") {
                    showingResults = false
                    selectedImage = nil
                    recognizedItems = []
                }
                .font(.caption)
                .foregroundStyle(Color.theme.primary)
                .debounced()
            }
            .padding(AppConstants.Spacing.md)
            .background(Color.theme.card)

            if recognizedItems.isEmpty {
                Spacer()
                LSJEmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "未识别到记录",
                    subtitle: "请重新拍摄或选择更清晰的图片",
                    actionTitle: "重新扫描"
                ) {
                    showingResults = false
                    selectedImage = nil
                }
                Spacer()
            } else {
                List {
                    // 账本选择
                    Section {
                        bookPicker
                    }

                    // 全选/取消全选
                    Section {
                        HStack {
                            let allSelected = recognizedItems.allSatisfy(\.isSelected)
                            Button {
                                let newValue = !allSelected
                                for index in recognizedItems.indices {
                                    recognizedItems[index].isSelected = newValue
                                }
                            } label: {
                                HStack(spacing: AppConstants.Spacing.sm) {
                                    Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(allSelected ? Color.theme.primary : Color.theme.textSecondary)
                                    Text(allSelected ? "取消全选" : "全选")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.theme.textPrimary)
                                }
                            }
                            Spacer()
                            Text("共 \(recognizedItems.count) 条，已选 \(recognizedItems.filter(\.isSelected).count) 条")
                                .font(.caption)
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                        .listRowBackground(Color.theme.card)
                    }

                    // 一键创建联系人
                    let unmatchedCount = recognizedItems.filter { $0.isSelected && $0.matchedContact == nil && !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.count
                    if unmatchedCount > 0 {
                        Section {
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
                            .listRowBackground(Color.clear)
                        }
                    }

                    // 识别条目列表
                    Section {
                        ForEach(Array($recognizedItems.enumerated()), id: \.element.id) { index, $item in
                            VStack(spacing: 0) {
                                HStack(spacing: AppConstants.Spacing.md) {
                                    // 勾选框
                                    Button {
                                        item.isSelected.toggle()
                                    } label: {
                                        Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(item.isSelected ? Color.theme.primary : Color.theme.textSecondary)
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)

                                    VStack(alignment: .leading, spacing: 4) {
                                        TextField("姓名", text: $item.name)
                                            .font(.headline)
                                            .foregroundStyle(item.isSelected ? Color.theme.textPrimary : Color.theme.textSecondary)
                                            .onChange(of: item.name) { _, newName in
                                                // 姓名变化时重新匹配联系人
                                                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                                                item.matchedContact = allContacts.first(where: { $0.name == trimmed })
                                            }
                                        HStack(spacing: 4) {
                                            Image(systemName: item.confidence > 0.8 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                                .foregroundStyle(item.confidence > 0.8 ? Color.theme.received : Color.theme.warning)
                                                .font(.caption2)
                                            Text("置信度: \(Int(item.confidence * 100))%")
                                                .font(.caption2)
                                                .foregroundStyle(Color.theme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    HStack(spacing: 2) {
                                        Text("¥")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.theme.textSecondary)
                                        TextField("金额", value: $item.amount, format: .number)
                                            .font(.headline.bold().monospacedDigit())
                                            .foregroundStyle(item.isSelected ? Color.theme.received : Color.theme.textSecondary)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 80)
                                    }
                                }

                                // 联系人匹配状态
                                HStack(spacing: AppConstants.Spacing.sm) {
                                    // 占位，对齐勾选框宽度
                                    Color.clear.frame(width: 22)

                                    if let contact = item.matchedContact {
                                        // 已匹配联系人
                                        HStack(spacing: 4) {
                                            Image(systemName: "person.fill.checkmark")
                                                .font(.caption2)
                                                .foregroundStyle(Color.theme.received)
                                            Text(contact.name)
                                                .font(.caption)
                                                .foregroundStyle(Color.theme.textPrimary)
                                            if contact.name != item.name {
                                                Text("(模糊匹配)")
                                                    .font(.caption2)
                                                    .foregroundStyle(Color.theme.warning)
                                            }
                                            Button {
                                                item.matchedContact = nil
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
                                    } else {
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
                                .padding(.top, 4)
                            }
                            .opacity(item.isSelected ? 1.0 : 0.5)
                            .listRowBackground(Color.theme.card)
                        }
                        .onDelete { indexSet in
                            recognizedItems.remove(atOffsets: indexSet)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - 账本选择器

    private var bookPicker: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .foregroundStyle(Color.theme.primary)
            Text("保存到账本")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textPrimary)
            Spacer()
            Picker("账本", selection: $selectedBook) {
                Text("不关联账本").tag(nil as GiftBook?)
                ForEach(books) { book in
                    Text(book.name).tag(book as GiftBook?)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.theme.primary)
        }
        .listRowBackground(Color.theme.card)
    }

    // MARK: - 处理图片

    private func processImage(_ image: UIImage) {
        isProcessing = true
        Task {
            do {
                // 使用智能识别：AI 优先，正则回退
                var items = try await OCRService.shared.smartRecognizeGiftList(from: image)
                await MainActor.run {
                    // 自动匹配联系人
                    autoMatchContacts(&items)
                    recognizedItems = items
                    showingResults = true
                    isProcessing = false
                    HapticManager.shared.successNotification()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "识别失败: \(error.localizedDescription)"
                    isProcessing = false
                    HapticManager.shared.errorNotification()
                }
            }
        }
    }

    // MARK: - 自动匹配联系人

    private func autoMatchContacts(_ items: inout [OCRRecognizedItem]) {
        for index in items.indices {
            let name = items[index].name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            // 精确匹配优先
            if let exactMatch = allContacts.first(where: { $0.name == name }) {
                items[index].matchedContact = exactMatch
            } else if let fuzzyMatch = allContacts.first(where: { $0.name.contains(name) || name.contains($0.name) }) {
                // 模糊匹配：包含关系
                items[index].matchedContact = fuzzyMatch
            }
        }
    }

    // MARK: - 批量创建联系人

    private func batchCreateContacts() {
        guard !isCreatingContacts else { return }
        isCreatingContacts = true

        let contactRepository = ContactRepository()
        var createdCount = 0

        for index in recognizedItems.indices {
            let item = recognizedItems[index]
            let trimmedName = item.name.trimmingCharacters(in: .whitespaces)
            guard item.isSelected, item.matchedContact == nil, !trimmedName.isEmpty else { continue }
            do {
                let newContact = try contactRepository.create(
                    name: trimmedName,
                    relation: RelationType.other.rawValue,
                    phone: "",
                    context: modelContext
                )
                recognizedItems[index].matchedContact = newContact
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

    // MARK: - 批量保存

    private func saveAllRecords() {
        let recordRepository = GiftRecordRepository()
        let targetBook = selectedBook

        // 只保存选中的条目
        for item in recognizedItems where item.isSelected && item.amount > 0 && !item.name.isEmpty {
            do {
                // 创建记录：contactName 始终填充，contact 使用匹配到的联系人（可为 nil）
                try recordRepository.create(
                    amount: item.amount,
                    direction: GiftDirection.received.rawValue,
                    eventName: "\(item.name)的礼金",
                    eventCategory: "其他",
                    eventDate: Date(),
                    note: "OCR 识别录入",
                    contactName: item.name,
                    book: targetBook,
                    contact: item.matchedContact,
                    context: modelContext
                )
            } catch {
                // 继续处理下一条
                continue
            }
        }

        try? modelContext.save()
        HapticManager.shared.successNotification()
        dismiss()
    }
}

// MARK: - 图片选择器

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
