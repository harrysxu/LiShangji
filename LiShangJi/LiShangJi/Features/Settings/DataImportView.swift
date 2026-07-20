//
//  DataImportView.swift
//  LiShangJi
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingFileImporter = false
    @State private var preview: CSVImportPreview?
    @State private var importError: String?
    @State private var importedCount: Int?
    @State private var isImporting = false

    var body: some View {
        List {
            Section {
                Button {
                    showingFileImporter = true
                } label: {
                    Label("选择 CSV 文件", systemImage: "doc.badge.plus")
                }
            } footer: {
                Text("导入前会自动创建本地快照。重复记录默认跳过。")
            }

            if let preview {
                Section("导入预览") {
                    summaryRow("可导入", value: "\(preview.importableCount) 条", color: Color.theme.received)
                    summaryRow("重复", value: "\(preview.duplicateCount) 条", color: Color.theme.warning)
                    summaryRow("异常", value: "\(preview.invalidCount) 条", color: Color.theme.sent)

                    Button {
                        performImport()
                    } label: {
                        HStack {
                            Spacer()
                            if isImporting {
                                ProgressView()
                            } else {
                                Text("导入可用记录")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(preview.importableCount == 0 || isImporting)
                }

                Section("异常与重复明细") {
                    ForEach(preview.rows.filter { !$0.canImport }.prefix(50)) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("第 \(row.lineNumber) 行：\(row.contactName.isEmpty ? "未命名" : row.contactName)")
                                .font(.subheadline.weight(.medium))
                            if row.isDuplicate {
                                Text("疑似重复")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.warning)
                            }
                            if !row.errors.isEmpty {
                                Text(row.errors.joined(separator: "、"))
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.sent)
                            }
                        }
                    }
                }
            }

            if let importedCount {
                Section {
                    Label("成功导入 \(importedCount) 条记录", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.theme.received)
                }
            }
        }
        .navigationTitle("导入数据")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            do {
                let url = try result.get()
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                preview = try CSVImportService.shared.previewImport(from: url, context: modelContext)
                importedCount = nil
            } catch {
                importError = error.localizedDescription
            }
        }
        .alert("导入失败", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("确定") { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private func summaryRow(_ title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(color)
        }
    }

    private func performImport() {
        guard let preview else { return }
        isImporting = true
        do {
            importedCount = try CSVImportService.shared.performImport(preview: preview, context: modelContext)
            self.preview = nil
            HapticManager.shared.successNotification()
        } catch {
            importError = error.localizedDescription
            HapticManager.shared.errorNotification()
        }
        isImporting = false
    }
}
