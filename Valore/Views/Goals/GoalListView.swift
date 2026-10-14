import SwiftData
import SwiftUI

struct GoalListView: View {
    @Query(sort: \SavingGoal.createdAt) private var goals: [SavingGoal]
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(title: "Tabungan") {
                        BrutIconButton(symbol: "plus", label: "Bikin target", fill: Permen.cyan) { showingNew = true }
                    }

                    if goals.isEmpty {
                        EmptyCard(
                            symbol: "target",
                            title: "Belum ada target",
                            message: "Bikin target tabungan, nanti VALORE hitung harus nabung berapa per minggu atau per bulan.",
                            actionTitle: "Bikin target",
                            action: { showingNew = true }
                        )
                    } else {
                        totalCard
                        ForEach(goals) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                GoalCard(goal: goal)
                            }
                            .buttonStyle(BrutPressStyle(fill: Permen.surface, radius: Permen.radiusCard))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(PermenBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingNew) { GoalFormView() }
        }
    }

    private var totalCard: some View {
        let reached = goals.filter { $0.plan().isDone }.count
        return VStack(alignment: .leading, spacing: 6) {
            FieldLabel("Total terkumpul")
            Text(Fmt.rupiah(goals.reduce(0) { $0 + $1.saved }))
                .font(.nunito(34, .black))
                .foregroundStyle(Permen.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 6) {
                Sticker(text: "\(goals.count) target")
                Sticker(text: "\(reached) tercapai", fill: reached > 0 ? Permen.lemon : Permen.surface)
            }
        }
        .brut(Permen.mint, padding: 18)
    }
}

#Preview {
    GoalListView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
