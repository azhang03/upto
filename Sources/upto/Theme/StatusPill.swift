import AppKit
import SwiftUI

// The connection status in the window chrome: the brand mark tinted by
// the connection state, the status text, and a live timer while the
// presence is up.
struct StatusPill: View {
    let presence: PresenceController

    private static let liveMark = templateImage("uptoTemplate")
    private static let offlineMark = templateImage("uptoOfflineTemplate")

    private static func templateImage(_ name: String) -> NSImage {
        let image = BrandImage.named(name)
        image.isTemplate = true
        return image
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(nsImage: presence.isReady ? Self.liveMark : Self.offlineMark)
                .resizable()
                .renderingMode(.template)
                .frame(width: 12, height: 12)
                .foregroundStyle(Theme.Colors.status(for: presence.state))
            Text(presence.statusText)
                .font(Theme.Fonts.control)
                .foregroundStyle(Theme.Colors.textPrimary)
            if let since = presence.connectedSince {
                TimelineView(.periodic(from: since, by: 1)) { context in
                    Text(elapsedText(from: since, to: context.date))
                        .font(Theme.Fonts.mono)
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Theme.Colors.bgInset, in: Capsule())
        .overlay(Capsule().stroke(Theme.Colors.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func elapsedText(from start: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let rest = seconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, rest)
    }
}
