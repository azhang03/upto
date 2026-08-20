import SwiftUI
import UptoCore

struct ImagesSection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            EditorTextRow(
                label: "Large image", prompt: "Asset key or image link",
                text: $model.draft.largeImage, limit: 256,
                focusCase: .largeImage, issues: model.issues(for: .largeImage), focus: focus
            )

            EditorTextRow(
                label: "Large image text", prompt: "Tooltip on hover",
                text: $model.draft.largeText, limit: 128,
                focusCase: .largeText, issues: model.issues(for: .largeText), focus: focus
            )

            EditorTextRow(
                label: "Large image link", prompt: "Makes the image clickable",
                text: $model.draft.largeURL, limit: 512,
                focusCase: .largeURL, issues: model.issues(for: .largeURL), focus: focus
            )

            EditorTextRow(
                label: "Small image", prompt: "Asset key or image link",
                text: $model.draft.smallImage, limit: 256,
                focusCase: .smallImage, issues: model.issues(for: .smallImage), focus: focus
            )

            EditorTextRow(
                label: "Small image text", prompt: "Tooltip on hover",
                text: $model.draft.smallText, limit: 128,
                focusCase: .smallText, issues: model.issues(for: .smallText), focus: focus
            )

            EditorTextRow(
                label: "Small image link", prompt: "Makes the image clickable",
                text: $model.draft.smallURL, limit: 512,
                focusCase: .smallURL, issues: model.issues(for: .smallURL), focus: focus
            )
        }
    }
}
