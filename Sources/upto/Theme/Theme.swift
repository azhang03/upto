import SwiftUI
import UptoCore

// The design tokens for the app chrome. The values come from the app
// icon and the design spec. Views use the semantic names, never raw
// color values. The preview column keeps its own fixed Discord palette
// and does not use these tokens.
enum Theme {
    enum Colors {
        static let bgWindow = Color(hex: 0x23262C)
        static let bgHeader = Color(hex: 0x3C4045)
        static let bgRaised = Color(hex: 0x2F3237)
        static let bgElevated = Color(hex: 0x33363C)
        static let bgInset = Color(hex: 0x222529)
        static let accent = Color(hex: 0x6ED0B1)
        static let accentText = Color(hex: 0x23262C)
        static let accentDim = Color(hex: 0x679585)
        static let textPrimary = Color(hex: 0xF2F3F4)
        static let textSecondary = Color.white.opacity(0.55)
        static let hairline = Color.white.opacity(0.09)
        static let destructive = Color(hex: 0xD96A5F)

        static func status(for state: ConnectionState) -> Color {
            switch state {
            case .idle:
                return textSecondary
            case .scanning:
                return .yellow
            case .ready:
                return accent
            case .backoff:
                return .orange
            case .failed:
                return destructive
            }
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let field: CGFloat = 10
        static let card: CGFloat = 12
        static let panel: CGFloat = 12
    }

    enum Fonts {
        static let sectionLabel = Font.system(size: 11, weight: .semibold)
        static let control = Font.system(size: 13, weight: .medium)
        static let mono = Font.system(size: 12, design: .monospaced)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
