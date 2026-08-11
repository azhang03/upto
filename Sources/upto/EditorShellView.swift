import SwiftUI
import UptoCore

struct EditorShellView: View {
    @Environment(PresenceController.self) private var presence
    @State private var model = EditorModel()
    @FocusState private var focus: EditorFocus?

    var body: some View {
        let activity = model.builtActivity
        let focusedTargets = Set(focus?.previewTargets(in: activity) ?? [])

        HSplitView {
            EditorFormView(model: model, focus: $focus)
                .frame(minWidth: 340, idealWidth: 430)
            PreviewPane(
                activity: activity,
                issues: model.issues,
                focusedTargets: focusedTargets,
                displayName: presence.userDisplayName ?? "You"
            )
            .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlayPreferenceValue(ConnectorAnchorsKey.self) { anchors in
            ConnectorOverlay(anchors: anchors, focus: focus, activity: activity)
        }
        .frame(minWidth: 780, minHeight: 520)
        .toolbar {
            ToolbarItem(placement: .status) {
                Label(presence.statusText, systemImage: "circle.fill")
                    .foregroundStyle(presence.statusColor)
            }
            ToolbarItem(placement: .primaryAction) {
                updateButton
            }
            ToolbarItem {
                Button("Clear") {
                    model.markCleared()
                    presence.clearPresence()
                }
                .disabled(!presence.isReady)
            }
        }
    }

    private var updateButton: some View {
        Button {
            model.markApplied()
            presence.apply(model.draft.buildActivity())
        } label: {
            if model.isDirty {
                Text("Update")
            } else {
                Label("Applied", systemImage: "checkmark")
            }
        }
        .disabled(!presence.isReady || model.hasErrors)
    }
}
