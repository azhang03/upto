import SwiftUI

// A row of equal width capsule segments, used instead of the system
// picker for short option lists.
struct PillSegmentedPicker<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    var onSelect: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                    onSelect?()
                } label: {
                    Text(label(option))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChipButtonStyle(isSelected: isSelected, cornerRadius: 8))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
    }
}
