import SwiftUI

struct GlobalAddMenu: View {
    @Environment(NavigationRouter.self) private var router
    @State private var showPurchase = false

    var body: some View {
        Menu {
            Button("手动记一笔", systemImage: "square.and.pencil") { router.showingRecordEntry = true }
            Button("扫描礼单", systemImage: "camera.viewfinder") { openPremium(.ocrBatch) { router.showingOCRScanner = true } }
            Button("语音录入", systemImage: "mic.fill") {
                openPremium(.voiceBatch) {
                    router.selectedTab = .home
                    router.voiceCaptureRequested = true
                }
            }
            Divider()
            Button("新建提醒", systemImage: "bell.badge") { router.showingEventEntry = true }
        } label: {
            Image(systemName: "plus")
                .font(.headline)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("新增")
        .sheet(isPresented: $showPurchase) { PurchaseView() }
    }

    private func openPremium(_ feature: EntitlementFeature, action: () -> Void) {
        if PremiumManager.shared.entitlementPolicy.allows(feature) { action() } else { showPurchase = true }
    }
}
