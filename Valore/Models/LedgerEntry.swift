import Foundation
import SwiftData

/// Satu transaksi pemasukan atau pengeluaran.
@Model
final class LedgerEntry {
    var uuid: UUID = UUID()
    /// Selalu positif, dalam rupiah. Arah uang ditentukan `kind`.
    var amount: Int = 0
    // Enum disimpan sebagai String: predicate SwiftData belum bisa memfilter enum secara andal.
    var kindRaw: String = EntryKind.expense.rawValue
    var categoryRaw: String = EntryCategory.lainnya.rawValue
    var note: String = ""
    var date: Date = Date.now
    var wallet: Wallet?

    init(amount: Int = 0, kind: EntryKind = .expense, category: EntryCategory = .lainnya, note: String = "", date: Date = .now) {
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.categoryRaw = category.rawValue
        self.note = note
        self.date = date
    }

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var category: EntryCategory {
        get { EntryCategory(rawValue: categoryRaw) ?? .lainnya }
        set { categoryRaw = newValue.rawValue }
    }

    var signedAmount: Int { amount * kind.sign }

    var record: EntryRecord {
        EntryRecord(amount: amount, kind: kind, category: category, date: date)
    }

    /// Pesan kalau menghapus transaksi ini bikin saldo dompetnya minus (mis. menghapus pemasukan), selain itu nil.
    var deletionProblem: String? {
        guard let wallet, !BalanceRule.isAllowed(current: wallet.balance, removing: signedAmount) else { return nil }
        return "Nggak bisa dihapus: saldo \(wallet.name) jadi \(Fmt.rupiah(BalanceRule.resultingBalance(current: wallet.balance, removing: signedAmount)))."
    }

    func matches(_ query: String) -> Bool {
        [note, category.label, wallet?.name ?? ""].contains { $0.localizedCaseInsensitiveContains(query) }
    }
}
