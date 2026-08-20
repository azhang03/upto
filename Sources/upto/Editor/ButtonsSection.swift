import SwiftUI
import UptoCore

struct ButtonsSection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            buttonGroup(index: 0, title: "Button 1")
            buttonGroup(index: 1, title: "Button 2")
            Text("Discord does not let you click your own buttons. Other people can use them.")
                .font(.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func buttonGroup(index: Int, title: String) -> some View {
        UptoCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                SectionHeader(title)

                EditorTextRow(
                    label: "Label", prompt: "Button text",
                    text: $model.draft.buttons[index].label, limit: 32,
                    focusCase: .buttonLabel(index),
                    issues: model.issues(for: .buttonLabel(index)) + model.issues(for: .buttons),
                    focus: focus
                )

                EditorTextRow(
                    label: "Link", prompt: "https://...",
                    text: $model.draft.buttons[index].url, limit: 512,
                    focusCase: .buttonURL(index),
                    issues: model.issues(for: .buttonURL(index)),
                    focus: focus
                )
            }
        }
    }
}
