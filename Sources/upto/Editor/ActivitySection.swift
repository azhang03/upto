import SwiftUI
import UptoCore

struct ActivitySection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            EditorEnumRow(label: "Type", focusCase: .activityType, focus: focus) {
                PillSegmentedPicker(
                    selection: $model.draft.type,
                    options: ActivityType.allCases,
                    label: { $0.displayName },
                    onSelect: { focus.wrappedValue = .activityType }
                )
            }

            EditorTextRow(
                label: "Name", prompt: "Overrides the app name",
                text: $model.draft.name, limit: 128,
                focusCase: .activityName, issues: model.issues(for: .name), focus: focus
            )

            EditorTextRow(
                label: "Details", prompt: "What are you doing?",
                text: $model.draft.details, limit: 128,
                focusCase: .details, issues: model.issues(for: .details), focus: focus
            )

            EditorTextRow(
                label: "Details link", prompt: "Makes the details clickable",
                text: $model.draft.detailsURL, limit: 512,
                focusCase: .detailsURL, issues: model.issues(for: .detailsURL), focus: focus
            )

            EditorTextRow(
                label: "State", prompt: "Second line",
                text: $model.draft.state, limit: 128,
                focusCase: .state, issues: model.issues(for: .state), focus: focus
            )

            EditorTextRow(
                label: "State link", prompt: "Makes the state clickable",
                text: $model.draft.stateURL, limit: 512,
                focusCase: .stateURL, issues: model.issues(for: .stateURL), focus: focus
            )

            EditorEnumRow(label: "Status shows", focusCase: .statusDisplay, focus: focus) {
                PillSegmentedPicker(
                    selection: $model.draft.statusDisplay,
                    options: StatusDisplayType.allCases,
                    label: { $0.displayName },
                    onSelect: { focus.wrappedValue = .statusDisplay }
                )
            }
        }
    }
}

// A labeled row for a segmented picker. The row itself takes the
// focus when a segment is clicked, so the connector still points at
// the preview.
struct EditorEnumRow<Content: View>: View {
    let label: String
    let focusCase: EditorFocus
    var focus: FocusState<EditorFocus?>.Binding
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(label)
            content
        }
        .focusable()
        .focusEffectDisabled()
        .focused(focus, equals: focusCase)
        .connectorSource(focusCase)
    }
}
