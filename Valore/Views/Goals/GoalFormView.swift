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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetHeader(title: goal == nil ? "Target baru" : "Ubah target") { dismiss() }

                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel("Nama target")
                    BrutTextField(prompt: "Mis. Liburan, Dana darurat", text: $name)
                    FieldLabel("Ikon")
                        .padding(.top, 4)
                    SymbolPicker(symbols: Self.symbols, selection: $symbol)
                }
                .brut()

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel("Target")
                    RupiahField(amount: $target)
                }
                .brut()

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $hasDeadline) {
                        Text("Pakai tenggat")
                            .font(.nunito(16, .extraBold))
                            .foregroundStyle(Permen.ink)
                    }
                    .tint(Permen.cyan)
                    if hasDeadline {
                        HStack {
                            FieldLabel("Tenggat")
                            Spacer()
                            DatePicker("Tenggat", selection: $deadline, in: Date.now..., displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                    Text(hasDeadline
                         ? "VALORE akan menghitung harus nabung berapa per hari, minggu, atau bulan."
                         : "Tanpa tenggat, kamu bisa simulasi kapan target tercapai dari nominal nabung per bulan.")
                        .font(.nunito(13, .semibold))
                        .foregroundStyle(Permen.muted)
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
                .disabled(trimmedName.isEmpty || target <= 0)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Permen.bg)
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
