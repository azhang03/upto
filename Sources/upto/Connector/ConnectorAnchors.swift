import SwiftUI
import UptoCore

// Anchor bookkeeping for the focus connector. Form rows report where
// they are, preview elements report where they are, and the overlay on
// the split view resolves both sides in one shared coordinate space.
struct ConnectorAnchors {
    var fields: [EditorFocus: Anchor<CGRect>] = [:]
    var targets: [PreviewTarget: Anchor<CGRect>] = [:]
    var editorViewport: Anchor<CGRect>?

    mutating func merge(_ other: ConnectorAnchors) {
        fields.merge(other.fields) { _, new in new }
        targets.merge(other.targets) { _, new in new }
        if let viewport = other.editorViewport {
            editorViewport = viewport
        }
    }
}

struct ConnectorAnchorsKey: PreferenceKey {
    static var defaultValue: ConnectorAnchors { ConnectorAnchors() }

    static func reduce(value: inout ConnectorAnchors, nextValue: () -> ConnectorAnchors) {
        value.merge(nextValue())
    }
}

extension View {
    func connectorSource(_ focus: EditorFocus) -> some View {
        anchorPreference(key: ConnectorAnchorsKey.self, value: .bounds) {
            ConnectorAnchors(fields: [focus: $0])
        }
    }

    func connectorTarget(_ target: PreviewTarget) -> some View {
        anchorPreference(key: ConnectorAnchorsKey.self, value: .bounds) {
            ConnectorAnchors(targets: [target: $0])
        }
    }

    func connectorViewport() -> some View {
        anchorPreference(key: ConnectorAnchorsKey.self, value: .bounds) {
            ConnectorAnchors(editorViewport: $0)
        }
    }
}
