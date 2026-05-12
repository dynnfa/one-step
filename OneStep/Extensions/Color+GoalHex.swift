import AppKit
import OneStepCore
import SwiftUI

extension Color {
    init(goalHex hex: String) {
        guard let normalizedHex = FinalGoalColorTheme.normalizedHex(hex) else {
            self = Color.accentColor
            return
        }

        let rawHex = String(normalizedHex.dropFirst())
        let scanner = Scanner(string: rawHex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var goalHex: String? {
        NSColor(self).usingColorSpace(.sRGB)?.goalHex
    }
}

extension NSColor {
    var goalHex: String {
        let red = Int(round(redComponent * 255))
        let green = Int(round(greenComponent * 255))
        let blue = Int(round(blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
