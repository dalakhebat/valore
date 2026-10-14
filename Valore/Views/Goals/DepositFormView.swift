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

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: fixedGoal ? (goal?.name ?? "Setor") : "Setor tabungan") { dismiss() }

                if !fixedGoal {
                    VStack(alignment: .leading, spacing: 12) {
                        FieldLabel("Target")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(goals) { option in
                                    FilterChip(title: option.name, isSelected: option == goal) { goal = option }
                                }
                            }
                            .padding(.vertical, 2)
                            .padding(.trailing, 4)
                        }
                    }
                    .brut()
                }

                BrutSegmented(options: Direction.allCases, selection: $direction) { $0.rawValue }

                VStack(spacing: 8) {
                    FieldLabel("Jumlah")
                    RupiahField(amount: $amount, large: true)
                    if exceedsSaved {
                        Sticker(text: "Lebih dari yang terkumpul (\(Fmt.rupiah(saved)))", fill: Permen.pinkSoft)
                    } else if let goal {
                        Text("Terkumpul \(Fmt.rupiah(goal.saved)) dari \(Fmt.rupiah(goal.target))")
                            .font(.nunito(13, .bold))
                            .foregroundStyle(Permen.muted)
                    }
                }
                .frame(maxWidth: .infinity)
                .brut(padding: 18)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        FieldLabel("Tanggal")
                        Spacer()
                        DatePicker("Tanggal", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                    }
                    FieldLabel("Catatan")
                    BrutTextField(prompt: "Opsional", text: $note)
                }
                .brut()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PermenBackground())
        .safeAreaInset(edge: .bottom) {
            Button("Simpan", action: save)
                .buttonStyle(BrutButtonStyle(fullWidth: true))
                .disabled(goal == nil || amount <= 0 || exceedsSaved)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Permen.bg)
        }
        .onAppear {
            if goal == nil {
                goal = goals.first { !$0.plan().isDone } ?? goals.first
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
