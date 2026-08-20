import SwiftUI
import UptoCore

// Wraps a form control and shows its validation messages underneath.
struct ValidatedRow<Content: View>: View {
    let issues: [ActivityValidationIssue]
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content
            ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                Text(issue.message)
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
