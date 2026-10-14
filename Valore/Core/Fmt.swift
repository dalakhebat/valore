import Foundation

/// Format angka & tanggal gaya Indonesia: titik sebagai pemisah ribuan, nama hari/bulan bahasa Indonesia.
enum Fmt {
    static let locale = Locale(identifier: "id_ID")

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    /// `Rp 1.500.000`, `−Rp 50.000`, atau `+Rp 50.000` kalau `signed`.
    static func rupiah(_ amount: Int, signed: Bool = false) -> String {
        let sign = amount < 0 ? "−" : (signed && amount > 0 ? "+" : "")
        return "\(sign)Rp \(number(abs(amount)))"
    }

    /// Versi ringkas buat label grafik: `1,5 jt`, `250 rb`, `2 M`.
    static func compact(_ amount: Int) -> String {
        let sign = amount < 0 ? "−" : ""
        let value = Double(abs(amount))
        let (scaled, unit): (Double, String) = switch value {
        case 1_000_000_000...: (value / 1_000_000_000, " M")
        case 1_000_000...: (value / 1_000_000, " jt")
        case 1_000...: (value / 1_000, " rb")
        default: (value, "")
        }
        return sign + scaled.formatted(.number.locale(locale).precision(.fractionLength(0...1))) + unit
    }

    static func compactRupiah(_ amount: Int) -> String {
        amount < 0 ? "−Rp " + compact(-amount) : "Rp " + compact(amount)
    }

    /// Ambil angka dari teks input (`"Rp 1.500.000"` → 1500000). Dibatasi 13 digit supaya tidak overflow.
    static func parseAmount(_ text: String) -> Int {
        Int(text.filter { $0.isASCII && $0.isNumber }.prefix(13)) ?? 0
    }

    /// `Selasa, 14 Oktober 2026`
    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(locale))
    }

    /// `14 Okt`
    static func shortDay(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }

    /// `Oktober 2026`
    static func month(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(locale))
    }

    /// Sapaan sesuai jam: pagi (04–10), siang (11–14), sore (15–17), selain itu malam.
    static func greeting(at date: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 4..<11: "Selamat pagi"
        case 11..<15: "Selamat siang"
        case 15..<18: "Selamat sore"
        default: "Selamat malam"
        }
    }
}
