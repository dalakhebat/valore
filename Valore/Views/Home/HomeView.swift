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
                VStack(alignment: .leading, spacing: 26) {
                    header
                    BalanceCard(total: wallets.reduce(0) { $0 + $1.balance }, walletCount: wallets.count, month: thisMonth)
                    quickActions
                    walletSection
                    goalSection(activeGoals.isEmpty ? goals : activeGoals)
                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Palette.background)
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
                .font(.headline)
                .foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
                .background(Palette.peach, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(Fmt.greeting(at: .now))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(displayName.isEmpty ? "VALORE" : displayName)
                    .font(.title3.weight(.bold))
            }
            Spacer()
            CircleIconButton(symbol: "gearshape", label: "Pengaturan") { showingSettings = true }
        }
    }

    private var initial: String {
        displayName.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "V"
    }

    private var quickActions: some View {
        HStack(alignment: .top, spacing: 8) {
            QuickActionButton(title: "Keluar", symbol: "arrow.up.right", tint: Palette.peach, accessibilityText: "Catat pengeluaran") {
                newEntryKind = .expense
            }
            QuickActionButton(title: "Masuk", symbol: "arrow.down.left", tint: Palette.green, accessibilityText: "Catat pemasukan") {
                newEntryKind = .income
            }
            QuickActionButton(title: "Setor", symbol: "tray.and.arrow.down", tint: Palette.sky, accessibilityText: "Setor ke target") {
                if goals.isEmpty { showingNewGoal = true } else { showingDeposit = true }
            }
            QuickActionButton(title: "Target", symbol: "target", tint: Palette.yellow, accessibilityText: "Bikin target") {
                showingNewGoal = true
            }
        }
    }

    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Dompet") {
                Button { showingNewWallet = true } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 32, height: 32)
                        .background(Palette.card, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tambah dompet")
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(wallets.enumerated()), id: \.element.id) { index, wallet in
                    Button { editingWallet = wallet } label: {
                        WalletTile(wallet: wallet, tint: Palette.pastels[index % Palette.pastels.count])
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func goalSection(_ shown: [SavingGoal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Target tabungan") {
                if !goals.isEmpty {
                    Button("Lihat semua") { selectedTab = .goals }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            if shown.isEmpty {
                Button { showingNewGoal = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                            .background(Palette.yellow, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bikin target pertama")
                                .font(.headline)
                            Text("Nanti dihitung harus nabung berapa per bulan.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(Color.primary)
                    .card()
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shown) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                GoalCard(goal: goal, compact: true)
                                    .frame(width: 236)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Transaksi terbaru") {
                if !entries.isEmpty {
                    Button("Lihat semua") { selectedTab = .entries }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            VStack(spacing: 0) {
                if entries.isEmpty {
                    Text("Belum ada transaksi. Mulai dari tombol Keluar atau Masuk di atas.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                }
                ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider().padding(.leading, 52)
                    }
                    Button { editingEntry = entry } label: {
                        EntryRow(entry: entry, showsDate: true)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .card(padding: 16)
        }
    }
}

private struct BalanceCard: View {
    let total: Int
    let walletCount: Int
    let month: MonthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Total saldo")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(walletCount) dompet")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Palette.card.opacity(0.7), in: Capsule())
            }
            Text(Fmt.rupiah(total))
                .font(.system(size: 36, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            HStack(spacing: 10) {
                flow("Masuk bulan ini", month.income, symbol: "arrow.down.left", color: Palette.positive)
                flow("Keluar bulan ini", month.expense, symbol: "arrow.up.right", color: Palette.coral)
            }
        }
        .card(Palette.sky, padding: 20)
    }

    private func flow(_ title: String, _ amount: Int, symbol: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(Fmt.compactRupiah(amount))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card.opacity(0.75), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WalletTile: View {
    let wallet: Wallet
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: wallet.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 36, height: 36)
                .background(Palette.card.opacity(0.75), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(wallet.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(Fmt.rupiah(wallet.balance))
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .foregroundStyle(Color.primary)
        .card(tint, padding: 16, radius: 22)
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
