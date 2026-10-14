import SwiftData
import SwiftUI

struct DepositFormView: View {
    private enum Direction: String, CaseIterable, Identifiable {
        case deposit = "Setor"
        case withdraw = "Tarik"

        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \SavingGoal.createdAt) private var goals: [SavingGoal]

    /// Dari halaman detail target sudah pasti; dari Beranda dipilih di form ini.
    private let fixedGoal: Bool
    @State private var goal: SavingGoal?
    @State private var direction = Direction.deposit
    @State private var amount = 0
    @State private var date = Date.now
    @State private var note = ""

    init(goal: SavingGoal? = nil) {
        fixedGoal = goal != nil
        _goal = State(initialValue: goal)
    }

    var body: some View {
        let saved = goal?.saved ?? 0
        let exceedsSaved = direction == .withdraw && amount > saved

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if !fixedGoal {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Target")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(goals) { option in
                                        FilterChip(title: option.name, isSelected: option == goal, unselectedFill: Palette.background) {
                                            goal = option
                                        }
                                    }
                                }
                            }
                        }
                        .card()
                    }

                    Picker("Jenis", selection: $direction) {
                        ForEach(Direction.allCases) { direction in
                            Text(direction.rawValue).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 8) {
                        RupiahField(amount: $amount, large: true)
                        if exceedsSaved {
                            Text("Lebih besar dari yang sudah terkumpul (\(Fmt.rupiah(saved))).")
                                .font(.footnote)
                                .foregroundStyle(Palette.coral)
                        } else if let goal {
                            Text("Terkumpul \(Fmt.rupiah(goal.saved)) dari \(Fmt.rupiah(goal.target))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 14)
                    .card()

                    VStack(spacing: 0) {
                        DatePicker("Tanggal", selection: $date, displayedComponents: .date)
                            .padding(.vertical, 6)
                        Divider()
                        TextField("Catatan (opsional)", text: $note)
                            .padding(.vertical, 12)
                    }
                    .card(padding: 16)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Palette.background)
            .safeAreaInset(edge: .bottom) {
                Button("Simpan", action: save)
                    .buttonStyle(InkButtonStyle(fullWidth: true))
                    .disabled(goal == nil || amount <= 0 || exceedsSaved)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Palette.background)
            }
            .navigationTitle(fixedGoal ? (goal?.name ?? "") : "Setor tabungan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
            }
            .onAppear {
                if goal == nil {
                    goal = goals.first { !$0.plan().isDone } ?? goals.first
                }
            }
        }
    }

    private func save() {
        guard let goal else { return }
        let deposit = GoalDeposit(
            amount: direction == .deposit ? amount : -amount,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(deposit)
        deposit.goal = goal
        try? context.save()
        dismiss()
    }
}
