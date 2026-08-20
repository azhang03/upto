import SwiftUI

// The track style tab bar that switches editor pages. Equal width
// segments sit in an inset track; the selected one is raised.
struct SegmentedTabBar<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .font(Theme.Fonts.control)
                        .foregroundStyle(
                            isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            isSelected ? Theme.Colors.bgHeader : .clear,
                            in: RoundedRectangle(cornerRadius: Theme.Radius.field - 3)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.field - 3))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(
            Theme.Colors.bgInset,
            in: RoundedRectangle(cornerRadius: Theme.Radius.field)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.field)
                .stroke(Theme.Colors.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}
