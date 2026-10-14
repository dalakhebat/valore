import SwiftData
import SwiftUI

struct GoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let goal: SavingGoal

    @State private var cadence: SavingCadence = .monthly
    @State private var simulatedMonthly = 0
    @State private var showingDeposit = false
    @State private var showingEdit = false
    @State private var confirmingDelete = false

    var body: some View {
        // Setelah "Hapus target", view ini masih sempat dirender sekali saat animasi kembali;
        // membaca properti model yang sudah dihapus bisa crash.
        if goal.isDeleted || goal.modelContext == nil {
            Color.clear
        } else {
            content
        }
    }

    private var content: some View {
        let plan = goal.plan()
        let deposits = (goal.deposits ?? []).sorted { $0.date > $1.date }

        return List {
            Section {
                VStack(spacing: 10) {
                    ProgressRing(progress: plan.progress, color: plan.pace.color) {
                        VStack(spacing: 4) {
                            Image(systemName: goal.symbol)
                                .font(.title2)
                                .foregroundStyle(plan.pace.color)
                            Text(plan.progress, format: .percent.precision(.fractionLength(0)))
                                .font(.system(.title, design: .rounded).weight(.bold))
                        }
                    }
                    .frame(width: 150, height: 150)
                    .padding(.bottom, 6)

                    Text(Fmt.rupiah(plan.saved))
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Text("dari \(Fmt.rupiah(plan.target))")
                        .foregroundStyle(.secondary)
                    PaceBadge(pace: plan.pace)

                    // Di header, bukan toolbar .bottomBar: bottom bar tertutup tab bar.
                    Button {
                        showingDeposit = true
                    } label: {
                        Label("Setor / Tarik", systemImage: "plus.circle.fill")
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Rencana") {
                planContent(plan)
            }

            Section("Riwayat setoran") {
                if deposits.isEmpty {
                    Text("Belum ada setoran.")
                        .foregroundStyle(.secondary)
                }
                ForEach(deposits) { deposit in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(deposit.note.isEmpty ? (deposit.amount >= 0 ? "Setoran" : "Penarikan") : deposit.note)
                            Text(Fmt.day(deposit.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Fmt.rupiah(deposit.amount, signed: true))
                            .monospacedDigit()
                            .foregroundStyle(deposit.amount >= 0 ? Color.green : Color.red)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(deposits[index]) }
                    try? context.save()
                }
            }
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Ubah target", systemImage: "pencil") }
                    Button(role: .destructive) { confirmingDelete = true } label: { Label("Hapus target", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingDeposit) { DepositFormView(goal: goal) }
        .sheet(isPresented: $showingEdit) { GoalFormView(goal: goal) }
        .confirmationDialog("Hapus target \"\(goal.name)\"?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Hapus target & riwayat setoran", role: .destructive) {
                dismiss()
                context.delete(goal)
                try? context.save()
            }
        }
    }

    @ViewBuilder
    private func planContent(_ plan: SavingsPlan) -> some View {
        if plan.isDone {
            Label("Target tercapai. Mantap!", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        } else if let deadline = goal.deadline {
            LabeledContent("Tenggat", value: Fmt.day(deadline))
            LabeledContent("Kurang", value: Fmt.rupiah(plan.remaining))
                .monospacedDigit()

            if plan.isOverdue {
                Text("Tenggat sudah lewat. Ubah tenggatnya supaya rencana dihitung ulang.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Frekuensi", selection: $cadence) {
                    ForEach(SavingCadence.allCases) { cadence in
                        Text(cadence.label).tag(cadence)
                    }
                }
                .pickerStyle(.segmented)

                if let perPeriod = plan.requiredPerPeriod(cadence), let periods = plan.periodsLeft(cadence) {
                    LabeledContent("Harus nabung") {
                        Text("\(Fmt.rupiah(perPeriod)) \(cadence.perLabel)")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    Text("Masih \(periods) \(cadence.unitLabel) lagi sampai tenggat.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let expected = plan.expectedByNow {
                    Text("Kalau nabung rata dari awal, per hari ini idealnya sudah terkumpul \(Fmt.rupiah(expected)).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            LabeledContent("Kurang", value: Fmt.rupiah(plan.remaining))
                .monospacedDigit()
            VStack(alignment: .leading, spacing: 4) {
                Text("Simulasi: kalau nabung per bulan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                RupiahField(amount: $simulatedMonthly)
            }
            if let months = plan.monthsToReach(saving: simulatedMonthly), let date = plan.projectedDate(saving: simulatedMonthly) {
                Text("Tercapai sekitar \(months) bulan lagi, kira-kira \(Fmt.month(date)).")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let container = try! SampleData.makeContainer()
    let goal = try! container.mainContext.fetch(FetchDescriptor<SavingGoal>()).first!
    return NavigationStack { GoalDetailView(goal: goal) }
        .modelContainer(container)
        .environment(\.locale, Fmt.locale)
}
