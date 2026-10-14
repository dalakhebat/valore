import SwiftUI

/// Input nominal rupiah dengan pemisah ribuan otomatis.
struct RupiahField: View {
    @Binding var amount: Int
    var prompt = "0"

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("Rp")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(prompt, text: text)
                .keyboardType(.numberPad)
                .font(.system(.title, design: .rounded).weight(.bold))
                .monospacedDigit()
        }
    }

    private var text: Binding<String> {
        Binding(
            get: { amount == 0 ? "" : Fmt.number(amount) },
            set: { amount = Fmt.parseAmount($0) }
        )
    }
}

struct CategoryIcon: View {
    let category: EntryCategory

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(category.color.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

struct EntryRow: View {
    let entry: LedgerEntry
    var showsDate = false

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: entry.category)
            // Warna eksplisit: di dalam Button (daftar transaksi) teks bawaan ikut warna tint.
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.note.isEmpty ? entry.category.label : entry.note)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text(Fmt.rupiah(entry.signedAmount, signed: true))
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? Color.green : Color.primary)
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if showsDate { parts.append(Fmt.shortDay(entry.date)) }
        if !entry.note.isEmpty { parts.append(entry.category.label) }
        if let wallet = entry.wallet { parts.append(wallet.name) }
        return parts.joined(separator: " · ")
    }
}

struct PaceBadge: View {
    let pace: GoalPace

    var body: some View {
        Text(pace.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(pace.color)
            .background(pace.color.opacity(0.15), in: Capsule())
    }
}

struct GoalRow: View {
    let goal: SavingGoal

    var body: some View {
        let plan = goal.plan()
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.symbol)
                    .foregroundStyle(.tint)
                Text(goal.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                PaceBadge(pace: plan.pace)
            }
            ProgressView(value: plan.progress)
                .tint(plan.pace.color)
            HStack {
                Text("\(Fmt.rupiah(plan.saved)) dari \(Fmt.rupiah(plan.target))")
                Spacer()
                Text(plan.progress, format: .percent.precision(.fractionLength(0)))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

struct ProgressRing<Content: View>: View {
    let progress: Double
    var color: Color = .accentColor
    var lineWidth: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            content
        }
    }
}

/// Pilihan ikon SF Symbol dalam bentuk grid.
struct SymbolPicker: View {
    let symbols: [String]
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(symbols, id: \.self) { symbol in
                let isSelected = symbol == selection
                Button {
                    selection = symbol
                } label: {
                    Image(systemName: symbol)
                        .font(.title3)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear, in: Circle())
                }
                .buttonStyle(.borderless)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
