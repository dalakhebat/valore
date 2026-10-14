import Foundation
import SwiftData

/// Target tabungan, mis. "Liburan" Rp 25 jt sebelum Juni.
@Model
final class SavingGoal {
    var uuid: UUID = UUID()
    var name: String = ""
    var symbol: String = "star.fill"
    var target: Int = 0
    var deadline: Date?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \GoalDeposit.goal)
    var deposits: [GoalDeposit]? = []

    init(name: String, symbol: String = "star.fill", target: Int, deadline: Date? = nil, createdAt: Date = .now) {
        self.name = name
        self.symbol = symbol
        self.target = target
        self.deadline = deadline
        self.createdAt = createdAt
    }

    var saved: Int {
        (deposits ?? []).reduce(0) { $0 + $1.amount }
    }

    func plan(now: Date = .now) -> SavingsPlan {
        SavingsPlan(target: target, saved: saved, start: createdAt, deadline: deadline, now: now)
    }
}

/// Setoran ke (atau penarikan dari) sebuah target tabungan.
@Model
final class GoalDeposit {
    var uuid: UUID = UUID()
    /// Positif = setor, negatif = tarik.
    var amount: Int = 0
    var date: Date = Date.now
    var note: String = ""
    var goal: SavingGoal?

    init(amount: Int, date: Date = .now, note: String = "") {
        self.amount = amount
        self.date = date
        self.note = note
    }
}
