import CoreText
import SwiftUI
import UIKit

/// Sistem desain "Permen": neubrutalism pastel, sama dengan MarSawit.
/// Garis hitam 2px, bayangan keras tanpa blur, warna permen flat. Hanya versi terang.
enum Permen {
    static let bg = Color(hex: 0xF8F1D7)
    static let surface = Color(hex: 0xFFFDF1)
    static let ink = Color(hex: 0x171717)
    /// Teks sekunder di atas krem.
    static let muted = Color(hex: 0x57534A)

    static let cyan = Color(hex: 0x19C7CF)
    static let cyanSoft = Color(hex: 0xB4EFF2)
    static let cyanPale = Color(hex: 0xD8F7F8)
    static let sky = Color(hex: 0xC9ECFB)
    static let skyStrong = Color(hex: 0x22C7F2)
    static let mint = Color(hex: 0xBDF3C9)
    static let mintStrong = Color(hex: 0x5CD68C)
    static let jade = Color(hex: 0x128A46)
    static let lemon = Color(hex: 0xFFF0A8)
    static let honey = Color(hex: 0xFFE7A6)
    static let amber = Color(hex: 0xFFBF45)
    static let orangeSoft = Color(hex: 0xFFD8A8)
    static let pink = Color(hex: 0xFF527A)
    static let pinkSoft = Color(hex: 0xFFD2DD)
    static let pinkText = Color(hex: 0xC22A50)
    static let lilac = Color(hex: 0xE3D7FF)
    static let neutral = Color(hex: 0xE4E4E7)
    static let neutralStrong = Color(hex: 0xA1A1AA)

    /// Isi kartu ringkasan bergiliran (satu kartu satu warna).
    static let candies = [cyanSoft, mint, honey, pinkSoft]

    static let line: CGFloat = 2
    static let shadow: CGFloat = 3
    static let radiusCard: CGFloat = 16
    static let radiusField: CGFloat = 12
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Huruf

/// Bangers untuk judul, Nunito untuk teks dan semua angka (Bangers tidak terbaca untuk data).
enum PermenFont {
    enum Weight: String {
        case regular = "Nunito-Regular"
        case semibold = "Nunito-SemiBold"
        case bold = "Nunito-Bold"
        case extraBold = "Nunito-ExtraBold"
        case black = "Nunito-Black"
    }

    static let display = "Bangers-Regular"

    /// Didaftarkan saat runtime supaya juga jalan di SwiftUI Preview (tanpa UIAppFonts).
    static let registration: Void = {
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    static func uiFont(_ weight: Weight, size: CGFloat) -> UIFont {
        _ = registration
        return UIFont(name: weight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}

extension Font {
    static func nunito(_ size: CGFloat, _ weight: PermenFont.Weight = .regular, relativeTo style: TextStyle = .body) -> Font {
        _ = PermenFont.registration
        return .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static func bangers(_ size: CGFloat, relativeTo style: TextStyle = .largeTitle) -> Font {
        _ = PermenFont.registration
        return .custom(PermenFont.display, size: size, relativeTo: style)
    }
}

// MARK: - Latar & kartu

/// Latar krem dengan tiga semburat warna tipis.
struct PermenBackground: View {
    var body: some View {
        ZStack {
            Permen.bg
            RadialGradient(colors: [Permen.cyan.opacity(0.22), .clear], center: UnitPoint(x: 0.12, y: 0.16), startRadius: 0, endRadius: 260)
            RadialGradient(colors: [Permen.pink.opacity(0.14), .clear], center: UnitPoint(x: 0.9, y: 0.1), startRadius: 0, endRadius: 220)
            RadialGradient(colors: [Permen.amber.opacity(0.18), .clear], center: UnitPoint(x: 0.8, y: 0.88), startRadius: 0, endRadius: 280)
        }
        .ignoresSafeArea()
    }
}

/// Bentuk dasar neubrutalism: isi flat, garis tinta, bayangan keras di kanan bawah.
struct BrutShape: View {
    var fill: Color = Permen.surface
    var radius: CGFloat = Permen.radiusCard
    var shadow: CGFloat = Permen.shadow
    var lineWidth: CGFloat = Permen.line

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            if shadow > 0 {
                shape.fill(Permen.ink).offset(x: shadow, y: shadow)
            }
            shape.fill(fill)
            shape.strokeBorder(Permen.ink, lineWidth: lineWidth)
        }
    }
}

extension View {
    /// Kartu brutal: isi warna, garis 2px, bayangan keras 3px.
    func brut(_ fill: Color = Permen.surface, padding: CGFloat = 16, radius: CGFloat = Permen.radiusCard, shadow: CGFloat = Permen.shadow) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BrutShape(fill: fill, radius: radius, shadow: shadow))
    }
}

// MARK: - Tombol

/// Semua yang bisa diketuk terasa "dipencet": bergeser dan bayangannya mengecil.
private struct PressBody<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    let label: Label
    let isPressed: Bool
    let fill: Color
    let radius: CGFloat
    let shadow: CGFloat

    var body: some View {
        let pressed = isPressed && isEnabled
        label
            .background(BrutShape(fill: isEnabled ? fill : Permen.neutral, radius: radius, shadow: pressed ? 1 : shadow))
            .offset(x: pressed ? shadow - 1 : 0, y: pressed ? shadow - 1 : 0)
            .opacity(isEnabled ? 1 : 0.6)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

/// Bentuk brutal yang bisa dipencet, tanpa mengubah isi label (untuk kartu & ubin).
struct BrutPressStyle: ButtonStyle {
    var fill: Color = Permen.surface
    var radius: CGFloat = Permen.radiusField
    var shadow: CGFloat = Permen.shadow

    func makeBody(configuration: Configuration) -> some View {
        PressBody(label: configuration.label, isPressed: configuration.isPressed, fill: fill, radius: radius, shadow: shadow)
    }
}

/// Tombol teks (default cyan, aksi utama).
struct BrutButtonStyle: ButtonStyle {
    var fill: Color = Permen.cyan
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        PressBody(
            label: configuration.label
                .font(.nunito(17, .extraBold))
                .foregroundStyle(Permen.ink)
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .frame(maxWidth: fullWidth ? .infinity : nil),
            isPressed: configuration.isPressed,
            fill: fill,
            radius: Permen.radiusField,
            shadow: Permen.shadow
        )
    }
}

// MARK: - Warna data

extension EntryCategory {
    /// Warna "stiker" kategori.
    var color: Color {
        switch self {
        case .makan: Permen.orangeSoft
        case .transportasi: Permen.sky
        case .belanja: Permen.pinkSoft
        case .tagihan: Permen.lilac
        case .hiburan: Color(hex: 0xF3D1FF)
        case .kesehatan: Color(hex: 0xFFA8BD)
        case .pendidikan: Permen.cyanSoft
        case .keluarga: Permen.honey
        case .gaji: Permen.mint
        case .usaha: Color(hex: 0x93E6AE)
        case .investasi: Color(hex: 0xD7F4E6)
        case .bonus: Permen.lemon
        case .lainnya: Permen.neutral
        }
    }
}

extension GoalPace {
    /// Latar stiker status.
    var stickerFill: Color {
        switch self {
        case .done: Permen.mint
        case .ahead: Permen.cyanPale
        case .onTrack: Permen.sky
        case .behind: Permen.honey
        case .overdue: Permen.pinkSoft
        case .noDeadline: Permen.neutral
        }
    }

    /// Isi batang/busur progres.
    var barFill: Color {
        switch self {
        case .done: Permen.mintStrong
        case .ahead: Permen.cyan
        case .onTrack: Permen.skyStrong
        case .behind: Permen.amber
        case .overdue: Permen.pink
        case .noDeadline: Permen.neutralStrong
        }
    }
}
