import SwiftUI

struct EditorShellView: View {
    var body: some View {
        HSplitView {
            editor
                .frame(minWidth: 320, idealWidth: 400)
            preview
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 480)
        .toolbar {
            ToolbarItem(placement: .status) {
                Label("Not connected", systemImage: "circle.fill")
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Update") {}
                    .disabled(true)
            }
        }
    }

    private var editor: some View {
        Form {
            Section("Application") { placeholder }
            Section("Activity") { placeholder }
            Section("Images") { placeholder }
            Section("Timestamps") { placeholder }
            Section("Party") { placeholder }
            Section("Buttons") { placeholder }
        }
        .formStyle(.grouped)
    }

    private var preview: some View {
        VStack(spacing: 8) {
            Text("Live preview")
                .font(.headline)
            Text("The preview appears here when the editor fields are ready.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var placeholder: some View {
        Text("Not built yet")
            .foregroundStyle(.tertiary)
    }
}
