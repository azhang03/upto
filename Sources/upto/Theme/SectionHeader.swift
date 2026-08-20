import SwiftUI

// The small tracked label above a section or a field.
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(Theme.Fonts.sectionLabel)
            .tracking(1.5)
            .foregroundStyle(Theme.Colors.accentDim)
    }
}
