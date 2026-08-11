import SwiftUI
import UptoCore

struct EditorFormView: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        Form {
            ApplicationSection(focus: focus)
            ActivitySection(model: model, focus: focus)
            ImagesSection(model: model, focus: focus)
            TimestampsSection(model: model, focus: focus)
            PartySection(model: model, focus: focus)
        }
        .formStyle(.grouped)
        .connectorViewport()
    }
}
