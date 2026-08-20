import SwiftUI

// Chrome for one input row: an optional label above, a rounded field
// surface, an optional character counter, and an accent border while
// the field has focus. Focus itself stays on the inner control, so the
// caller passes the focus state in.
struct UptoField<Content: View>: View {
    var label: String? = nil
    var isFocused = false
    var count: Int? = nil
    var limit: Int? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let label {
                SectionHeader(label)
            }
            HStack(spacing: Theme.Spacing.s) {
                content
                if let count, let limit {
                    Text("\(count)/\(limit)")
                        .font(Theme.Fonts.mono)
                        .foregroundStyle(
                            isFocused ? Theme.Colors.accent : Theme.Colors.textSecondary
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Theme.Colors.bgInset,
                in: RoundedRectangle(cornerRadius: Theme.Radius.field)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.field)
                    .stroke(
                        isFocused ? Theme.Colors.accent : Theme.Colors.hairline,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isFocused ? Theme.Colors.accent.opacity(0.25) : .clear,
                radius: 4
            )
        }
    }
}
