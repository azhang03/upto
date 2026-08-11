import SwiftUI
import UptoCore

struct ApplicationSection: View {
    @Environment(PresenceController.self) private var presence
    @AppStorage("applicationID") private var applicationID = ""
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        Section("Application") {
            TextField("Application ID", text: $applicationID)
                .focused(focus, equals: .applicationID)
                .connectorSource(.applicationID)
                .disabled(presence.isBusy)
            connectButton
            if let error = presence.lastError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
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
}
