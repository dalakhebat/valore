import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Beranda", systemImage: "house.fill") }
            EntryListView()
                .tabItem { Label("Transaksi", systemImage: "list.bullet.rectangle.portrait") }
            GoalListView()
                .tabItem { Label("Tabungan", systemImage: "target") }
            SummaryView()
                .tabItem { Label("Ringkasan", systemImage: "chart.pie.fill") }
        }
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
