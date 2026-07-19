import SwiftUI

struct AppRecoveryView: View {
    let message: String
    let retry: () -> Void
    @State private var shareItem: ExportShareItem?

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("需要恢复数据", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text("升级没有完成，原始数据仍保留。请重试，或先导出恢复目录交给支持人员。")
            } actions: {
                Button("重试升级", action: retry)
                    .buttonStyle(.borderedProminent)
                Button("导出恢复目录") { exportRecoveryDirectory() }
                    .buttonStyle(.bordered)
            }
            .navigationTitle("数据恢复")
        }
        .sheet(item: $shareItem) { ShareSheet(items: [$0.url]) }
        .accessibilityHint(message)
    }

    private func exportRecoveryDirectory() {
        if let url = try? AppModelContainerFactory.recoveryDirectory() {
            shareItem = ExportShareItem(url: url)
        }
    }
}
