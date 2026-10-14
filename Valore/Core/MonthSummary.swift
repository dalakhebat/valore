import Foundation

/// Bentuk polos sebuah transaksi, supaya ringkasan bisa dihitung & dites tanpa SwiftData.
struct EntryRecord: Equatable {
    var amount: Int
    var kind: EntryKind
    var category: EntryCategory
    var date: Date
}

struct CategoryTotal: Identifiable, Equatable {
    var category: EntryCategory
    var amount: Int
    /// Porsi dari total pengeluaran bulan itu, 0...1.
    var share: Double

    var id: EntryCategory { category }
}

struct MonthSummary: Equatable {
    var month: DateInterval
    var income: Int
    var expense: Int
    /// Urut dari kategori dengan pengeluaran terbesar.
    var expenseByCategory: [CategoryTotal]

    var net: Int { income - expense }

    init(records: [EntryRecord], month date: Date, calendar: Calendar = .current) {
        let interval = calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: date, duration: 0)
        let inMonth = records.filter { $0.date >= interval.start && $0.date < interval.end }

        var income = 0
        var expense = 0
        var byCategory: [EntryCategory: Int] = [:]
        for record in inMonth {
            switch record.kind {
            case .income:
                income += record.amount
            case .expense:
                expense += record.amount
                byCategory[record.category, default: 0] += record.amount
            }
        }

        self.month = interval
        self.income = income
        self.expense = expense
        self.expenseByCategory = byCategory
            .map { CategoryTotal(category: $0.key, amount: $0.value, share: expense > 0 ? Double($0.value) / Double(expense) : 0) }
            .sorted { $0.amount != $1.amount ? $0.amount > $1.amount : $0.category.rawValue < $1.category.rawValue }
    }
}

struct MonthTotal: Identifiable, Equatable {
    /// Awal bulan.
    var month: Date
    var income: Int
    var expense: Int

    var id: Date { month }

    /// Total `count` bulan terakhir yang berakhir di bulan `date`, urut dari yang paling lama.
    static func trend(records: [EntryRecord], endingAt date: Date, count: Int, calendar: Calendar = .current) -> [MonthTotal] {
        guard count > 0, let current = calendar.dateInterval(of: .month, for: date)?.start else { return [] }
        return (0..<count).reversed().compactMap { offset in
            guard let start = calendar.date(byAdding: .month, value: -offset, to: current) else { return nil }
            let summary = MonthSummary(records: records, month: start, calendar: calendar)
            return MonthTotal(month: start, income: summary.income, expense: summary.expense)
        }
    }
}
