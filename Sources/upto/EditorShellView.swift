import SwiftUI
import UptoCore

struct EditorShellView: View {
    @Environment(PresenceController.self) private var presence
    @AppStorage("applicationID") private var applicationID = ""

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
                Label(presence.statusText, systemImage: "circle.fill")
                    .foregroundStyle(presence.statusColor)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Send test presence") {
                    presence.sendTestPresence()
                }
                .disabled(!presence.isReady)
            }
            ToolbarItem {
                Button("Clear") {
                    presence.clearPresence()
                }
                .disabled(!presence.isReady)
            }
        }
    }

    // The Application section below is the temporary hookup for testing
    // the connection. The full editor replaces this form.
    private var editor: some View {
        Form {
            Section("Application") {
                TextField("Application ID", text: $applicationID)
                    .disabled(presence.isBusy)
                connectButton
                if let error = presence.lastError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            Section("Activity") { placeholder }
            Section("Images") { placeholder }
            Section("Timestamps") { placeholder }
            Section("Party") { placeholder }
            Section("Buttons") { placeholder }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var connectButton: some View {
        if presence.isBusy {
            Button("Disconnect") {
                presence.disconnect()
            }
        } else {
            Button("Connect") {
                presence.connect(applicationID: applicationID)
            }
            .disabled(applicationID.trimmingCharacters(in: .whitespaces).isEmpty)
        }
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
