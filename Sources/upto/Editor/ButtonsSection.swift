import SwiftUI
import UptoCore

struct ButtonsSection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        Section {
            buttonGroup(index: 0, title: "Button 1")
            buttonGroup(index: 1, title: "Button 2")
        } header: {
            Text("Buttons")
        } footer: {
            Text("Discord does not let you click your own buttons. Other people can use them.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func buttonGroup(index: Int, title: String) -> some View {
        ValidatedRow(issues: model.issues(for: .buttonLabel(index)) + model.issues(for: .buttons)) {
            TextField("\(title) label", text: $model.draft.buttons[index].label, prompt: Text("Button text"))
                .focused(focus, equals: .buttonLabel(index))
        }
        .connectorSource(.buttonLabel(index))

        ValidatedRow(issues: model.issues(for: .buttonURL(index))) {
            TextField("\(title) link", text: $model.draft.buttons[index].url, prompt: Text("https://..."))
                .focused(focus, equals: .buttonURL(index))
        }
        .connectorSource(.buttonURL(index))
    }
}
