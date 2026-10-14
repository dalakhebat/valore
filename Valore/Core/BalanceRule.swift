import Foundation

/// Aturan saldo: saldo dompet tidak boleh minus.
///
/// Semua nilai bertanda: pemasukan positif, pengeluaran negatif.
enum BalanceRule {
    /// Saldo dompet setelah transaksi lama diganti transaksi baru.
    /// - Parameters:
    ///   - current: saldo dompet sekarang, sudah termasuk `removing` kalau transaksi itu ada di dompet ini.
    ///   - removing: nilai transaksi lama di dompet ini (0 untuk transaksi baru atau yang pindah dari dompet lain).
    ///   - adding: nilai transaksi setelah disimpan (0 kalau transaksi dihapus atau pindah ke dompet lain).
    static func resultingBalance(current: Int, removing: Int = 0, adding: Int = 0) -> Int {
        current - removing + adding
    }

    static func isAllowed(current: Int, removing: Int = 0, adding: Int = 0) -> Bool {
        resultingBalance(current: current, removing: removing, adding: adding) >= 0
    }

    /// Pengeluaran terbesar yang masih boleh dicatat di dompet ini.
    static func spendable(current: Int, removing: Int = 0) -> Int {
        max(resultingBalance(current: current, removing: removing), 0)
    }
}
