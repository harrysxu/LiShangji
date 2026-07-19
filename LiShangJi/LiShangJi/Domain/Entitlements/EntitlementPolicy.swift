import Foundation

enum EntitlementFeature: String, CaseIterable {
    case multipleBooks
    case ocrBatch
    case voiceBatch
    case advancedAnalytics
    case returnGiftAssistant
}

struct EntitlementPolicy {
    let isPremium: Bool

    func allows(_ feature: EntitlementFeature) -> Bool {
        isPremium
    }

    func canCreateBook(existingActiveBookCount: Int) -> Bool {
        isPremium || existingActiveBookCount < 1
    }
}
