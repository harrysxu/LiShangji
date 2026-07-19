import Foundation
import SwiftData

enum AppLaunchState: Equatable {
    case loading
    case migrating
    case ready
    case recoveryRequired(String)
}

enum AppModelContainerFactory {
    private static let migrationReceiptKey = "didOpenSchemaV2"

    @MainActor
    static func makeContainer() throws -> ModelContainer {
        try createRecoverySnapshotIfNeeded()
        let cloudKit: ModelConfiguration.CloudKitDatabase = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") ? .automatic : .none
        let schema = Schema(versionedSchema: LiShangJiSchemaV2.self)
        let configuration = ModelConfiguration("default", schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: cloudKit)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: LiShangJiMigrationPlan.self,
            configurations: [configuration]
        )
        try CompatibilityBackfillService.runIfNeeded(context: container.mainContext)
        UserDefaults.standard.set(true, forKey: migrationReceiptKey)
        UserDefaults.standard.set(false, forKey: ICloudConfigurationChangeService.restartRequiredKey)
        return container
    }

    static func recoveryDirectory() throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = base.appendingPathComponent("Recovery", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func createRecoverySnapshotIfNeeded() throws {
        guard !UserDefaults.standard.bool(forKey: migrationReceiptKey) else { return }
        let fileManager = FileManager.default
        let support = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let source = support.appendingPathComponent("default.store")
        guard fileManager.fileExists(atPath: source.path) else { return }

        let formatter = ISO8601DateFormatter()
        let snapshot = try recoveryDirectory().appendingPathComponent("pre-v2-\(formatter.string(from: Date()))", isDirectory: true)
        try fileManager.createDirectory(at: snapshot, withIntermediateDirectories: true)
        for suffix in ["", "-wal", "-shm"] {
            let item = support.appendingPathComponent("default.store\(suffix)")
            if fileManager.fileExists(atPath: item.path) {
                try fileManager.copyItem(at: item, to: snapshot.appendingPathComponent(item.lastPathComponent))
            }
        }
    }
}
