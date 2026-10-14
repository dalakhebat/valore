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
    let goal: SavingGoal

    @State private var direction = Direction.deposit
    @State private var amount = 0
    @State private var date = Date.now
    @State private var note = ""

    var body: some View {
        let exceedsSaved = direction == .withdraw && amount > goal.saved

        NavigationStack {
            Form {
                Section {
                    Picker("Jenis", selection: $direction) {
                        ForEach(Direction.allCases) { direction in
                            Text(direction.rawValue).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    RupiahField(amount: $amount)
                } header: {
                    Text("Jumlah")
                } footer: {
                    if exceedsSaved {
                        Text("Lebih besar dari yang sudah terkumpul (\(Fmt.rupiah(goal.saved))).")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    DatePicker("Tanggal", selection: $date, displayedComponents: .date)
                    TextField("Catatan (opsional)", text: $note)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan", action: save)
                        .disabled(amount <= 0 || exceedsSaved)
                }
            }
        }
    }

    private func save() {
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
