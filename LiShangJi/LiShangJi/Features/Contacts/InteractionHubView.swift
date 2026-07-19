import SwiftData
import SwiftUI

private enum InteractionMode: String, CaseIterable { case contacts = "联系人"; case returns = "待回礼"; case reminders = "提醒" }

struct InteractionHubView: View {
    @State private var mode: InteractionMode = .contacts

    var body: some View {
        VStack(spacing: 0) {
            Picker("往来视图", selection: $mode) {
                ForEach(InteractionMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("interaction_mode_picker")
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.vertical, AppConstants.Spacing.sm)

            switch mode {
            case .contacts: ContactListView(embeddedInInteractionHub: true)
            case .returns: ReturnGiftListView()
            case .reminders: EventListView(embeddedInInteractionHub: true)
            }
        }
        .navigationTitle("往来")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { GlobalAddMenu() } }
    }
}

private struct ReturnGiftListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @Query(filter: #Predicate<GiftRecord> { $0.reciprocityStatusCode == "toReturn" }, sort: \GiftRecord.eventDate, order: .reverse)
    private var records: [GiftRecord]

    var body: some View {
        if !PremiumManager.shared.entitlementPolicy.allows(.returnGiftAssistant) {
            PremiumGateView(icon: "arrow.uturn.forward.circle", title: "回礼助手", subtitle: "根据历史金额和场景准备回礼，并保留清晰依据。")
        } else if records.isEmpty {
            ContentUnavailableView("暂无待回礼", systemImage: "checkmark.circle", description: Text("在联系人历史记录中可将收到的礼金加入待回礼。"))
        } else {
            List(records) { record in
                VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.displayName).font(.headline)
                            Text("依据 \(record.eventDate.chineseFullDate) · \(record.eventCategory)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(record.amount.currencyString).font(.headline.monospacedDigit())
                    }
                    HStack {
                        Button("无需回礼") { try? RecordCommandService().setReciprocityStatus("dismissed", for: record, context: modelContext) }
                            .buttonStyle(.bordered)
                        Spacer()
                        Button("按此回礼") {
                            router.selectedRecordForReturn = record
                            router.selectedBookForEntry = record.book
                            router.showingRecordEntry = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, AppConstants.Spacing.xs)
            }
            .listStyle(.plain)
        }
    }
}
