import SwiftUI
import UptoCore

struct TimestampsSection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        Section("Timestamps") {
            Picker("Mode", selection: $model.draft.timestampMode) {
                Text("Off").tag(ActivityDraft.TimestampMode.off)
                Text("Time since update").tag(ActivityDraft.TimestampMode.sinceApply)
                Text("Custom").tag(ActivityDraft.TimestampMode.custom)
            }
            .focused(focus, equals: .timestampMode)
            .connectorSource(.timestampMode)

            if model.draft.timestampMode == .custom {
                ValidatedRow(issues: model.issues(for: .timestamps)) {
                    DatePicker("Start", selection: $model.draft.customStart, displayedComponents: [.date, .hourAndMinute])
                        .focused(focus, equals: .timestampStart)
                }
                .connectorSource(.timestampStart)

                Toggle("Set an end time", isOn: $model.draft.endEnabled)

                if model.draft.endEnabled {
                    DatePicker("End", selection: $model.draft.customEnd, displayedComponents: [.date, .hourAndMinute])
                        .focused(focus, equals: .timestampEnd)
                        .connectorSource(.timestampEnd)
                }
            }
        }
    }
}
