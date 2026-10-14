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

        return ScrollView {
            VStack(spacing: 16) {
                hero(plan)
                planCard(plan)
                historyCard(deposits)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.background)
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Ubah target", systemImage: "pencil") }
                    Button(role: .destructive) { confirmingDelete = true } label: { Label("Hapus target", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Opsi target")
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

    private func hero(_ plan: SavingsPlan) -> some View {
        VStack(spacing: 10) {
            HalfGauge(progress: plan.progress, color: plan.pace.color, lineWidth: 16) {
                VStack(spacing: 2) {
                    Image(systemName: goal.symbol)
                        .font(.title3)
                        .foregroundStyle(plan.pace.color)
                    Text(plan.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 40, weight: .bold))
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: 230)
            .padding(.top, 4)

            Text(Fmt.rupiah(plan.saved))
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text("dari \(Fmt.rupiah(plan.target))")
                .foregroundStyle(.secondary)
            PaceBadge(pace: plan.pace)

            Button { showingDeposit = true } label: {
                Label("Setor / Tarik", systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .card(Palette.sky, padding: 22)
    }

    private func planCard(_ plan: SavingsPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Rencana")
                .font(.headline)

            if plan.isDone {
                Label("Target tercapai.", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Palette.positive)
            } else if let deadline = goal.deadline {
                infoRow("Tenggat", Fmt.day(deadline))
                Divider()
                infoRow("Kurang", Fmt.rupiah(plan.remaining))

                if plan.isOverdue {
                    Text("Tenggat sudah lewat. Ubah tenggatnya supaya rencana dihitung ulang.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Frekuensi", selection: $cadence) {
                        ForEach(SavingCadence.allCases) { cadence in
                            Text(cadence.label).tag(cadence)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let perPeriod = plan.requiredPerPeriod(cadence), let periods = plan.periodsLeft(cadence) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Harus nabung")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(Fmt.rupiah(perPeriod))
                                    .font(.system(size: 28, weight: .bold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text(cadence.perLabel)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Masih \(periods) \(cadence.unitLabel) lagi sampai tenggat.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .card(Palette.yellow, padding: 16, radius: 20)
                    }
                    if let expected = plan.expectedByNow {
                        Text("Kalau nabung rata dari awal, per hari ini idealnya sudah terkumpul \(Fmt.rupiah(expected)).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                infoRow("Kurang", Fmt.rupiah(plan.remaining))
                VStack(alignment: .leading, spacing: 8) {
                    Text("Simulasi: kalau nabung per bulan")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    RupiahField(amount: $simulatedMonthly)
                    if let months = plan.monthsToReach(saving: simulatedMonthly), let date = plan.projectedDate(saving: simulatedMonthly) {
                        Text("Tercapai sekitar \(months) bulan lagi, kira-kira \(Fmt.month(date)).")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .card(Palette.yellow, padding: 16, radius: 20)
            }
        }
        .card()
    }

    private func historyCard(_ deposits: [GoalDeposit]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Riwayat setoran")
                .font(.headline)
                .padding(.bottom, 10)
            if deposits.isEmpty {
                Text("Belum ada setoran.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(deposits.enumerated()), id: \.element.id) { index, deposit in
                if index > 0 { Divider() }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(deposit.note.isEmpty ? (deposit.amount >= 0 ? "Setoran" : "Penarikan") : deposit.note)
                            .font(.subheadline.weight(.medium))
                        Text(Fmt.day(deposit.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(Fmt.rupiah(deposit.amount, signed: true))
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(deposit.amount >= 0 ? Palette.positive : Palette.coral)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .contextMenu {
                    Button(role: .destructive) {
                        context.delete(deposit)
                        try? context.save()
                    } label: {
                        Label("Hapus setoran", systemImage: "trash")
                    }
                }
            }
            if !deposits.isEmpty {
                Text("Tekan lama untuk menghapus setoran.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 6)
            }
        }
        .card()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}

#Preview {
    let container = try! SampleData.makeContainer()
    let goal = try! container.mainContext.fetch(FetchDescriptor<SavingGoal>()).first!
    return NavigationStack { GoalDetailView(goal: goal) }
        .modelContainer(container)
        .environment(\.locale, Fmt.locale)
}
