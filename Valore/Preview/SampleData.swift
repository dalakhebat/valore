import Foundation
import SwiftData

/// Data karangan untuk SwiftUI Preview dan screenshot portofolio. Bukan data asli.
@MainActor
enum SampleData {
    static func makeContainer(now: Date = .now) throws -> ModelContainer {
        let container = try ValoreSchema.container(inMemory: true)
        insert(into: container.mainContext, now: now)
        return container
    }

    static func insert(into context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        var rng = SeededGenerator(seed: 2026)

        // Saldo awal sengaja besar untuk dompet kecil: data contoh tidak punya transaksi isi ulang,
        // jadi tanpa ini saldo Tunai/E-Wallet jadi minus setelah 6 bulan jajan.
        let tunai = Wallet(name: "Tunai", symbol: "banknote.fill", initialBalance: 2_300_000)
        let bank = Wallet(name: "Rekening Bank", symbol: "building.columns.fill", initialBalance: 1_500_000)
        let ewallet = Wallet(name: "E-Wallet", symbol: "iphone", initialBalance: 4_600_000)
        for wallet in [tunai, bank, ewallet] { context.insert(wallet) }

        guard let thisMonth = calendar.dateInterval(of: .month, for: now)?.start else { return }

        for monthsAgo in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsAgo, to: thisMonth) else { continue }

            func add(_ amount: Int, _ kind: EntryKind, _ category: EntryCategory, _ note: String, day: Int, hour: Int = 12, _ wallet: Wallet) {
                guard let date = calendar.date(byAdding: DateComponents(day: day - 1, hour: hour), to: monthStart), date <= now else { return }
                let entry = LedgerEntry(amount: amount, kind: kind, category: category, note: note, date: date)
                context.insert(entry)
                entry.wallet = wallet
            }

            add(8_500_000, .income, .gaji, "Gaji bulanan", day: 1, hour: 9, bank)
            if monthsAgo % 2 == 0 {
                add(1_000_000 + Int.random(in: 0...8, using: &rng) * 100_000, .income, .usaha, "Hasil jualan online", day: 20, bank)
            }
            add(1_750_000, .expense, .tagihan, "Kos & listrik", day: 3, bank)
            add(120_000, .expense, .tagihan, "Paket data", day: 5, ewallet)
            add(750_000, .expense, .keluarga, "Kirim ke orang tua", day: 2, bank)
            add(300_000 + Int.random(in: 0...6, using: &rng) * 50_000, .expense, .belanja, "Belanja bulanan", day: 8, bank)

            let meals = ["Makan siang", "Kopi", "Makan malam", "Jajan"]
            for index in 0..<13 {
                add(20_000 + Int.random(in: 0...12, using: &rng) * 5_000, .expense, .makan,
                    meals[Int.random(in: 0..<meals.count, using: &rng)],
                    day: 1 + index * 2, hour: 12 + index % 7,
                    index % 3 == 0 ? tunai : ewallet)
            }
            for index in 0..<5 {
                add(18_000 + Int.random(in: 0...6, using: &rng) * 4_000, .expense, .transportasi, "Ojek online", day: 4 + index * 5, hour: 8, ewallet)
            }
            if monthsAgo % 2 == 1 { add(180_000, .expense, .hiburan, "Nonton & jajan", day: 16, hour: 19, tunai) }
            if monthsAgo % 3 == 0 { add(275_000, .expense, .pendidikan, "Buku kuliah", day: 12, bank) }
            if monthsAgo == 2 { add(150_000, .expense, .kesehatan, "Vitamin & obat", day: 22, ewallet) }
        }

        func goal(_ name: String, _ symbol: String, target: Int, monthsAgo: Int, deadlineInMonths: Int?, deposits: [Int]) {
            let created = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            let deadline = deadlineInMonths.flatMap { calendar.date(byAdding: .month, value: $0, to: now) }
            let goal = SavingGoal(name: name, symbol: symbol, target: target, deadline: deadline, createdAt: created)
            context.insert(goal)
            for (index, amount) in deposits.enumerated() {
                let date = calendar.date(byAdding: .month, value: index, to: created) ?? created
                let deposit = GoalDeposit(amount: amount, date: date, note: amount < 0 ? "Pakai sebagian" : "")
                context.insert(deposit)
                deposit.goal = goal
            }
        }

        goal("Liburan Jepang", "airplane", target: 25_000_000, monthsAgo: 4, deadlineInMonths: 8, deposits: [2_000_000, 2_000_000, 2_500_000, 2_000_000])
        goal("Laptop baru", "laptopcomputer", target: 18_000_000, monthsAgo: 3, deadlineInMonths: 3, deposits: [3_000_000, 2_500_000, 2_000_000])
        goal("Dana darurat", "shield.fill", target: 30_000_000, monthsAgo: 6, deadlineInMonths: nil, deposits: [1_500_000, 1_500_000, 1_000_000, 1_500_000, -500_000, 1_500_000])

        try? context.save()
    }
}

/// SplitMix64: acak tapi selalu sama tiap jalan, supaya screenshot konsisten.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
