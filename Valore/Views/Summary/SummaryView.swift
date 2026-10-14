import SwiftData
import SwiftUI

struct SummaryView: View {
    @Query(sort: \LedgerEntry.date) private var entries: [LedgerEntry]
    @State private var month = Date.now

    var body: some View {
        let records = entries.map(\.record)
        let summary = MonthSummary(records: records, month: month)
        let trend = MonthTotal.trend(records: records, endingAt: month, count: 6)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ScreenHeader(title: "Ringkasan") { EmptyView() }
                    monthSwitcher
                    HStack(spacing: 12) {
                        StatTile(title: "Masuk", value: Fmt.compactRupiah(summary.income), fill: Permen.mint)
                        StatTile(title: "Keluar", value: Fmt.compactRupiah(summary.expense), fill: Permen.pinkSoft)
                        StatTile(title: "Selisih", value: (summary.net > 0 ? "+" : "") + Fmt.compactRupiah(summary.net), fill: Permen.cyanSoft)
                    }
                    categoryCard(summary)
                    trendCard(trend)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(PermenBackground())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var monthSwitcher: some View {
        let isCurrentMonth = Calendar.current.isDate(month, equalTo: .now, toGranularity: .month)
        return HStack {
            BrutIconButton(symbol: "chevron.left", label: "Bulan sebelumnya") { shiftMonth(by: -1) }
            Spacer()
            Text(Fmt.month(month))
                .font(.nunito(18, .black))
                .foregroundStyle(Permen.ink)
            Spacer()
            BrutIconButton(symbol: "chevron.right", label: "Bulan berikutnya") { shiftMonth(by: 1) }
                .disabled(isCurrentMonth)
        }
    }

    private func categoryCard(_ summary: MonthSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel("Pengeluaran per kategori")
            if summary.expenseByCategory.isEmpty {
                Text("Belum ada pengeluaran di bulan ini.")
                    .font(.nunito(14, .semibold))
                    .foregroundStyle(Permen.muted)
            } else {
                StackedShareBar(items: summary.expenseByCategory)
                VStack(spacing: 0) {
                    ForEach(Array(summary.expenseByCategory.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { InkDivider() }
                        HStack(spacing: 12) {
                            CategoryIcon(category: item.category, size: 36)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.category.label)
                                        .font(.nunito(15, .extraBold))
                                    Spacer()
                                    Text(Fmt.rupiah(item.amount))
                                        .font(.nunito(15, .black))
                                }
                                HStack(spacing: 8) {
                                    BrutProgressBar(progress: item.share, fill: item.category.color, height: 10)
                                    Text(item.share, format: .percent.precision(.fractionLength(0)))
                                        .font(.nunito(12, .extraBold, relativeTo: .caption))
                                        .foregroundStyle(Permen.muted)
                                        .frame(width: 36, alignment: .trailing)
                                }
                            }
                        }
                        .foregroundStyle(Permen.ink)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .brut()
    }

    private func trendCard(_ trend: [MonthTotal]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                FieldLabel("6 bulan terakhir")
                Spacer()
                Sticker(text: "Masuk", fill: Permen.mintStrong)
                Sticker(text: "Keluar", fill: Permen.pink)
            }
            TrendBars(trend: trend)
                .frame(height: 170)
        }
        .brut()
    }

    private func shiftMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: month) {
            month = newMonth
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let fill: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title)
            Text(value)
                .font(.nunito(18, .black))
                .foregroundStyle(Permen.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .brut(fill, padding: 12, radius: Permen.radiusField)
    }
}

/// Satu batang bersekat: porsi tiap kategori dari total pengeluaran.
private struct StackedShareBar: View {
    let items: [CategoryTotal]

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Rectangle()
                        .fill(item.category.color)
                        .frame(width: max(proxy.size.width * item.share, 2))
                        .overlay(alignment: .leading) {
                            if index > 0 { Rectangle().fill(Permen.ink).frame(width: 1.5) }
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Permen.ink, lineWidth: Permen.line))
        }
        .frame(height: 26)
        .accessibilityHidden(true)
    }
}

/// Batang masuk/keluar per bulan, digambar manual supaya bisa bergaris tinta.
private struct TrendBars: View {
    let trend: [MonthTotal]

    var body: some View {
        let peak = max(trend.map { max($0.income, $0.expense) }.max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(trend) { month in
                VStack(spacing: 6) {
                    HStack(alignment: .bottom, spacing: 3) {
                        bar(month.income, peak: peak, fill: Permen.mintStrong)
                        bar(month.expense, peak: peak, fill: Permen.pink)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    Text(month.month.formatted(.dateTime.month(.abbreviated).locale(Fmt.locale)))
                        .font(.nunito(11, .extraBold, relativeTo: .caption))
                        .foregroundStyle(Permen.ink)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(Fmt.month(month.month)))
                .accessibilityValue(Text("Masuk \(Fmt.rupiah(month.income)), keluar \(Fmt.rupiah(month.expense))"))
            }
        }
    }

    private func bar(_ value: Int, peak: Int, fill: Color) -> some View {
        GeometryReader { proxy in
            let height = max(proxy.size.height * CGFloat(value) / CGFloat(peak), value > 0 ? 6 : 2)
            VStack {
                Spacer(minLength: 0)
                UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5, style: .continuous)
                    .fill(fill)
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5, style: .continuous)
                            .stroke(Permen.ink, lineWidth: 1.5)
                    )
                    .frame(height: height)
            }
        }
    }
}

#Preview {
    SummaryView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
