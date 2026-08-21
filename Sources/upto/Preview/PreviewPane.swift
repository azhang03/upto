import SwiftUI
import UptoCore

struct PreviewPane: View {
    let activity: Activity
    let issues: [ActivityValidationIssue]
    let focusedTargets: Set<PreviewTarget>
    let displayName: String
    let appliedAt: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let model = PresencePreviewModel(activity: activity, appName: "Your app", now: context.date, autoTimerStart: appliedAt)
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        labeled("As others see it") {
                            UptoCard {
                                PresenceCardView(model: model, focusedTargets: focusedTargets)
                            }
                        }
                        labeled("Member list") {
                            UptoCard {
                                MemberListRowView(displayName: displayName, statusText: model.memberListText)
                            }
                        }
                    }
                }

                if !issues.isEmpty {
                    labeled("Checks") {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                                Label(issue.message, systemImage: issue.severity == .error ? "xmark.circle" : "exclamationmark.triangle")
                                    .font(.footnote)
                                    .foregroundStyle(
                                        issue.severity == .error
                                            ? Theme.Colors.destructive
                                            : Theme.Colors.warning
                                    )
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .withoutTopScrollEdge()
        .background(Theme.Colors.bgWindow)
    }

    private func labeled(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title)
            content()
        }
    }
}
