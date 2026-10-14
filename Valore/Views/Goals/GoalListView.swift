import SwiftData
import SwiftUI

struct GoalListView: View {
    @Query(sort: \SavingGoal.createdAt) private var goals: [SavingGoal]
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    ContentUnavailableView {
                        Label("Belum ada target", systemImage: "target")
                    } description: {
                        Text("Bikin target tabungan, nanti VALORE hitung harus nabung berapa per minggu atau per bulan.")
                    } actions: {
                        Button("Bikin target") { showingNew = true }
                            .buttonStyle(InkButtonStyle())
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            totalCard
                            ForEach(goals) { goal in
                                NavigationLink {
                                    GoalDetailView(goal: goal)
                                } label: {
                                    GoalCard(goal: goal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
            .background(Palette.background)
            .navigationTitle("Tabungan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Bikin target")
                }
            }
            .sheet(isPresented: $showingNew) { GoalFormView() }
        }
    }

    private var totalCard: some View {
        let reached = goals.filter { $0.plan().isDone }.count
        return VStack(alignment: .leading, spacing: 6) {
            Text("Total terkumpul")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(Fmt.rupiah(goals.reduce(0) { $0 + $1.saved }))
                .font(.system(size: 32, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(goals.count) target · \(reached) tercapai")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card(Palette.green, padding: 20)
    }
}

#Preview {
    GoalListView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
