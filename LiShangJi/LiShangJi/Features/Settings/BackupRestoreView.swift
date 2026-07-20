//
//  BackupRestoreView.swift
//  LiShangJi
//
//  本地快照备份与恢复
//

import SwiftUI
import SwiftData

struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var snapshots: [BackupSnapshotItem] = []
    @State private var manualName = ""
    @State private var isWorking = false
    @State private var shareItem: ExportShareItem?
    @State private var selectedRestoreItem: BackupSnapshotItem?
    @State private var showRestoreDialog = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        List {
            manualBackupSection
            snapshotListSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.theme.background)
        .navigationTitle("备份与恢复")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isWorking)
        .overlay {
            if isWorking {
                ZStack {
                    Color.black.opacity(0.08).ignoresSafeArea()
                    ProgressView("处理中...")
                        .padding(AppConstants.Spacing.lg)
                        .background(Color.theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.md))
                }
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
        .confirmationDialog("恢复备份", isPresented: $showRestoreDialog, presenting: selectedRestoreItem) { item in
            Button("合并到当前数据") {
                restore(item, mode: .merge)
            }
            Button("替换当前所有数据", role: .destructive) {
                restore(item, mode: .replace)
            }
            Button("取消", role: .cancel) {}
        } message: { item in
            Text("恢复「\(item.snapshot.reason)」前会自动创建一份当前数据备份。替换模式会先清空当前数据。")
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("确定") {}
        } message: {
            Text(alertMessage)
        }
        .onAppear(perform: reloadSnapshots)
    }

    private var manualBackupSection: some View {
        Section {
            TextField("备份名称", text: $manualName)

            Button {
                createManualBackup()
            } label: {
                HStack {
                    Image(systemName: "archivebox.fill")
                    Text("创建手动备份")
                    Spacer()
                }
                .foregroundStyle(Color.theme.primary)
            }
            .disabled(isWorking)
        } header: {
            Text("手动备份")
        } footer: {
            Text("导入、恢复、清空等高风险操作会自动生成备份。手动备份可用于版本升级前留存。")
        }
        .listRowBackground(Color.theme.card)
    }

    private var snapshotListSection: some View {
        Section {
            if snapshots.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    Image(systemName: "tray")
                        .foregroundStyle(Color.theme.textSecondary)
                    Text("暂无备份")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.theme.textPrimary)
                    Text("创建一次手动备份后会显示在这里")
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                .padding(.vertical, AppConstants.Spacing.sm)
            } else {
                ForEach(snapshots) { item in
                    snapshotRow(item)
                }
            }
        } header: {
            HStack {
                Text("备份列表")
                Spacer()
                Button("刷新") {
                    reloadSnapshots()
                }
                .font(.caption)
            }
        }
        .listRowBackground(Color.theme.card)
    }

    private func snapshotRow(_ item: BackupSnapshotItem) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.snapshot.reason)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.theme.textPrimary)
                    Text(item.snapshot.createdAt.chineseFullDate)
                        .font(.caption)
                        .foregroundStyle(Color.theme.textSecondary)
                }
                Spacer()
                Text(item.kindText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(item.isManual ? Color.theme.primary : Color.theme.info)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((item.isManual ? Color.theme.primary : Color.theme.info).opacity(0.1))
                    .clipShape(Capsule())
            }

            Text("\(item.snapshot.books.count) 个账本 · \(item.snapshot.records.count) 条记录 · \(item.snapshot.contacts.count) 位联系人 · \(item.snapshot.events.count) 个提醒")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary)

            HStack {
                Button {
                    selectedRestoreItem = item
                    showRestoreDialog = true
                } label: {
                    Label("恢复", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    shareItem = ExportShareItem(url: item.url)
                } label: {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
            }
            .font(.caption)
            .foregroundStyle(Color.theme.primary)
        }
        .padding(.vertical, AppConstants.Spacing.xs)
    }

    private func reloadSnapshots() {
        snapshots = BackupService.shared.listSnapshots().compactMap { url in
            guard let snapshot = try? BackupService.shared.loadSnapshot(from: url) else {
                return nil
            }
            return BackupSnapshotItem(url: url, snapshot: snapshot)
        }
    }

    private func createManualBackup() {
        isWorking = true
        defer { isWorking = false }

        do {
            let url = try BackupService.shared.createManualSnapshot(context: modelContext, name: manualName)
            manualName = ""
            reloadSnapshots()
            shareItem = ExportShareItem(url: url)
            HapticManager.shared.successNotification()
            showInfo(title: "备份完成", message: "已创建手动备份，可通过分享保存到文件或云盘。")
        } catch {
            HapticManager.shared.errorNotification()
            showInfo(title: "备份失败", message: error.localizedDescription)
        }
    }

    private func restore(_ item: BackupSnapshotItem, mode: BackupRestoreMode) {
        isWorking = true
        defer { isWorking = false }

        do {
            try BackupService.shared.restoreSnapshot(from: item.url, mode: mode, context: modelContext)
            reloadSnapshots()
            HapticManager.shared.successNotification()
            showInfo(title: "恢复完成", message: mode == .replace ? "已使用备份替换当前数据。" : "已将备份合并到当前数据。")
        } catch {
            HapticManager.shared.errorNotification()
            showInfo(title: "恢复失败", message: error.localizedDescription)
        }
    }

    private func showInfo(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

private struct BackupSnapshotItem: Identifiable {
    let url: URL
    let snapshot: BackupSnapshot

    var id: String { url.path }
    var isManual: Bool { url.lastPathComponent.hasPrefix("manual_") }
    var kindText: String { isManual ? "手动" : "自动" }
}
