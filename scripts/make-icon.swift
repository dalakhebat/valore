// Menggambar ikon app 1024×1024 (gradien teal→hijau + simbol dompet).
// Jalankan dari root repo: swift scripts/make-icon.swift
import AppKit

let size = 1024
let output = URL(fileURLWithPath: "Valore/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

// Ikon iOS tidak boleh punya kanal alpha: gambar ke RGBX (alpha diabaikan).
guard let cg = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("Gagal membuat bitmap") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)

let canvas = NSRect(x: 0, y: 0, width: size, height: size)
let gradient = NSGradient(
    starting: NSColor(srgbRed: 0.00, green: 0.50, blue: 0.53, alpha: 1),
    ending: NSColor(srgbRed: 0.20, green: 0.78, blue: 0.47, alpha: 1)
)!
gradient.draw(in: canvas, angle: -45)

let config = NSImage.SymbolConfiguration(pointSize: 470, weight: .semibold)
    .applying(.init(paletteColors: [.white]))
guard let symbol = NSImage(systemSymbolName: "wallet.bifold.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) else { fatalError("SF Symbol tidak ditemukan") }
let symbolSize = symbol.size
symbol.draw(in: NSRect(
    x: (CGFloat(size) - symbolSize.width) / 2,
    y: (CGFloat(size) - symbolSize.height) / 2,
    width: symbolSize.width,
    height: symbolSize.height
))

NSGraphicsContext.restoreGraphicsState()

guard let image = cg.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
else { fatalError("Gagal encode PNG") }
try png.write(to: output)
print("Ikon disimpan ke \(output.path)")
