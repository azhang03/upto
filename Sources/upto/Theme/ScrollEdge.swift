import SwiftUI

// macOS 26 draws an edge line where scrollable content meets the
// chrome above it. The header supplies its own visual boundary, so
// the line is hidden where the system supports that.
extension View {
    @ViewBuilder
    func withoutTopScrollEdge() -> some View {
        if #available(macOS 26.0, *) {
            self.scrollEdgeEffectHidden(true, for: .top)
        } else {
            self
        }
    }
}
