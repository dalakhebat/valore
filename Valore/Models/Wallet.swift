import Foundation
import SwiftData

/// Tempat uang disimpan: tunai, rekening bank, e-wallet, dst.
@Model
final class Wallet {
    /// ID stabil untuk file cadangan (`persistentModelID` tidak bisa dipakai lintas perangkat).
    var uuid: UUID = UUID()
    var name: String = ""
    var symbol: String = "wallet.pass.fill"
    /// Saldo saat dompet mulai dicatat, dalam rupiah.
    var initialBalance: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.wallet)
    var entries: [LedgerEntry]? = []

    init(name: String, symbol: String = "wallet.pass.fill", initialBalance: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.symbol = symbol
        self.initialBalance = initialBalance
        self.createdAt = createdAt
    }

    var balance: Int {
        initialBalance + (entries ?? []).reduce(0) { $0 + $1.signedAmount }
    }
}
