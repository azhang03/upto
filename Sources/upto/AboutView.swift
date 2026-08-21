import AppKit
import SwiftUI

// The About window: icon, version, and the project link.
struct AboutView: View {
    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        return "Version \(short)"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("upto")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(version)
                .font(Theme.Fonts.mono)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("Custom Discord Rich Presence for macOS.")
                .font(.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize()
            Link("github.com/azhang03/upto", destination: URL(string: "https://github.com/azhang03/upto")!)
                .font(Theme.Fonts.control)
                .foregroundStyle(Theme.Colors.accentDim)
        }
        .padding(.top, 44)
        .padding(.bottom, Theme.Spacing.xl)
        .padding(.horizontal, 48)
        .background(Theme.Colors.bgWindow)
    }
}
