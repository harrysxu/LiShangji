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

    @Query(sort: \GiftBook.sortOrder) private var books: [GiftBook]

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
                        Button("全部保存") {
                            saveAllRecords()
                        }
                        .fontWeight(.semibold)
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
            .alert("识别失败", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
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
                Text("请核对识别结果，点击可编辑")
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
                    ForEach($recognizedItems) { $item in
                        HStack(spacing: AppConstants.Spacing.md) {
                            // 置信度指示
                            Image(systemName: item.confidence > 0.8 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(item.confidence > 0.8 ? Color.theme.received : Color.theme.warning)
                                .font(.body)

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("姓名", text: $item.name)
                                    .font(.headline)
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("置信度: \(Int(item.confidence * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }

                            Spacer()

                            HStack(spacing: 2) {
                                Text("¥")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.theme.textSecondary)
                                TextField("金额", value: $item.amount, format: .number)
                                    .font(.headline.bold().monospacedDigit())
                                    .foregroundStyle(Color.theme.received)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                        .listRowBackground(Color.theme.card)
                    }
                    .onDelete { indexSet in
                        recognizedItems.remove(atOffsets: indexSet)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - 处理图片

    private func processImage(_ image: UIImage) {
        isProcessing = true
        Task {
            do {
                let items = try await OCRService.shared.recognizeGiftList(from: image)
                await MainActor.run {
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

    // MARK: - 批量保存

    private func saveAllRecords() {
        let recordRepository = GiftRecordRepository()
        let contactRepository = ContactRepository()
        let defaultBook = books.first

        for item in recognizedItems where item.amount > 0 && !item.name.isEmpty {
            do {
                // 查找或创建联系人
                let existingContacts = try contactRepository.search(query: item.name, context: modelContext)
                let contact = existingContacts.first ?? {
                    let newContact = Contact(name: item.name)
                    modelContext.insert(newContact)
                    return newContact
                }()

                // 创建记录
                try recordRepository.create(
                    amount: item.amount,
                    direction: GiftDirection.received.rawValue,
                    eventName: "\(item.name)的礼金",
                    eventCategory: EventCategory.other.rawValue,
                    eventDate: Date(),
                    note: "OCR 识别录入",
                    book: defaultBook,
                    contact: contact,
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
