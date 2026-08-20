import SwiftUI

// The capsule button used across the app chrome.
struct PillButtonStyle: ButtonStyle {
    enum Variant {
        case accent
        case neutral
        case destructive
    }

    var variant: Variant = .neutral

    func makeBody(configuration: Configuration) -> some View {
        PillButtonBody(variant: variant, configuration: configuration)
    }
}

private struct PillButtonBody: View {
    @Environment(\.isEnabled) private var isEnabled
    let variant: PillButtonStyle.Variant
    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(Theme.Fonts.control)
            .foregroundStyle(labelColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(fillColor, in: Capsule())
            .overlay {
                if variant != .accent {
                    Capsule().stroke(Theme.Colors.hairline, lineWidth: 1)
                }
            }
            .opacity(isEnabled ? 1 : 0.4)
            .brightness(configuration.isPressed ? -0.08 : 0)
            .contentShape(Capsule())
    }

    private var labelColor: Color {
        switch variant {
        case .accent:
            return Theme.Colors.accentText
        case .neutral:
            return Theme.Colors.textPrimary
        case .destructive:
            return Theme.Colors.destructive
        }
    }

    private var fillColor: Color {
        switch variant {
        case .accent:
            return Theme.Colors.accent
        case .neutral, .destructive:
            return Theme.Colors.bgRaised
        }
    }
}
