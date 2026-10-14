import Foundation
import Testing
@testable import Valore

struct MonthSummaryTests {
    private let records = [
        EntryRecord(amount: 9_000_000, kind: .income, category: .gaji, date: date(2026, 10, 1, hour: 0)),
        EntryRecord(amount: 50_000, kind: .expense, category: .makan, date: date(2026, 10, 2)),
        EntryRecord(amount: 30_000, kind: .expense, category: .makan, date: date(2026, 10, 9)),
        EntryRecord(amount: 1_500_000, kind: .expense, category: .tagihan, date: date(2026, 10, 3)),
        EntryRecord(amount: 999_000, kind: .expense, category: .belanja, date: date(2026, 9, 30, hour: 23, minute: 59)),
        EntryRecord(amount: 777_000, kind: .expense, category: .belanja, date: date(2026, 11, 1, hour: 0)),
        EntryRecord(amount: 8_500_000, kind: .income, category: .gaji, date: date(2026, 9, 1)),
    ]

    @Test func totalsOnlyCountTheMonth() {
        let summary = MonthSummary(records: records, month: date(2026, 10, 20), calendar: wib)
        #expect(summary.income == 9_000_000)
        #expect(summary.expense == 1_580_000)
        #expect(summary.net == 7_420_000)
    }

    @Test func categoriesSortedByAmount() {
        let summary = MonthSummary(records: records, month: date(2026, 10, 20), calendar: wib)
        #expect(summary.expenseByCategory.map(\.category) == [.tagihan, .makan])
        #expect(summary.expenseByCategory.map(\.amount) == [1_500_000, 80_000])
        let shares = summary.expenseByCategory.reduce(0) { $0 + $1.share }
        #expect(abs(shares - 1) < 0.000_001)
    }

    @Test func emptyMonth() {
        let summary = MonthSummary(records: records, month: date(2026, 6, 1), calendar: wib)
        #expect(summary.income == 0)
        #expect(summary.expense == 0)
        #expect(summary.expenseByCategory.isEmpty)
    }

    @Test func trendIsOldestFirst() {
        let trend = MonthTotal.trend(records: records, endingAt: date(2026, 10, 14), count: 3, calendar: wib)
        #expect(trend.map(\.month) == [date(2026, 8, 1, hour: 0), date(2026, 9, 1, hour: 0), date(2026, 10, 1, hour: 0)])
        #expect(trend.map(\.income) == [0, 8_500_000, 9_000_000])
        #expect(trend.map(\.expense) == [0, 999_000, 1_580_000])
    }
}
