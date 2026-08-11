import SwiftUI
import UptoCore

struct ImagesSection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        Section("Images") {
            ValidatedRow(issues: model.issues(for: .largeImage)) {
                TextField("Large image", text: $model.draft.largeImage, prompt: Text("Asset key or image link"))
                    .focused(focus, equals: .largeImage)
            }
            .connectorSource(.largeImage)

            ValidatedRow(issues: model.issues(for: .largeText)) {
                TextField("Large image text", text: $model.draft.largeText, prompt: Text("Tooltip on hover"))
                    .focused(focus, equals: .largeText)
            }
            .connectorSource(.largeText)

            ValidatedRow(issues: model.issues(for: .smallImage)) {
                TextField("Small image", text: $model.draft.smallImage, prompt: Text("Asset key or image link"))
                    .focused(focus, equals: .smallImage)
            }
            .connectorSource(.smallImage)

            ValidatedRow(issues: model.issues(for: .smallText)) {
                TextField("Small image text", text: $model.draft.smallText, prompt: Text("Tooltip on hover"))
                    .focused(focus, equals: .smallText)
            }
            .connectorSource(.smallText)
        }
    }
}
