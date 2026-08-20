import SwiftUI

// A small chip, used for preset selection rows and picker segments.
// Capsule by default; pass a corner radius for a squarer shape. The
// dashed variant is the "add new" chip.
struct ChipButtonStyle: ButtonStyle {
    var isSelected = false
    var isDashed = false
    var cornerRadius: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.control)
            .foregroundStyle(labelColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(fillColor, in: shape)
            .overlay {
                if isDashed {
                    shape.stroke(
                        Theme.Colors.textSecondary,
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                } else if !isSelected {
                    shape.stroke(Theme.Colors.hairline, lineWidth: 1)
                }
            }
            .brightness(configuration.isPressed ? -0.08 : 0)
            .contentShape(shape)
    }

    private var shape: AnyShape {
        if let cornerRadius {
            AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            AnyShape(Capsule())
        }
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
