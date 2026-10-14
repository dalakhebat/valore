import SwiftUI

// MARK: - Teks

/// Label huruf besar kecil di atas isian/bagian (11pt, tebal, renggang).
struct FieldLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.jakarta(11, .extraBold, relativeTo: .caption))
            .tracking(0.8)
            .foregroundStyle(Permen.muted)
    }
}

/// Judul halaman (huruf kapital tebal) dengan aksi di kanan.
struct ScreenHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center) {
            Text(title.uppercased())
                .font(.heading(30))
                .tracking(-0.2)
                .foregroundStyle(Permen.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            trailing
        }
    }
}

/// Judul bagian (huruf kapital tebal) dengan aksi di kanan.
struct SectionTitle<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.heading(20, relativeTo: .title2))
                .tracking(-0.2)
                .foregroundStyle(Permen.ink)
                .accessibilityAddTraits(.isHeader)
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

/// Kepala lembar (sheet): judul + tombol tutup.
struct SheetHeader: View {
    let title: String
    var closeTitle = "Batal"
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text(title.uppercased())
                .font(.heading(24, relativeTo: .title))
                .tracking(-0.2)
                .foregroundStyle(Permen.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: onClose) {
                Text(closeTitle)
                    .font(.jakarta(15, .bold))
                    .foregroundStyle(Permen.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(BrutPressStyle(fill: Permen.surface, radius: 999, shadow: 2))
        }
        .padding(.top, 8)
    }
}

/// Link teks bergaris bawah.
struct InkLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.jakarta(14, .bold))
                .underline(true, color: Permen.ink)
                .foregroundStyle(Permen.ink)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stiker & chip

/// Label kecil berbentuk pil dengan garis tinta.
struct Sticker: View {
    let text: String
    var fill: Color = Permen.surface

    var body: some View {
        Text(text)
            .font(.jakarta(11, .bold, relativeTo: .caption))
            .foregroundStyle(Permen.ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(Permen.ink, lineWidth: 1.5))
            .fixedSize()
    }
}

struct PaceBadge: View {
    let pace: GoalPace

    var body: some View {
        Sticker(text: pace.label, fill: pace.stickerFill)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.jakarta(14, .bold))
                .foregroundStyle(Permen.ink)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .buttonStyle(BrutPressStyle(fill: isSelected ? Permen.cyan : Permen.surface, radius: 999, shadow: isSelected ? 2 : 0))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Pilihan 2–3 opsi ala tab, versi brutal.
struct BrutSegmented<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button { selection = option } label: {
                    Text(label(option))
                        .font(.jakarta(14, .bold))
                        .foregroundStyle(Permen.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isSelected ? Permen.lemon : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Permen.ink, lineWidth: isSelected ? 1.5 : 0)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(5)
        .background(BrutShape(fill: Permen.surface, radius: Permen.radiusField, shadow: 0))
    }
}

// MARK: - Input

/// Input nominal rupiah dengan pemisah ribuan otomatis.
struct RupiahField: View {
    @Binding var amount: Int
    var prompt = "0"
    /// Versi besar di tengah, untuk form utama.
    var large = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("Rp")
                .font(.jakarta(large ? 22 : 18, .bold))
                .foregroundStyle(Permen.muted)
            TextField(prompt, text: text)
                .keyboardType(.numberPad)
                .font(.jakarta(large ? 46 : 28, .extraBold))
                .foregroundStyle(Permen.ink)
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

/// Isian teks bergaris tinta; saat fokus muncul bayangan cyan.
struct BrutTextField: View {
    let prompt: String
    @Binding var text: String
    var axis: Axis = .horizontal
    @FocusState private var focused: Bool

    var body: some View {
        TextField(prompt, text: $text, axis: axis)
            .font(.jakarta(16, .medium))
            .foregroundStyle(Permen.ink)
            .focused($focused)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    let shape = RoundedRectangle(cornerRadius: Permen.radiusField, style: .continuous)
                    if focused { shape.fill(Permen.cyan).offset(x: 3, y: 3) }
                    shape.fill(Permen.surface)
                    shape.strokeBorder(Permen.ink, lineWidth: Permen.line)
                }
            )
    }
}

// MARK: - Progres

struct BrutProgressBar: View {
    let progress: Double
    var fill: Color = Permen.cyan
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Permen.surface)
                if clamped > 0 {
                    Capsule()
                        .fill(fill)
                        .frame(width: max(proxy.size.width * clamped, height))
                        .overlay(Capsule().strokeBorder(Permen.ink, lineWidth: 1.5))
                }
                Capsule().strokeBorder(Permen.ink, lineWidth: Permen.line)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

/// Busur setengah lingkaran (kiri → atas → kanan).
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

/// Gauge setengah lingkaran bergaris tinta.
struct HalfGauge<Content: View>: View {
    let progress: Double
    var fill: Color
    var lineWidth: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            // Garis luar tinta, lalu jalur krem, lalu isi progres.
            SemicircleArc(progress: 1, lineWidth: lineWidth + 4)
                .stroke(Permen.ink, style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round))
            SemicircleArc(progress: 1, lineWidth: lineWidth + 4)
                .stroke(Permen.surface, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            if progress > 0 {
                SemicircleArc(progress: progress, lineWidth: lineWidth + 4)
                    .stroke(fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .animation(.easeOut, value: progress)
            }
            content
        }
        .aspectRatio(2, contentMode: .fit)
    }
}

// MARK: - Baris & kartu data

struct CategoryIcon: View {
    let category: EntryCategory
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundStyle(Permen.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(category.color))
            .overlay(Circle().strokeBorder(Permen.ink, lineWidth: 1.5))
    }
}

struct EntryRow: View {
    let entry: LedgerEntry
    var showsDate = false

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: entry.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.note.isEmpty ? entry.category.label : entry.note)
                    .font(.jakarta(16, .bold))
                    .foregroundStyle(Permen.ink)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.jakarta(12, .medium, relativeTo: .caption))
                        .foregroundStyle(Permen.muted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text(Fmt.rupiah(entry.signedAmount, signed: true))
                .font(.jakarta(16, .extraBold))
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? Permen.jade : Permen.ink)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts: [String] = []
        if showsDate { parts.append(Fmt.shortDay(entry.date)) }
        if !entry.note.isEmpty { parts.append(entry.category.label) }
        if let wallet = entry.wallet { parts.append(wallet.name) }
        return parts.joined(separator: " · ")
    }
}

/// Garis pemisah tinta di dalam kartu.
struct InkDivider: View {
    var body: some View {
        Rectangle()
            .fill(Permen.ink)
            .frame(height: 1.5)
    }
}

/// Kartu target tabungan: persentase besar + batang progres.
struct GoalCard: View {
    let goal: SavingGoal

    var body: some View {
        let plan = goal.plan()
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: goal.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Permen.ink)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(plan.pace.stickerFill))
                    .overlay(Circle().strokeBorder(Permen.ink, lineWidth: 1.5))
                Text(goal.name)
                    .font(.jakarta(17, .extraBold))
                    .foregroundStyle(Permen.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            HStack(alignment: .bottom) {
                Text(plan.progress, format: .percent.precision(.fractionLength(0)))
                    .font(.jakarta(34, .extraBold))
                    .foregroundStyle(Permen.ink)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 4) {
                    PaceBadge(pace: plan.pace)
                    Text("\(Fmt.compactRupiah(plan.saved)) / \(Fmt.compactRupiah(plan.target))")
                        .font(.jakarta(13, .semibold))
                        .foregroundStyle(Permen.muted)
                        .lineLimit(1)
                }
                .padding(.bottom, 6)
            }
            BrutProgressBar(progress: plan.progress, fill: plan.pace.barFill)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Tombol ikon bulat (garis + bayangan keras).
struct BrutIconButton: View {
    let symbol: String
    let label: String
    var fill: Color = Permen.surface
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(Permen.ink)
                .frame(width: size, height: size)
        }
        .buttonStyle(BrutPressStyle(fill: fill, radius: size / 2, shadow: 2))
        .accessibilityLabel(label)
    }
}

/// Ubin aksi cepat di Beranda.
struct QuickActionTile: View {
    let title: String
    let symbol: String
    let fill: Color
    let accessibilityText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .frame(height: 24)
                Text(title)
                    .font(.jakarta(13, .bold))
            }
            .foregroundStyle(Permen.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(BrutPressStyle(fill: fill, radius: Permen.radiusCard))
        .accessibilityLabel(accessibilityText)
    }
}

/// Kartu kosong dengan ajakan.
struct EmptyCard: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Permen.ink)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Permen.lemon))
                .overlay(Circle().strokeBorder(Permen.ink, lineWidth: Permen.line))
            Text(title)
                .font(.jakarta(18, .extraBold))
                .foregroundStyle(Permen.ink)
            Text(message)
                .font(.jakarta(14, .medium))
                .foregroundStyle(Permen.muted)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(BrutButtonStyle())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .brut(padding: 24)
    }
}

/// Pilihan ikon SF Symbol dalam bentuk grid.
struct SymbolPicker: View {
    let symbols: [String]
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 12) {
            ForEach(symbols, id: \.self) { symbol in
                let isSelected = symbol == selection
                Button { selection = symbol } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Permen.ink)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(BrutPressStyle(fill: isSelected ? Permen.lemon : Permen.surface, radius: 22, shadow: isSelected ? 2 : 0))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
