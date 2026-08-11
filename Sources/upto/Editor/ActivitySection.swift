import SwiftUI
import UptoCore

struct ActivitySection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        Section("Activity") {
            Picker("Type", selection: $model.draft.type) {
                Text("Playing").tag(ActivityType.playing)
                Text("Listening").tag(ActivityType.listening)
                Text("Watching").tag(ActivityType.watching)
                Text("Competing").tag(ActivityType.competing)
            }
            .focused(focus, equals: .activityType)
            .connectorSource(.activityType)

            ValidatedRow(issues: model.issues(for: .name)) {
                TextField("Name", text: $model.draft.name, prompt: Text("Overrides the app name"))
                    .focused(focus, equals: .activityName)
            }
            .connectorSource(.activityName)

            ValidatedRow(issues: model.issues(for: .details)) {
                TextField("Details", text: $model.draft.details, prompt: Text("What are you doing?"))
                    .focused(focus, equals: .details)
            }
            .connectorSource(.details)

            ValidatedRow(issues: model.issues(for: .detailsURL)) {
                TextField("Details link", text: $model.draft.detailsURL, prompt: Text("Makes the details clickable"))
                    .focused(focus, equals: .detailsURL)
            }
            .connectorSource(.detailsURL)

            ValidatedRow(issues: model.issues(for: .state)) {
                TextField("State", text: $model.draft.state, prompt: Text("Second line"))
                    .focused(focus, equals: .state)
            }
            .connectorSource(.state)

            ValidatedRow(issues: model.issues(for: .stateURL)) {
                TextField("State link", text: $model.draft.stateURL, prompt: Text("Makes the state clickable"))
                    .focused(focus, equals: .stateURL)
            }
            .connectorSource(.stateURL)

            Picker("Status shows", selection: $model.draft.statusDisplay) {
                Text("Name").tag(StatusDisplayType.name)
                Text("State").tag(StatusDisplayType.state)
                Text("Details").tag(StatusDisplayType.details)
            }
            .focused(focus, equals: .statusDisplay)
            .connectorSource(.statusDisplay)
        }
    }
}
