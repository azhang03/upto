import SwiftUI
import UptoCore

struct PartySection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Toggle("Set a party size", isOn: $model.draft.partyEnabled)
                .tint(Theme.Colors.accent)

            if model.draft.partyEnabled {
                ValidatedRow(issues: model.issues(for: .party)) {
                    HStack(alignment: .top, spacing: Theme.Spacing.m) {
                        partyField("In the party", text: $model.draft.partyCurrent, focusCase: .partyCurrent)
                            .connectorSource(.partyCurrent)
                        partyField("Party limit", text: $model.draft.partyMax, focusCase: .partyMax)
                            .connectorSource(.partyMax)
                    }
                }
            }
        }
    }

    private func partyField(_ label: String, text: Binding<String>, focusCase: EditorFocus) -> some View {
        UptoField(label: label, isFocused: focus.wrappedValue == focusCase) {
            TextField("", text: text)
                .textFieldStyle(.plain)
                .foregroundStyle(Theme.Colors.textPrimary)
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
