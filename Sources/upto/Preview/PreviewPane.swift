import SwiftUI
import UptoCore

struct PreviewPane: View {
    let activity: Activity
    let issues: [ActivityValidationIssue]
    let focusedTargets: Set<PreviewTarget>
    let displayName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let model = PresencePreviewModel(activity: activity, appName: "Your app", now: context.date)
                    VStack(alignment: .leading, spacing: 16) {
                        labeled("Profile") {
                            PresenceCardView(model: model, focusedTargets: focusedTargets)
                        }
                        labeled("Member list") {
                            MemberListRowView(displayName: displayName, statusText: model.memberListText)
                        }
                    }
                }

                if !issues.isEmpty {
                    labeled("Checks") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                                Label(issue.message, systemImage: issue.severity == .error ? "xmark.circle" : "exclamationmark.triangle")
                                    .font(.footnote)
                                    .foregroundStyle(issue.severity == .error ? Color.red : Color.orange)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private func labeled(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}
