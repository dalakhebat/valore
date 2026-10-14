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
            VStack(alignment: .leading, spacing: 18) {
                hero(plan)
                planCard(plan)
                historyCard(deposits)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PermenBackground())
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
            HalfGauge(progress: plan.progress, fill: plan.pace.barFill) {
                VStack(spacing: 0) {
                    Image(systemName: goal.symbol)
                        .font(.system(size: 20, weight: .bold))
                    Text(plan.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.jakarta(42, .extraBold))
                }
                .foregroundStyle(Permen.ink)
            }
            .frame(maxWidth: 240)
            .padding(.top, 6)

            Text(Fmt.rupiah(plan.saved))
                .font(.jakarta(26, .extraBold))
                .foregroundStyle(Permen.ink)
            Text("dari \(Fmt.rupiah(plan.target))")
                .font(.jakarta(15, .semibold))
                .foregroundStyle(Permen.muted)
            PaceBadge(pace: plan.pace)

            Button { showingDeposit = true } label: {
                Label("Setor / Tarik", systemImage: "plus")
            }
            .buttonStyle(BrutButtonStyle(fill: Permen.lemon))
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .brut(Permen.cyanSoft, padding: 20)
    }

    private func planCard(_ plan: SavingsPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel("Rencana")

            if plan.isDone {
                Sticker(text: "Target tercapai", fill: Permen.mint)
            } else if let deadline = goal.deadline {
                infoRow("Tenggat", Fmt.day(deadline))
                InkDivider()
                infoRow("Kurang", Fmt.rupiah(plan.remaining))

                if plan.isOverdue {
                    Text("Tenggat sudah lewat. Ubah tenggatnya supaya rencana dihitung ulang.")
                        .font(.jakarta(14, .medium))
                        .foregroundStyle(Permen.pinkText)
                } else {
                    BrutSegmented(options: SavingCadence.allCases, selection: $cadence) { $0.label }

                    if let perPeriod = plan.requiredPerPeriod(cadence), let periods = plan.periodsLeft(cadence) {
                        VStack(alignment: .leading, spacing: 4) {
                            FieldLabel("Harus nabung")
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(Fmt.rupiah(perPeriod))
                                    .font(.jakarta(30, .extraBold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text(cadence.perLabel)
                                    .font(.jakarta(14, .semibold))
                            }
                            .foregroundStyle(Permen.ink)
                            Text("Masih \(periods) \(cadence.unitLabel) lagi sampai tenggat.")
                                .font(.jakarta(12, .medium, relativeTo: .caption))
                                .foregroundStyle(Permen.muted)
                        }
                        .brut(Permen.lemon, padding: 14, radius: Permen.radiusField, shadow: 0)
                    }
                    if let expected = plan.expectedByNow {
                        Text("Kalau nabung rata dari awal, per hari ini idealnya sudah terkumpul \(Fmt.rupiah(expected)).")
                            .font(.jakarta(13, .medium))
                            .foregroundStyle(Permen.muted)
                    }
                }
            } else {
                infoRow("Kurang", Fmt.rupiah(plan.remaining))
                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel("Simulasi nabung per bulan")
                    RupiahField(amount: $simulatedMonthly)
                    if let months = plan.monthsToReach(saving: simulatedMonthly), let date = plan.projectedDate(saving: simulatedMonthly) {
                        Text("Tercapai sekitar \(months) bulan lagi, kira-kira \(Fmt.month(date)).")
                            .font(.jakarta(14, .bold))
                            .foregroundStyle(Permen.ink)
                    }
                }
                .brut(Permen.lemon, padding: 14, radius: Permen.radiusField, shadow: 0)
            }
        }
        .brut()
    }

    private func historyCard(_ deposits: [GoalDeposit]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            FieldLabel("Riwayat setoran")
            if deposits.isEmpty {
                Text("Belum ada setoran.")
                    .font(.jakarta(14, .medium))
                    .foregroundStyle(Permen.muted)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(deposits.enumerated()), id: \.element.id) { index, deposit in
                        if index > 0 { InkDivider() }
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(deposit.note.isEmpty ? (deposit.amount >= 0 ? "Setoran" : "Penarikan") : deposit.note)
                                    .font(.jakarta(15, .bold))
                                Text(Fmt.day(deposit.date))
                                    .font(.jakarta(12, .medium, relativeTo: .caption))
                                    .foregroundStyle(Permen.muted)
                            }
                            Spacer()
                            Text(Fmt.rupiah(deposit.amount, signed: true))
                                .font(.jakarta(15, .extraBold))
                                .foregroundStyle(deposit.amount >= 0 ? Permen.jade : Permen.pinkText)
                        }
                        .foregroundStyle(Permen.ink)
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
                }
                Text("Tekan lama untuk menghapus setoran.")
                    .font(.jakarta(11, .medium, relativeTo: .caption))
                    .foregroundStyle(Permen.muted)
            }
        }
        .brut()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.jakarta(15, .medium))
                .foregroundStyle(Permen.muted)
            Spacer()
            Text(value)
                .font(.jakarta(15, .extraBold))
                .foregroundStyle(Permen.ink)
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
