import SwiftUI

/// Every color, font and size used by Travaso lives here. Change these to restyle the app.
/// Palette: Iron Grey 474747, Gunmetal 3D3D3D, Parchment F2EFEA, Dark Teal 036277.
enum Theme {

    // MARK: - Backgrounds
    static let background      = Color(hex: 0x333333)                         // window and list
    static let surface         = Color(hex: 0x3D3D3D)                         // bottom bar (Gunmetal)
    static let rowAlternate    = Color(hex: 0x383838)                         // every other row
    static let divider         = Color(hex: 0xF2EFEA).opacity(0.09)

    // MARK: - Text
    static let textPrimary     = Color(hex: 0xF2EFEA)                         // Parchment
    static let textSecondary   = Color(hex: 0xBCB8B1)
    static let textTertiary    = Color(hex: 0x8D8984)

    // MARK: - Accents and status
    static let accent          = Color(hex: 0x036277)                         // Convert button (Dark Teal)
    static let accentText      = Color(hex: 0xF2EFEA)                         // text on the Convert button
    static let tint            = Color(hex: 0x8D99AE)                         // switches, selections, progress ring
    static let success         = Color(hex: 0x4AAFC4)                         // ✓ ring
    static let failure         = Color(hex: 0xB3001B)                         // ✕ ring, Stop button
    static let failureText     = Color(hex: 0xE5384F)                         // error messages (readable on dark)
    static let skipped         = Color(hex: 0x8D8984)                         // "Skipped" ring
    static let ringTrack       = Color(hex: 0xF2EFEA).opacity(0.13)
    static let dropHighlight   = Color(hex: 0x8D99AE)                         // outline while dragging files in

    // MARK: - Fonts
    static let titleFont       = Font.system(size: 15, weight: .semibold)
    static let bodyFont        = Font.system(size: 13)
    static let rowTitleFont    = Font.system(size: 13, weight: .medium)
    static let detailFont      = Font.system(size: 11)
    static let monoDetailFont  = Font.system(size: 11).monospacedDigit()
    static let buttonFont      = Font.system(size: 13, weight: .semibold)
    static let ringFont        = Font.system(size: 9, weight: .medium)
    static let ringSymbolFont  = Font.system(size: 14, weight: .bold)
    static let rowIconFont     = Font.system(size: 15)
    static let toolbarIconFont = Font.system(size: 15)

    // MARK: - Sizes
    static let ringSize: CGFloat      = 40
    static let ringLineWidth: CGFloat = 3
    static let cornerRadius: CGFloat  = 10
}

extension Color {
    /// A color from a 0xRRGGBB literal, e.g. `Color(hex: 0x036277)`.
    init(hex: UInt32) {
        self.init(red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255)
    }
}
