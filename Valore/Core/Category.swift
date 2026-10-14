import Foundation

/// Arah arus uang sebuah transaksi.
enum EntryKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense: "Pengeluaran"
        case .income: "Pemasukan"
        }
    }

    /// -1 untuk pengeluaran, +1 untuk pemasukan.
    var sign: Int { self == .expense ? -1 : 1 }
}

/// Kategori bawaan. Disimpan sebagai `rawValue`, jadi jangan ganti nama case yang sudah dipakai.
enum EntryCategory: String, Codable, CaseIterable, Identifiable {
    case makan, transportasi, belanja, tagihan, hiburan, kesehatan, pendidikan, keluarga
    case gaji, usaha, investasi, bonus
    case lainnya

    var id: String { rawValue }

    var label: String {
        switch self {
        case .makan: "Makan & Minum"
        case .transportasi: "Transportasi"
        case .belanja: "Belanja"
        case .tagihan: "Tagihan"
        case .hiburan: "Hiburan"
        case .kesehatan: "Kesehatan"
        case .pendidikan: "Pendidikan"
        case .keluarga: "Keluarga"
        case .gaji: "Gaji"
        case .usaha: "Usaha"
        case .investasi: "Investasi"
        case .bonus: "Bonus & Hadiah"
        case .lainnya: "Lainnya"
        }
    }

    /// Nama SF Symbol.
    var symbol: String {
        switch self {
        case .makan: "fork.knife"
        case .transportasi: "car.fill"
        case .belanja: "bag.fill"
        case .tagihan: "doc.text.fill"
        case .hiburan: "gamecontroller.fill"
        case .kesehatan: "cross.case.fill"
        case .pendidikan: "book.fill"
        case .keluarga: "person.2.fill"
        case .gaji: "briefcase.fill"
        case .usaha: "building.2.fill"
        case .investasi: "chart.line.uptrend.xyaxis"
        case .bonus: "gift.fill"
        case .lainnya: "ellipsis.circle.fill"
        }
    }

    var kinds: Set<EntryKind> {
        switch self {
        case .gaji, .usaha, .investasi, .bonus: [.income]
        case .lainnya: [.income, .expense]
        default: [.expense]
        }
    }

    static func options(for kind: EntryKind) -> [EntryCategory] {
        allCases.filter { $0.kinds.contains(kind) }
    }
}
