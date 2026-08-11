import Foundation
import Observation
import UptoCore

@MainActor
@Observable
final class EditorModel {
    private static let draftKey = "activityDraft"

    var draft: ActivityDraft {
        didSet { save() }
    }

    private(set) var lastAppliedDraft: ActivityDraft?

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.draftKey),
           let saved = try? JSONDecoder().decode(ActivityDraft.self, from: data) {
            draft = saved
        } else {
            draft = ActivityDraft()
        }
    }

    var builtActivity: Activity {
        draft.buildActivity()
    }

    var issues: [ActivityValidationIssue] {
        draft.localIssues() + builtActivity.validate()
    }

    func issues(for field: ActivityField) -> [ActivityValidationIssue] {
        issues.filter { $0.field == field }
    }

    var hasErrors: Bool {
        issues.contains { $0.severity == .error }
    }

    // Compared on drafts, not built activities, so a running
    // "since update" timer does not read as an edit.
    var isDirty: Bool {
        lastAppliedDraft != draft
    }

    func markApplied() {
        lastAppliedDraft = draft
    }

    func markCleared() {
        lastAppliedDraft = nil
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: Self.draftKey)
    }
}
