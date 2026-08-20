import SwiftUI

// A small capsule chip, used for preset selection rows. The dashed
// variant is the "add new" chip.
struct ChipButtonStyle: ButtonStyle {
    var isSelected = false
    var isDashed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.control)
            .foregroundStyle(labelColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(fillColor, in: Capsule())
            .overlay {
                if isDashed {
                    Capsule().stroke(
                        Theme.Colors.textSecondary,
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                } else if !isSelected {
                    Capsule().stroke(Theme.Colors.hairline, lineWidth: 1)
                }
            }
            .brightness(configuration.isPressed ? -0.08 : 0)
            .contentShape(Capsule())
    }

    private var labelColor: Color {
        if isSelected { return Theme.Colors.accentText }
        if isDashed { return Theme.Colors.textSecondary }
        return Theme.Colors.textPrimary
    }

    private var fillColor: Color {
        if isSelected { return Theme.Colors.accent }
        if isDashed { return .clear }
        return Theme.Colors.bgRaised
    }
}
