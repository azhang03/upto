import SwiftUI
import UptoCore

struct PartySection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        Section("Party") {
            Toggle("Set a party size", isOn: $model.draft.partyEnabled)

            if model.draft.partyEnabled {
                ValidatedRow(issues: model.issues(for: .party)) {
                    partyField("In the party", text: $model.draft.partyCurrent, focusCase: .partyCurrent)
                    partyField("Party limit", text: $model.draft.partyMax, focusCase: .partyMax)
                }
                .connectorSource(.partyCurrent)
            }
        }
    }

    private func partyField(_ label: String, text: Binding<String>, focusCase: EditorFocus) -> some View {
        HStack {
            TextField(label, text: text)
                .focused(focus, equals: focusCase)
            Stepper(label) {
                text.wrappedValue = String((Int(text.wrappedValue) ?? 1) + 1)
            } onDecrement: {
                text.wrappedValue = String(max(1, (Int(text.wrappedValue) ?? 1) - 1))
            }
            .labelsHidden()
        }
    }
}
