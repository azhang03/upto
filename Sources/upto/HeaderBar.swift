import AppKit
import SwiftUI
import UptoCore

// The strip across the top of the window: the brand block on the left
// and the main actions on the right. It replaces the system toolbar.
struct HeaderBar: View {
    @Environment(PresenceController.self) private var presence
    @Environment(EditorModel.self) private var model

    private static let mark: NSImage = {
        let image = Bundle.module.image(forResource: "uptoTemplate") ?? NSImage()
        image.isTemplate = true
        return image
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(nsImage: Self.mark)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Theme.Colors.accent)
                Text("upto")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Spacer(minLength: Theme.Spacing.l)

            StatusPill(presence: presence)
            pushButton
            Button("Clear") {
                model.markCleared()
                presence.clearPresence()
            }
            .buttonStyle(PillButtonStyle(variant: .neutral))
            .disabled(!presence.isReady)
            .help("Remove the presence from your profile and stay connected.")
        }
        .padding(.leading, Theme.Metrics.trafficLightInset)
        .padding(.trailing, Theme.Spacing.l)
        .frame(maxWidth: .infinity)
        .frame(height: Theme.Metrics.headerHeight)
        .background(Theme.Colors.bgHeader)
    }

    private var pushButton: some View {
        Button {
            model.markApplied()
            presence.apply(model.draft.buildActivity())
        } label: {
            if model.isDirty {
                Text("Push")
            } else {
                Label("Pushed", systemImage: "checkmark")
            }
        }
        .buttonStyle(PillButtonStyle(variant: .accent))
        .disabled(!presence.isReady || model.hasErrors)
        .help("Send the presence to Discord.")
    }
}
