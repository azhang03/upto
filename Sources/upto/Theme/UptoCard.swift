import SwiftUI

// A raised rounded surface with a hairline border.
struct UptoCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .background(
                Theme.Colors.bgRaised,
                in: RoundedRectangle(cornerRadius: Theme.Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Colors.hairline, lineWidth: 1)
            )
    }
}
