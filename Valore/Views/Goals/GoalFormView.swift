import SwiftData
import SwiftUI

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    static let symbols = [
        "star.fill", "house.fill", "car.fill", "airplane", "graduationcap.fill", "laptopcomputer",
        "iphone", "gift.fill", "heart.fill", "cross.case.fill", "banknote.fill", "shield.fill",
    ]

    private let goal: SavingGoal?
    @State private var name: String
    @State private var symbol: String
    @State private var target: Int
    @State private var hasDeadline: Bool
    @State private var deadline: Date

    init(goal: SavingGoal? = nil) {
        self.goal = goal
        _name = State(initialValue: goal?.name ?? "")
        _symbol = State(initialValue: goal?.symbol ?? "star.fill")
        _target = State(initialValue: goal?.target ?? 0)
        _hasDeadline = State(initialValue: goal == nil || goal?.deadline != nil)
        _deadline = State(initialValue: goal?.deadline ?? Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nama target (mis. Liburan, Dana darurat)", text: $name)
                    SymbolPicker(symbols: Self.symbols, selection: $symbol)
                }

                Section("Target") {
                    RupiahField(amount: $target)
                }

                Section {
                    Toggle("Pakai tenggat", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Tenggat", selection: $deadline, in: Date.now..., displayedComponents: .date)
                    }
                } footer: {
                    Text(hasDeadline
                         ? "VALORE akan menghitung harus nabung berapa per hari, minggu, atau bulan."
                         : "Tanpa tenggat, kamu bisa simulasi kapan target tercapai dari nominal nabung per bulan.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(goal == nil ? "Target baru" : "Ubah target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan", action: save)
                        .disabled(trimmedName.isEmpty || target <= 0)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let target: SavingGoal
        if let goal {
            target = goal
        } else {
            target = SavingGoal(name: trimmedName, target: self.target)
            context.insert(target)
        }
        target.name = trimmedName
        target.symbol = symbol
        target.target = self.target
        target.deadline = hasDeadline ? deadline : nil
        try? context.save()
        dismiss()
    }
}

#Preview {
    GoalFormView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
