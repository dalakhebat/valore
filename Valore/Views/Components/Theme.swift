import SwiftUI
import UIKit

/// Palet VALORE: latar abu sangat muda, kartu putih, blok pastel. Setiap warna punya versi gelap.
enum Palette {
    static let background = Color(light: 0xF4F4F2, dark: 0x121214)
    static let card = Color(light: 0xFFFFFF, dark: 0x1E1E21)

    static let sky = Color(light: 0xCDE8F2, dark: 0x1E3A44)
    static let green = Color(light: 0xDCEBC4, dark: 0x29391F)
    static let yellow = Color(light: 0xF7EAA8, dark: 0x453E1C)
    static let peach = Color(light: 0xF6C2AE, dark: 0x4A2C22)
    static let pastels = [sky, green, yellow, peach]

    /// Warna tegas untuk tombol utama dan pilihan yang aktif.
    static let ink = Color(light: 0x1C1C1E, dark: 0xF2F2F7)
    /// Teks dan ikon di atas `ink`.
    static let onInk = Color(light: 0xFFFFFF, dark: 0x1C1C1E)

    static let positive = Color(light: 0x2E9E5B, dark: 0x5BC983)
    static let coral = Color(light: 0xE0704F, dark: 0xF0947A)
    static let blue = Color(light: 0x3A87AE, dark: 0x6DB5D9)
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension View {
    /// Kartu bersudut besar khas VALORE.
    func card(_ fill: Color = Palette.card, padding: CGFloat = 18, radius: CGFloat = 26) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Tombol pil gelap (terang di dark mode) untuk aksi utama.
struct InkButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        InkLabel(configuration: configuration, fullWidth: fullWidth)
    }

    private struct InkLabel: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: Configuration
        let fullWidth: Bool

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(Palette.onInk)
                .padding(.horizontal, 24)
                .padding(.vertical, 15)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(Palette.ink, in: Capsule())
                .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.3)
        }
    }
}

extension EntryCategory {
    /// Warna kategori yang sedikit diredam supaya serasi dengan blok pastel.
    var color: Color {
        switch self {
        case .makan: Color(light: 0xE3874F, dark: 0xF0A06E)
        case .transportasi: Color(light: 0x4A86C8, dark: 0x6FA4DE)
        case .belanja: Color(light: 0xD96C8E, dark: 0xE88AA8)
        case .tagihan: Color(light: 0x7467C9, dark: 0x9488E0)
        case .hiburan: Color(light: 0x9E72C6, dark: 0xB894DB)
        case .kesehatan: Color(light: 0xD45F5F, dark: 0xE88080)
        case .pendidikan: Color(light: 0x3FA5BC, dark: 0x66C0D4)
        case .keluarga: Color(light: 0xA9835F, dark: 0xC4A07E)
        case .gaji: Color(light: 0x3E9E6A, dark: 0x5DBD88)
        case .usaha: Color(light: 0x2F9C95, dark: 0x52BAB3)
        case .investasi: Color(light: 0x5AAE8C, dark: 0x7ACBAA)
        case .bonus: Color(light: 0xC99A06, dark: 0xE8C547)
        case .lainnya: Color(light: 0x8E8E93, dark: 0xA1A1A6)
        }
    }
}

extension GoalPace {
    var color: Color {
        switch self {
        case .done: Palette.positive
        case .ahead: .teal
        case .onTrack: Palette.blue
        case .behind: Palette.coral
        case .overdue: .red
        case .noDeadline: .gray
        }
    }
}
