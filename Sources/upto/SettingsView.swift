import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage("connectOnLaunch") private var connectOnLaunch = false
    @State private var launchAtLogin = false
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Toggle("Launch upto at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, wanted in
                    updateLoginItem(wanted)
                }
            Toggle("Connect and apply on launch", isOn: $connectOnLaunch)
            if let loginItemError {
                Text(loginItemError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
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
