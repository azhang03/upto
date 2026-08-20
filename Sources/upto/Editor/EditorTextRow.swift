import SwiftUI
import UptoCore

// One text row in the editor: label, styled field with a character
// counter, and the row's validation messages. The connector anchor
// wraps the field and its messages, like the old form rows did.
struct EditorTextRow: View {
    let label: String
    let prompt: String
    @Binding var text: String
    let limit: Int
    let focusCase: EditorFocus
    let issues: [ActivityValidationIssue]
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        ValidatedRow(issues: issues) {
            UptoField(
                label: label,
                isFocused: focus.wrappedValue == focusCase,
                count: text.count,
                limit: limit
            ) {
                TextField("", text: $text, prompt: Text(prompt))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .focused(focus, equals: focusCase)
            }
        }
        .connectorSource(focusCase)
    }
}
