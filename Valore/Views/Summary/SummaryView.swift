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
            List {
                Section {
                    monthSwitcher
                    LabeledContent("Pemasukan", value: Fmt.rupiah(summary.income))
                    LabeledContent("Pengeluaran", value: Fmt.rupiah(summary.expense))
                    LabeledContent("Selisih") {
                        Text(Fmt.rupiah(summary.net, signed: true))
                            .fontWeight(.semibold)
                            .foregroundStyle(summary.net >= 0 ? Color.green : Color.red)
                    }
                }
                .monospacedDigit()

                Section("Pengeluaran per kategori") {
                    if summary.expenseByCategory.isEmpty {
                        Text("Belum ada pengeluaran di bulan ini.")
                            .foregroundStyle(.secondary)
                    } else {
                        CategoryDonut(summary: summary)
                            .frame(height: 220)
                            .padding(.vertical, 8)
                        ForEach(summary.expenseByCategory) { item in
                            HStack(spacing: 12) {
                                CategoryIcon(category: item.category)
                                Text(item.category.label)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(Fmt.rupiah(item.amount))
                                        .monospacedDigit()
                                    Text(item.share, format: .percent.precision(.fractionLength(0)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("6 bulan terakhir") {
                    TrendChart(trend: trend)
                        .frame(height: 200)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Ringkasan")
        }
    }

    private var monthSwitcher: some View {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(month, equalTo: .now, toGranularity: .month)
        return HStack {
            Button { shiftMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Bulan sebelumnya")
            Spacer()
            Text(Fmt.month(month))
                .font(.headline)
            Spacer()
            Button { shiftMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                .disabled(isCurrentMonth)
                .accessibilityLabel("Bulan berikutnya")
        }
        .buttonStyle(.borderless)
    }

    private func shiftMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: month) {
            month = newMonth
        }
    }
}

private struct CategoryDonut: View {
    let summary: MonthSummary

    var body: some View {
        ZStack {
            Chart(summary.expenseByCategory) { item in
                SectorMark(angle: .value("Jumlah", item.amount), innerRadius: .ratio(0.62), angularInset: 1.5)
                    .cornerRadius(4)
                    .foregroundStyle(item.category.color)
            }
            VStack(spacing: 2) {
                Text("Total keluar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Fmt.compactRupiah(summary.expense))
                    .font(.headline)
                    .monospacedDigit()
            }
        }
    }
}

private struct TrendChart: View {
    let trend: [MonthTotal]

    var body: some View {
        Chart(trend) { month in
            BarMark(x: .value("Bulan", month.month, unit: .month), y: .value("Jumlah", month.income))
                .foregroundStyle(by: .value("Jenis", "Masuk"))
                .position(by: .value("Jenis", "Masuk"))
            BarMark(x: .value("Bulan", month.month, unit: .month), y: .value("Jumlah", month.expense))
                .foregroundStyle(by: .value("Jenis", "Keluar"))
                .position(by: .value("Jenis", "Keluar"))
        }
        .chartForegroundStyleScale(["Masuk": Color.green, "Keluar": Color.red])
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Int.self) {
                        Text(Fmt.compact(amount))
                    }
                }
            }
        }
    }
}

#Preview {
    SummaryView()
        .modelContainer(try! SampleData.makeContainer())
        .environment(\.locale, Fmt.locale)
}
