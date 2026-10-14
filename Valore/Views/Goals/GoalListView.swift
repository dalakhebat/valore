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
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            LabeledContent("Total terkumpul", value: Fmt.rupiah(goals.reduce(0) { $0 + $1.saved }))
                                .monospacedDigit()
                        }
                        Section {
                            ForEach(goals) { goal in
                                NavigationLink {
                                    GoalDetailView(goal: goal)
                                } label: {
                                    GoalRow(goal: goal)
                                }
                            }
                        }
                    }
                }
            }
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
}

#Preview {
    GoalListView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
