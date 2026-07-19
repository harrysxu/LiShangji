import Foundation

enum ReviewRequestPolicy {
    static func recordSuccessfulEntry() -> Bool {
        let defaults = UserDefaults.standard
        let countKey = "successfulRecordCount"
        let versionKey = "reviewRequestedVersion"
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)
        guard count >= 5, defaults.string(forKey: versionKey) != AppConstants.Brand.version else { return false }
        defaults.set(AppConstants.Brand.version, forKey: versionKey)
        return true
    }
}
