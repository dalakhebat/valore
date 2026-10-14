import SwiftUI

/// Input nominal rupiah dengan pemisah ribuan otomatis.
struct RupiahField: View {
    @Binding var amount: Int
    var prompt = "0"
    /// Versi besar di tengah, untuk form utama.
    var large = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("Rp")
                .font(large ? .title2.weight(.semibold) : .title3.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(prompt, text: text)
                .keyboardType(.numberPad)
                .font(.system(size: large ? 44 : 28, weight: .bold))
                .monospacedDigit()
                .fixedSize(horizontal: large, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: large ? .center : .leading)
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
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(category.color)
            .frame(width: size, height: size)
            .background(category.color.opacity(0.16), in: Circle())
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
                    .font(.body.weight(.medium))
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
                .font(.callout.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? Palette.positive : Color.primary)
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
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundStyle(pace.color)
            .background(pace.color.opacity(0.16), in: Capsule())
    }
}

/// Busur setengah lingkaran (kiri → atas → kanan), dipakai untuk gauge progres.
struct SemicircleArc: Shape {
    var progress: Double
    var lineWidth: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = max(min(rect.width / 2 - lineWidth / 2, rect.height - lineWidth), 0)
        let center = CGPoint(x: rect.midX, y: rect.maxY - lineWidth / 2)
        var path = Path()
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(180), endAngle: .degrees(180 + 180 * min(max(progress, 0), 1)),
                    clockwise: false)
        return path
    }
}

struct HalfGauge<Content: View>: View {
    let progress: Double
    var color: Color
    var lineWidth: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            SemicircleArc(progress: 1, lineWidth: lineWidth)
                .stroke(color.opacity(0.18), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            SemicircleArc(progress: progress, lineWidth: lineWidth)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .animation(.easeOut, value: progress)
            content
        }
        .aspectRatio(2, contentMode: .fit)
    }
}

extension HalfGauge where Content == EmptyView {
    init(progress: Double, color: Color, lineWidth: CGFloat = 12) {
        self.init(progress: progress, color: color, lineWidth: lineWidth) { EmptyView() }
    }
}

/// Kartu target tabungan: persentase besar + gauge setengah lingkaran.
struct GoalCard: View {
    let goal: SavingGoal
    /// Versi sempit untuk deretan horizontal di Beranda.
    var compact = false

    var body: some View {
        let plan = goal.plan()
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: goal.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(plan.pace.color)
                    .frame(width: 34, height: 34)
                    .background(plan.pace.color.opacity(0.16), in: Circle())
                Text(goal.name)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if !compact { PaceBadge(pace: plan.pace) }
            }
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: compact ? 30 : 36, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.primary)
                    Text("\(Fmt.compactRupiah(plan.saved)) dari \(Fmt.compactRupiah(plan.target))")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                HalfGauge(progress: plan.progress, color: plan.pace.color, lineWidth: compact ? 9 : 11)
                    .frame(width: compact ? 72 : 100)
            }
            if compact { PaceBadge(pace: plan.pace) }
        }
        .card()
    }
}

/// Tombol ikon bulat putih di header.
struct CircleIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
                .background(Palette.card, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct QuickActionButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let accessibilityText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 58, height: 58)
                    .background(tint, in: Circle())
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    /// Latar saat tidak dipilih; pakai `Palette.background` kalau chip berada di dalam kartu.
    var unselectedFill: Color = Palette.card
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .foregroundStyle(isSelected ? Palette.onInk : Color.primary)
                .background(isSelected ? Palette.ink : unselectedFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SectionTitle<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            trailing
        }
    }
}

extension SectionTitle where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
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
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 42, height: 42)
                        .foregroundStyle(isSelected ? Palette.onInk : Color.primary)
                        .background(isSelected ? Palette.ink : Palette.background, in: Circle())
                }
                .buttonStyle(.borderless)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
