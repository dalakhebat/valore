import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Wallet.createdAt) private var wallets: [Wallet]
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \SavingGoal.createdAt) private var goals: [SavingGoal]
    @State private var showingNewEntry = false
    @State private var showingSettings = false

    var body: some View {
        let thisMonth = MonthSummary(records: entries.map(\.record), month: .now)
        let activeGoals = goals.filter { !$0.plan().isDone }

        NavigationStack {
            List {
                Section {
                    BalanceCard(total: wallets.reduce(0) { $0 + $1.balance }, month: thisMonth)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Dompet") {
                    ForEach(wallets) { wallet in
                        HStack {
                            Image(systemName: wallet.symbol)
                                .foregroundStyle(.tint)
                                .frame(width: 28)
                            Text(wallet.name)
                            Spacer()
                            Text(Fmt.rupiah(wallet.balance))
                                .monospacedDigit()
                        }
                    }
                }

                if !activeGoals.isEmpty {
                    Section("Target tabungan") {
                        ForEach(activeGoals.prefix(3)) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                GoalRow(goal: goal)
                            }
                        }
                    }
                }

                Section("Transaksi terbaru") {
                    if entries.isEmpty {
                        Text("Belum ada transaksi. Ketuk + untuk mencatat.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entries.prefix(5)) { entry in
                        EntryRow(entry: entry, showsDate: true)
                    }
                }
            }
            .navigationTitle("VALORE")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Pengaturan")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewEntry = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Catat transaksi")
                }
            }
            .sheet(isPresented: $showingNewEntry) { EntryFormView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }
}

private struct BalanceCard: View {
    let total: Int
    let month: MonthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total saldo")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(Fmt.rupiah(total))
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            HStack(spacing: 12) {
                stat("Masuk bulan ini", month.income, symbol: "arrow.down.circle.fill")
                stat("Keluar bulan ini", month.expense, symbol: "arrow.up.circle.fill")
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func stat(_ title: String, _ amount: Int, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Text(Fmt.rupiah(amount))
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HomeView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
