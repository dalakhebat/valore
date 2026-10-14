import SwiftData
import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \SavingGoal.createdAt) private var goals: [SavingGoal]
    @AppStorage("displayName") private var displayName = ""

    @State private var newEntryKind: EntryKind?
    @State private var editingEntry: LedgerEntry?
    @State private var editingWallet: Wallet?
    @State private var showingNewWallet = false
    @State private var showingDeposit = false
    @State private var showingNewGoal = false
    @State private var showingSettings = false

    var body: some View {
        let thisMonth = MonthSummary(records: entries.map(\.record), month: .now)
        let activeGoals = goals.filter { !$0.plan().isDone }

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    BalanceCard(total: wallets.reduce(0) { $0 + $1.balance }, walletCount: wallets.count, month: thisMonth)
                    quickActions
                    walletSection
                    goalSection(activeGoals.isEmpty ? goals : activeGoals)
                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(PermenBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $newEntryKind) { kind in EntryFormView(kind: kind) }
            .sheet(item: $editingEntry) { entry in EntryFormView(entry: entry) }
            .sheet(item: $editingWallet) { wallet in WalletFormView(wallet: wallet, canDelete: wallets.count > 1) }
            .sheet(isPresented: $showingNewWallet) { WalletFormView() }
            .sheet(isPresented: $showingDeposit) { DepositFormView() }
            .sheet(isPresented: $showingNewGoal) { GoalFormView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(initial)
                .font(.bangers(24, relativeTo: .title2))
                .foregroundStyle(Permen.ink)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Permen.pinkSoft))
                .overlay(Circle().strokeBorder(Permen.ink, lineWidth: Permen.line))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                FieldLabel(Fmt.greeting(at: .now))
                Text((displayName.isEmpty ? "VALORE" : displayName).uppercased())
                    .font(.bangers(30, relativeTo: .title))
                    .foregroundStyle(Permen.ink)
                    .lineLimit(1)
            }
            Spacer()
            BrutIconButton(symbol: "gearshape.fill", label: "Pengaturan") { showingSettings = true }
        }
    }

    private var initial: String {
        displayName.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "V"
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            QuickActionTile(title: "Keluar", symbol: "arrow.up.right", fill: Permen.pinkSoft, accessibilityText: "Catat pengeluaran") {
                newEntryKind = .expense
            }
            QuickActionTile(title: "Masuk", symbol: "arrow.down.left", fill: Permen.mint, accessibilityText: "Catat pemasukan") {
                newEntryKind = .income
            }
            QuickActionTile(title: "Setor", symbol: "tray.and.arrow.down.fill", fill: Permen.cyanSoft, accessibilityText: "Setor ke target") {
                if goals.isEmpty { showingNewGoal = true } else { showingDeposit = true }
            }
            QuickActionTile(title: "Target", symbol: "target", fill: Permen.lemon, accessibilityText: "Bikin target") {
                showingNewGoal = true
            }
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Dompet") {
                BrutIconButton(symbol: "plus", label: "Tambah dompet", size: 34) { showingNewWallet = true }
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                    Button { editingWallet = wallet } label: {
                        WalletTile(wallet: wallet)
                    }
                    .buttonStyle(BrutPressStyle(fill: Permen.candies[index % Permen.candies.count], radius: Permen.radiusCard))
                }
            }
        }
    }

    private func goalSection(_ shown: [SavingGoal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Target tabungan") {
                if !goals.isEmpty {
                    InkLink(title: "Lihat semua") { selectedTab = .goals }
                }
            }
            if shown.isEmpty {
                EmptyCard(
                    symbol: "target",
                    title: "Belum ada target",
                    message: "Bikin target, nanti dihitung harus nabung berapa per bulan.",
                    actionTitle: "Bikin target",
                    action: { showingNewGoal = true }
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(shown) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                GoalCard(goal: goal)
                                    .frame(width: 260)
                            }
                            .buttonStyle(BrutPressStyle(fill: Permen.surface, radius: Permen.radiusCard))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
                }
                .padding(.horizontal, -20)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Transaksi terbaru") {
                if !entries.isEmpty {
                    InkLink(title: "Lihat semua") { selectedTab = .entries }
                }
            }
            if entries.isEmpty {
                EmptyCard(symbol: "tray", title: "Belum ada transaksi", message: "Mulai dari tombol Keluar atau Masuk di atas.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { InkDivider() }
                        Button { editingEntry = entry } label: {
                            EntryRow(entry: entry, showsDate: true)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(BrutShape())
            }
        }
    }
}

private struct BalanceCard: View {
    let total: Int
    let walletCount: Int
    let month: MonthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                FieldLabel("Total saldo")
                Spacer()
                Sticker(text: "\(walletCount) dompet")
            }
            Text(Fmt.rupiah(total))
                .font(.nunito(38, .black))
                .foregroundStyle(Permen.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            HStack(spacing: 10) {
                flow("Masuk bulan ini", month.income, symbol: "arrow.down.left", fill: Permen.mint)
                flow("Keluar bulan ini", month.expense, symbol: "arrow.up.right", fill: Permen.pinkSoft)
            }
        }
        .brut(Permen.lemon, padding: 18)
    }

    private func flow(_ title: String, _ amount: Int, symbol: String, fill: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(Permen.ink)
                .frame(width: 28, height: 28)
                .background(Circle().fill(fill))
                .overlay(Circle().strokeBorder(Permen.ink, lineWidth: 1.5))
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.nunito(11, .bold, relativeTo: .caption))
                    .foregroundStyle(Permen.muted)
                Text(Fmt.compactRupiah(amount))
                    .font(.nunito(16, .black))
                    .foregroundStyle(Permen.ink)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BrutShape(fill: Permen.surface, radius: Permen.radiusField, shadow: 0))
    }
}

private struct WalletTile: View {
    let wallet: Wallet

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: wallet.symbol)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Permen.surface))
                .overlay(Circle().strokeBorder(Permen.ink, lineWidth: 1.5))
            VStack(alignment: .leading, spacing: 0) {
                Text(wallet.name)
                    .font(.nunito(14, .bold))
                    .lineLimit(1)
                Text(Fmt.rupiah(wallet.balance))
                    .font(.nunito(18, .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .foregroundStyle(Permen.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
