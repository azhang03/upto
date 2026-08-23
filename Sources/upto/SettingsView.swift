import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(PresenceController.self) private var presence
    @AppStorage("connectOnLaunch") private var connectOnLaunch = false
    @State private var launchAtLogin = false
    @State private var loginItemError: String?
    @State private var confirmingUninstall = false
    @State private var uninstallError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Toggle("Launch upto at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, wanted in
                    updateLoginItem(wanted)
                }
            Toggle("Connect and apply on launch", isOn: $connectOnLaunch)
            if let loginItemError {
                Text(loginItemError)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.destructive)
            }

            Divider()
                .overlay(Theme.Colors.hairline)
                .padding(.vertical, Theme.Spacing.xs)

            Button("Uninstall upto…") {
                confirmingUninstall = true
            }
            .buttonStyle(PillButtonStyle(variant: .destructive))
            Text("Removes the app and every file it made.")
                .font(.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
            if let uninstallError {
                Text(uninstallError)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.destructive)
            }
        }
        .tint(Theme.Colors.accent)
        .foregroundStyle(Theme.Colors.textPrimary)
        .frame(width: 360, alignment: .leading)
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.bgWindow)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .confirmationDialog(
            "Uninstall upto?",
            isPresented: $confirmingUninstall,
            titleVisibility: .visible
        ) {
            Button("Uninstall and Quit", role: .destructive) {
                uninstallError = nil
                Uninstaller.run(presence: presence) { message in
                    uninstallError = message
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your presets and the app move to the Trash. The settings and the login item are removed. upto quits when this completes.")
        }
    }

    private func updateLoginItem(_ wanted: Bool) {
        let enabled = SMAppService.mainApp.status == .enabled
        guard wanted != enabled else { return }
        loginItemError = nil
        do {
            if wanted {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            loginItemError = "Could not change the login item. macOS can refuse this for apps that run from a build folder."
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
