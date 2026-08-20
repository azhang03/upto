import SwiftUI
import UptoCore

// The pinned row above the tabs: the application ID and the
// connection controls.
struct ApplicationSection: View {
    @Environment(PresenceController.self) private var presence
    @AppStorage("applicationID") private var applicationID = ""
    var focus: FocusState<EditorFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
                UptoField(
                    label: "Application ID",
                    isFocused: focus.wrappedValue == .applicationID
                ) {
                    TextField("", text: $applicationID, prompt: Text("From the Discord developer portal"))
                        .textFieldStyle(.plain)
                        .font(Theme.Fonts.mono)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .focused(focus, equals: .applicationID)
                        .disabled(presence.isBusy)
                }
                .connectorSource(.applicationID)
                connectButton
                    .padding(.bottom, Theme.Spacing.xs)
            }
            if let guidance = presence.state.userGuidance {
                Text(guidance)
                    .font(.callout)
                    .foregroundStyle(Theme.Colors.warning)
            }
            if let error = presence.lastError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(Theme.Colors.destructive)
            }
        }
    }

    @ViewBuilder
    private var connectButton: some View {
        if presence.isBusy {
            Button("Disconnect") {
                presence.disconnect()
            }
            .buttonStyle(PillButtonStyle(variant: .neutral))
        } else {
            Button("Connect") {
                presence.connect(applicationID: applicationID)
            }
            .buttonStyle(PillButtonStyle(variant: .neutral))
            .disabled(applicationID.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
