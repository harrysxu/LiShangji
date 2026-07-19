import Foundation
import SwiftData

struct ICloudConfigurationChangeReceipt {
    let backupURL: URL
    let enabled: Bool
}

@MainActor
enum ICloudConfigurationChangeService {
    static let enabledKey = "iCloudSyncEnabled"
    static let restartRequiredKey = "iCloudSyncRequiresRestart"

    static func stageChange(
        to enabled: Bool,
        context: ModelContext,
        defaults: UserDefaults = .standard,
        backupDirectory: URL? = nil
    ) throws -> ICloudConfigurationChangeReceipt {
        let directory = try backupDirectory ?? AppModelContainerFactory.recoveryDirectory()
        let backupURL = try BackupService.shared.createBackup(context: context, directory: directory)

        // Only persist the requested configuration after a recoverable snapshot exists.
        defaults.set(enabled, forKey: enabledKey)
        defaults.set(true, forKey: restartRequiredKey)
        return ICloudConfigurationChangeReceipt(backupURL: backupURL, enabled: enabled)
    }
}
