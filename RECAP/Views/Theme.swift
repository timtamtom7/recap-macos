import SwiftUI

enum Theme {
    // Backgrounds
    static let backgroundPrimary = Color(hex: "1E1E1E")
    static let backgroundSecondary = Color(hex: "2D2D2D")
    static let backgroundTertiary = Color(hex: "3D3D3D")

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0A0")
    static let textTertiary = Color(hex: "666666")

    // Accents
    static let accentBlue = Color(hex: "0A84FF")
    static let recordingRed = Color(hex: "FF453A")
    static let pausedOrange = Color(hex: "FF9F0A")
    static let successGreen = Color(hex: "30D158")

    // Recording indicator pulse
    static let recordingRedGlow = Color(hex: "FF453A").opacity(0.4)
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
