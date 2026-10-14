import Charts
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
                VStack(spacing: 16) {
                    monthSwitcher
                    HStack(spacing: 10) {
                        StatTile(title: "Pemasukan", value: Fmt.compactRupiah(summary.income), fill: Palette.green)
                        StatTile(title: "Pengeluaran", value: Fmt.compactRupiah(summary.expense), fill: Palette.peach)
                        StatTile(title: "Selisih", value: (summary.net > 0 ? "+" : "") + Fmt.compactRupiah(summary.net), fill: Palette.sky)
                    }
                    categoryCard(summary)
                    trendCard(trend)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(Palette.background)
            .navigationTitle("Ringkasan")
        }
    }

    private var monthSwitcher: some View {
        let isCurrentMonth = Calendar.current.isDate(month, equalTo: .now, toGranularity: .month)
        return HStack {
            CircleIconButton(symbol: "chevron.left", label: "Bulan sebelumnya") { shiftMonth(by: -1) }
            Spacer()
            Text(Fmt.month(month))
                .font(.headline)
            Spacer()
            CircleIconButton(symbol: "chevron.right", label: "Bulan berikutnya") { shiftMonth(by: 1) }
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.3 : 1)
        }
    }

    private func categoryCard(_ summary: MonthSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pengeluaran per kategori")
                .font(.headline)
            if summary.expenseByCategory.isEmpty {
                Text("Belum ada pengeluaran di bulan ini.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ZStack {
                    Chart(summary.expenseByCategory) { item in
                        SectorMark(angle: .value("Jumlah", item.amount), innerRadius: .ratio(0.64), angularInset: 2)
                            .cornerRadius(5)
                            .foregroundStyle(item.category.color)
                    }
                    VStack(spacing: 2) {
                        Text("Total keluar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Fmt.compactRupiah(summary.expense))
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                    }
                }
                .frame(height: 210)

                VStack(spacing: 0) {
                    ForEach(Array(summary.expenseByCategory.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { Divider().padding(.leading, 48) }
                        HStack(spacing: 12) {
                            CategoryIcon(category: item.category, size: 36)
                            Text(item.category.label)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(Fmt.rupiah(item.amount))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                Text(item.share, format: .percent.precision(.fractionLength(0)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 9)
                    }
                }
            }
        }
        .card()
    }

    private func trendCard(_ trend: [MonthTotal]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("6 bulan terakhir")
                .font(.headline)
            Chart(trend) { month in
                LineMark(x: .value("Bulan", month.month, unit: .month), y: .value("Jumlah", month.income))
                    .foregroundStyle(by: .value("Jenis", "Masuk"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(40)
                LineMark(x: .value("Bulan", month.month, unit: .month), y: .value("Jumlah", month.expense))
                    .foregroundStyle(by: .value("Jenis", "Keluar"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(40)
            }
            .chartForegroundStyleScale(["Masuk": Palette.positive, "Keluar": Palette.coral])
            .chartLegend(position: .top, alignment: .leading)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    AxisValueLabel {
                        if let amount = value.as(Int.self) {
                            Text(Fmt.compact(amount))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .card()
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
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .card(fill, padding: 14, radius: 20)
    }
}

#Preview {
    SummaryView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
