import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case home, entries, goals, summary
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var tab = AppTab.home

    var body: some View {
        TabView(selection: $tab) {
            HomeView(selectedTab: $tab)
                .tabItem { Label("Beranda", systemImage: "house.fill") }
                .tag(AppTab.home)
            EntryListView()
                .tabItem { Label("Transaksi", systemImage: "list.bullet.rectangle.portrait") }
                .tag(AppTab.entries)
            GoalListView()
                .tabItem { Label("Tabungan", systemImage: "target") }
                .tag(AppTab.goals)
            SummaryView()
                .tabItem { Label("Ringkasan", systemImage: "chart.pie.fill") }
                .tag(AppTab.summary)
        }
        .tint(Palette.ink)
        .environment(\.locale, Fmt.locale)
        .task { ensureDefaultWallet() }
    }

    /// Transaksi butuh dompet, jadi selalu ada minimal satu ("Tunai").
    private func ensureDefaultWallet() {
        let count = (try? context.fetchCount(FetchDescriptor<Wallet>())) ?? 0
        guard count == 0 else { return }
        context.insert(Wallet(name: "Tunai", symbol: "banknote.fill"))
        try? context.save()
    }
}

#Preview {
    RootView()
        .modelContainer(try! SampleData.makeContainer())
}
