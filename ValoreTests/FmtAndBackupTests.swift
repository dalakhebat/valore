import Foundation
import Testing
@testable import Valore

struct FmtTests {
    @Test func rupiah() {
        #expect(Fmt.rupiah(1_500_000) == "Rp 1.500.000")
        #expect(Fmt.rupiah(-50_000) == "−Rp 50.000")
        #expect(Fmt.rupiah(50_000, signed: true) == "+Rp 50.000")
        #expect(Fmt.rupiah(0, signed: true) == "Rp 0")
    }

    @Test func compact() {
        #expect(Fmt.compact(1_500_000) == "1,5 jt")
        #expect(Fmt.compact(250_000) == "250 rb")
        #expect(Fmt.compact(2_000_000_000) == "2 M")
        #expect(Fmt.compact(900) == "900")
        #expect(Fmt.compactRupiah(-1_200_000) == "−Rp 1,2 jt")
    }

    @Test(arguments: [
        ("Rp 1.500.000", 1_500_000),
        ("abc", 0),
        ("", 0),
        ("١٢٣", 0),  // angka non-ASCII diabaikan
        ("99999999999999999999", 9_999_999_999_999),
    ])
    func parseAmount(text: String, expected: Int) {
        #expect(Fmt.parseAmount(text) == expected)
    }
}

struct BackupFileTests {
    @Test func roundTrip() throws {
        let walletID = UUID()
        // ISO 8601 tidak menyimpan pecahan detik, jadi pakai tanggal bulat.
        let file = BackupFile(
            version: BackupFile.currentVersion,
            exportedAt: date(2026, 10, 14),
            wallets: [.init(id: walletID, name: "Tunai", symbol: "banknote.fill", initialBalance: 100_000, createdAt: date(2026, 10, 1))],
            entries: [.init(id: UUID(), amount: 25_000, kind: "expense", category: "makan", note: "Kopi", date: date(2026, 10, 2), walletID: walletID)],
            goals: [.init(id: UUID(), name: "Liburan", symbol: "airplane", target: 5_000_000, deadline: nil, createdAt: date(2026, 10, 1),
                          deposits: [.init(id: UUID(), amount: 500_000, date: date(2026, 10, 5), note: "")])]
        )
        #expect(try BackupFile.decode(file.encoded()) == file)
    }

    @Test func rejectsNewerVersion() throws {
        var file = BackupFile(version: BackupFile.currentVersion + 1, exportedAt: date(2026, 10, 14), wallets: [], entries: [], goals: [])
        let data = try file.encoded()
        #expect(throws: BackupError.unsupportedVersion(file.version)) { try BackupFile.decode(data) }
        file.version = BackupFile.currentVersion
        #expect(try BackupFile.decode(file.encoded()) == file)
    }
}
