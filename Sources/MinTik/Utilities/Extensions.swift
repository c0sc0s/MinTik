import SwiftUI
import AppKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
    func toHex() -> String? {
        #if os(macOS)
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return nil }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
        #else
        return nil
        #endif
    }
}

func alertColor(from primary: Color) -> Color {
    #if os(macOS)
    let base = NSColor(primary)
    guard let rgb = base.usingColorSpace(.sRGB) else { return Color.red }
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    let warmedHue = max(0.0, min(1.0, h - 0.08))
    let boostedS = max(0.0, min(1.0, s + 0.15))
    let boostedB = max(0.0, min(1.0, b))
    return Color(hue: Double(warmedHue), saturation: Double(boostedS), brightness: Double(boostedB))
    #else
    return Color.red
    #endif
}

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let rect = NSRect(origin: .zero, size: image.size)
        rect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}
