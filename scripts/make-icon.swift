// Menggambar ikon app 1024×1024: monogram "V" di atas biru pastel.
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
// Latar biru pastel (Palette.sky) + monogram "V" warna tinta (Palette.ink).
NSColor(srgbRed: 0xCD / 255, green: 0xE8 / 255, blue: 0xF2 / 255, alpha: 1).setFill()
canvas.fill()

let ink = NSColor(srgbRed: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
let monogram = NSAttributedString(string: "V", attributes: [
    .font: NSFont.systemFont(ofSize: 640, weight: .black),
    .foregroundColor: ink,
])
let textSize = monogram.size()
monogram.draw(at: NSPoint(x: (CGFloat(size) - textSize.width) / 2, y: (CGFloat(size) - textSize.height) / 2 + 10))

// Titik kecil coral sebagai aksen.
NSColor(srgbRed: 0xE0 / 255, green: 0x70 / 255, blue: 0x4F / 255, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 712, y: 250, width: 96, height: 96)).fill()

NSGraphicsContext.restoreGraphicsState()

guard let image = cg.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
else { fatalError("Gagal encode PNG") }
try png.write(to: output)
print("Ikon disimpan ke \(output.path)")
