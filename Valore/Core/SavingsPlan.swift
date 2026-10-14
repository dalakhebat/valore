import Foundation

enum SavingCadence: String, CaseIterable, Identifiable {
    case daily, weekly, monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: "Harian"
        case .weekly: "Mingguan"
        case .monthly: "Bulanan"
        }
    }

    var perLabel: String {
        switch self {
        case .daily: "per hari"
        case .weekly: "per minggu"
        case .monthly: "per bulan"
        }
    }

    var unitLabel: String {
        switch self {
        case .daily: "hari"
        case .weekly: "minggu"
        case .monthly: "bulan"
        }
    }
}

enum GoalPace: Equatable {
    case done, ahead, onTrack, behind, overdue, noDeadline

    var label: String {
        switch self {
        case .done: "Tercapai"
        case .ahead: "Lebih cepat"
        case .onTrack: "Sesuai jadwal"
        case .behind: "Tertinggal"
        case .overdue: "Lewat tenggat"
        case .noDeadline: "Tanpa tenggat"
        }
    }
}

/// Perhitungan rencana sebuah target tabungan.
///
/// Sengaja murni (tanpa SwiftData/SwiftUI) supaya bisa dites langsung.
struct SavingsPlan: Equatable {
    var target: Int
    var saved: Int
    /// Kapan target dibuat; dipakai untuk menghitung seharusnya sudah terkumpul berapa.
    var start: Date
    var deadline: Date?
    var now: Date
    var calendar: Calendar = .current

    var remaining: Int { max(target - saved, 0) }

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(max(Double(saved) / Double(target), 0), 1)
    }

    var isDone: Bool { target > 0 && saved >= target }

    var isOverdue: Bool {
        guard let deadline, !isDone else { return false }
        return day(now) > day(deadline)
    }

    /// Sisa kesempatan menabung sampai tenggat, minimal 1 selama tenggat belum lewat.
    /// `nil` kalau tidak ada tenggat atau tenggat sudah lewat.
    func periodsLeft(_ cadence: SavingCadence) -> Int? {
        guard let deadline, !isOverdue else { return nil }
        let from = day(now)
        let to = day(deadline)
        switch cadence {
        case .daily:
            let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0
            return max(days, 1)
        case .weekly:
            let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0
            return max((days + 6) / 7, 1)
        case .monthly:
            // Bulan yang tidak penuh tetap dihitung satu kali setoran.
            let months = calendar.dateComponents([.month], from: from, to: to).month ?? 0
            let afterWholeMonths = calendar.date(byAdding: .month, value: months, to: from) ?? to
            return max(months + (afterWholeMonths < to ? 1 : 0), 1)
        }
    }

    /// Nominal yang perlu disisihkan tiap periode supaya target tercapai tepat waktu (dibulatkan ke atas).
    func requiredPerPeriod(_ cadence: SavingCadence) -> Int? {
        if isDone { return 0 }
        guard let periods = periodsLeft(cadence) else { return nil }
        return (remaining + periods - 1) / periods
    }

    /// Jumlah yang idealnya sudah terkumpul hari ini kalau menabung rata dari `start` sampai `deadline`.
    var expectedByNow: Int? {
        guard let deadline else { return nil }
        let total = deadline.timeIntervalSince(start)
        guard total > 0 else { return target }
        let elapsed = min(max(now.timeIntervalSince(start), 0), total)
        return Int((Double(target) * elapsed / total).rounded())
    }

    /// Status dibanding jadwal ideal, dengan toleransi 5% dari target.
    var pace: GoalPace {
        if isDone { return .done }
        if isOverdue { return .overdue }
        guard let expected = expectedByNow else { return .noDeadline }
        let tolerance = target / 20
        if saved > expected + tolerance { return .ahead }
        if saved >= expected - tolerance { return .onTrack }
        return .behind
    }

    /// Berapa bulan lagi target tercapai kalau menabung `perMonth` tiap bulan.
    func monthsToReach(saving perMonth: Int) -> Int? {
        guard perMonth > 0 else { return nil }
        if isDone { return 0 }
        return (remaining + perMonth - 1) / perMonth
    }

    func projectedDate(saving perMonth: Int) -> Date? {
        guard let months = monthsToReach(saving: perMonth) else { return nil }
        return calendar.date(byAdding: .month, value: months, to: now)
    }

    private func day(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}
