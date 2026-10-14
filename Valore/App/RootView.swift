import SwiftData
import SwiftUI
import UIKit

enum AppTab: Hashable {
    case home, entries, goals, summary
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var tab = AppTab.home

    init() {
        Self.configureUIKitAppearance()
    }

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
                .tabItem { Label("Ringkasan", systemImage: "chart.bar.fill") }
                .tag(AppTab.summary)
        }
        .tint(Permen.ink)
        .font(.nunito(17))
        .preferredColorScheme(.light)
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

    /// Bagian UIKit yang tidak bisa diatur dari SwiftUI: judul navigasi & label tab bar.
    private static func configureUIKitAppearance() {
        let ink = UIColor(red: 0x17 / 255, green: 0x17 / 255, blue: 0x17 / 255, alpha: 1)
        let navigation = UINavigationBar.appearance()
        navigation.titleTextAttributes = [.font: PermenFont.uiFont(.black, size: 17), .foregroundColor: ink]
        navigation.largeTitleTextAttributes = [.font: PermenFont.uiFont(.black, size: 34), .foregroundColor: ink]
        UITabBarItem.appearance().setTitleTextAttributes([.font: PermenFont.uiFont(.extraBold, size: 10)], for: .normal)
    }
}

#Preview {
    RootView()
        .modelContainer(try! SampleData.makeContainer())
}
