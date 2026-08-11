import SwiftUI
import UptoCore

// A look-alike of the activity card on a Discord profile. Deliberately
// dark like Discord's default theme so the preview reads as Discord,
// not as part of the surrounding window.
struct PresenceCardView: View {
    let model: PresencePreviewModel
    let focusedTargets: Set<PreviewTarget>

    private let cardBackground = Color(red: 0.169, green: 0.176, blue: 0.192)
    private let linkColor = Color(red: 0.0, green: 0.66, blue: 0.99)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.headerText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .connectorTarget(.cardHeader)

            HStack(alignment: .top, spacing: 10) {
                imageStack

                VStack(alignment: .leading, spacing: 2) {
                    if let appName = model.appNameLine {
                        Text(appName)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .connectorTarget(.cardAppName)
                    }
                    if let details = model.detailsLine {
                        lineText(details)
                            .connectorTarget(.cardDetails)
                    }
                    stateLine
                    if let third = model.largeTextLine {
                        Text(third)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .connectorTarget(.cardLargeTextLine)
                    }
                    timeLine
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !model.buttons.isEmpty {
                buttonRow
            }
        }
        .padding(14)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private func lineText(_ line: PresencePreviewModel.LinkableLine) -> some View {
        Text(line.text)
            .font(.callout)
            .foregroundStyle(line.isLink ? linkColor : .white.opacity(0.85))
            .underline(line.isLink)
            .lineLimit(1)
    }

    @ViewBuilder
    private var stateLine: some View {
        if model.stateLine != nil || model.partySuffix != nil {
            HStack(spacing: 4) {
                if let state = model.stateLine {
                    lineText(state)
                }
                if let party = model.partySuffix {
                    Text(party.text)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(party.rendersOnDiscord ? 0.85 : 0.3))
                        .help(party.rendersOnDiscord ? "" : "Discord only shows the party count for the Playing type.")
                }
            }
            .connectorTarget(.cardState)
        }
    }

    @ViewBuilder
    private var timeLine: some View {
        if let progress = model.progress {
            VStack(alignment: .leading, spacing: 2) {
                ProgressView(value: progress.fraction)
                    .tint(.white)
                HStack {
                    Text(progress.elapsedText)
                    Spacer()
                    Text(progress.totalText)
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 4)
            .connectorTarget(.cardProgressBar)
        } else if let timer = model.timer {
            HStack(spacing: 4) {
                Image(systemName: timerIconName)
                    .font(.system(size: 10))
                Text(timer.text)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color(red: 0.23, green: 0.87, blue: 0.55))
            .connectorTarget(.cardTimer)
        }
    }

    private var timerIconName: String {
        switch model.timerIcon {
        case .controller: return "gamecontroller.fill"
        case .musicNote: return "music.note"
        case .hourglass: return "hourglass"
        case .clock, nil: return "clock"
        }
    }

    // Only one tooltip bubble can show at a time because focus drives
    // it, so both float in the same spot above the images where they
    // cannot collide with the time or progress text.
    private var imageStack: some View {
        ZStack(alignment: .bottomTrailing) {
            imagePlaceholder(present: model.largeImagePresent, isLink: model.largeImageIsLink)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .connectorTarget(.cardLargeImage)
                .help(model.largeTooltip ?? "")

            if model.smallImagePresent || focusedTargets.contains(.cardSmallImage) || focusedTargets.contains(.cardSmallImageTooltip) {
                imagePlaceholder(present: model.smallImagePresent, isLink: model.smallImageIsLink)
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(cardBackground, lineWidth: 3))
                    .connectorTarget(.cardSmallImage)
                    .help(model.smallTooltip ?? "")
                    .offset(x: 6, y: 6)
            }
        }
        .overlay(alignment: .top) {
            if focusedTargets.contains(.cardLargeImageTooltip) {
                tooltipBubble(text: model.largeTooltip, target: .cardLargeImageTooltip)
                    .offset(y: -30)
            } else if focusedTargets.contains(.cardSmallImageTooltip) {
                tooltipBubble(text: model.smallTooltip, target: .cardSmallImageTooltip)
                    .offset(y: -30)
            }
        }
        .zIndex(1)
        .padding(.trailing, 6)
    }

    private func imagePlaceholder(present: Bool, isLink: Bool) -> some View {
        ZStack {
            Rectangle()
                .fill(present ? Color(red: 0.35, green: 0.4, blue: 0.9) : Color.white.opacity(0.1))
            Image(systemName: isLink ? "link" : "photo")
                .foregroundStyle(.white.opacity(present ? 0.9 : 0.4))
                .font(.system(size: 14))
        }
    }

    private func tooltipBubble(text: String?, target: PreviewTarget) -> some View {
        Text(text?.isEmpty == false ? text! : "Tooltip text")
            .font(.caption)
            .foregroundStyle(text?.isEmpty == false ? .white : .white.opacity(0.5))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 5))
            .fixedSize()
            .connectorTarget(target)
    }

    private var buttonRow: some View {
        VStack(spacing: 6) {
            ForEach(Array(model.buttons.enumerated()), id: \.offset) { index, label in
                Text(label.isEmpty ? "Button" : label)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
                    .connectorTarget(.cardButton(index))
            }
        }
    }
}
