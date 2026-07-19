import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DataSafetyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [GiftBook]
    @Query private var contacts: [Contact]
    @Query private var records: [GiftRecord]
    @State private var shareItem: ExportShareItem?
    @State private var isImportingBackup = false
    @State private var restorePreview: BackupPreview?
    @State private var showRestoreOptions = false
    @State private var statusMessage: String?

    private var backupType: UTType { UTType(filenameExtension: "lsxbackup") ?? .data }

    var body: some View {
        List {
            Section("当前数据") {
                LabeledContent("记录", value: "\(records.count) 条")
                LabeledContent("联系人", value: "\(contacts.count) 位")
                LabeledContent("账本", value: "\(books.count) 个")
            }
            Section {
                Button("创建可恢复备份", systemImage: "externaldrive.badge.plus") { createBackup() }
                Button("从备份恢复", systemImage: "arrow.counterclockwise") { isImportingBackup = true }
            } header: {
                Text("完整备份")
            } footer: {
                Text("备份包含实体关系和已有 OCR 原图。恢复前会校验文件，并自动创建当前数据恢复点。")
            }
            Section("表格迁移") {
                NavigationLink("导入 CSV", destination: CSVImportView())
                NavigationLink("导出 CSV", destination: DataExportView())
            }
        }
        .navigationTitle("数据管理")
        .sheet(item: $shareItem) { ShareSheet(items: [$0.url]) }
        .fileImporter(isPresented: $isImportingBackup, allowedContentTypes: [backupType]) { result in
            do {
                let url = try result.get(); let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                restorePreview = try BackupService.shared.preview(url: url); showRestoreOptions = true
            } catch { statusMessage = error.localizedDescription }
        }
        .confirmationDialog("恢复 \(restorePreview?.manifest.recordCounts["records"] ?? 0) 条记录", isPresented: $showRestoreOptions) {
            Button("合并到当前数据") { restore(.merge) }
            Button("替换当前数据", role: .destructive) { restore(.replace) }
            Button("取消", role: .cancel) { restorePreview = nil }
        } message: { Text("同一 ID 的数据默认保留当前版本。替换前会自动备份当前数据。") }
        .alert("数据管理", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
            Button("确定") { statusMessage = nil }
        } message: { Text(statusMessage ?? "") }
    }

    private func createBackup() {
        do { shareItem = ExportShareItem(url: try BackupService.shared.createBackup(context: modelContext)) }
        catch { statusMessage = "备份没有完成：\(error.localizedDescription)" }
    }
    private func restore(_ mode: RestoreMode) {
        guard let restorePreview else { return }
        do { try BackupService.shared.restore(restorePreview, mode: mode, context: modelContext); statusMessage = "恢复完成，已校验并重建数据关系。"; self.restorePreview = nil }
        catch { statusMessage = "恢复没有完成，现有数据未改变：\(error.localizedDescription)" }
    }
}

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GiftBook.sortOrder) private var books: [GiftBook]
    @State private var isSelectingFile = false
    @State private var preview: CSVImportPreview?
    @State private var includeDuplicates = false
    @State private var selectedBook: GiftBook?
    @State private var message: String?

    var body: some View {
        List {
            Section {
                Button("选择 CSV 文件", systemImage: "doc.badge.plus") { isSelectingFile = true }
                if !books.isEmpty { Picker("默认账本", selection: $selectedBook) { Text("不指定").tag(nil as GiftBook?); ForEach(books) { Text($0.name).tag($0 as GiftBook?) } } }
            }
            if let preview {
                Section("预检结果") {
                    LabeledContent("有效", value: "\(preview.validRows.count) 条")
                    LabeledContent("错误", value: "\(preview.errorRows.count) 条")
                    LabeledContent("疑似重复", value: "\(preview.duplicateRows.count) 条")
                    if !preview.duplicateRows.isEmpty { Toggle("仍然导入疑似重复项", isOn: $includeDuplicates) }
                }
                if !preview.errorRows.isEmpty {
                    Section("需要修正") { ForEach(preview.errorRows) { row in LabeledContent("第 \(row.line) 行", value: row.error ?? "格式错误") } }
                }
                Section {
                    Button("导入有效记录", systemImage: "square.and.arrow.down") { performImport() }
                        .disabled(preview.validRows.isEmpty)
                } footer: { Text("导入作为一次事务提交；发生错误时不会留下部分数据。") }
            }
        }
        .navigationTitle("导入 CSV")
        .fileImporter(isPresented: $isSelectingFile, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            do {
                let url = try result.get(); let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                preview = try CSVImportService().preview(url: url, context: modelContext)
            } catch { message = error.localizedDescription }
        }
        .alert("CSV 导入", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("确定") { message = nil } } message: { Text(message ?? "") }
        .onAppear { if selectedBook == nil { selectedBook = books.first } }
    }

    private func performImport() {
        guard let preview else { return }
        do { let count = try CSVImportService().importRows(preview.validRows, includeDuplicates: includeDuplicates, defaultBook: selectedBook, context: modelContext); message = "已导入 \(count) 条记录"; self.preview = nil }
        catch { message = "导入没有完成，现有数据未改变：\(error.localizedDescription)" }
    }
}
