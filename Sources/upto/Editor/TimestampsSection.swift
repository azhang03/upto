import SwiftUI
import UptoCore

struct TimestampsSection: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    @State private var editingStart = false
    @State private var editingEnd = false
    @State private var showingStartCalendar = false
    @State private var showingEndCalendar = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            EditorEnumRow(label: "Mode", focusCase: .timestampMode, focus: focus) {
                PillSegmentedPicker(
                    selection: $model.draft.timestampMode,
                    options: ActivityDraft.TimestampMode.allCases,
                    label: { $0.displayName },
                    onSelect: { focus.wrappedValue = .timestampMode }
                )
            }

            if model.draft.timestampMode == .custom {
                ValidatedRow(issues: model.issues(for: .timestamps)) {
                    dateField(
                        "Start",
                        date: $model.draft.customStart,
                        focusCase: .timestampStart,
                        editing: $editingStart,
                        showingCalendar: $showingStartCalendar
                    )
                }
                .connectorSource(.timestampStart)

                Toggle("Set an end time", isOn: $model.draft.endEnabled)
                    .tint(Theme.Colors.accent)

                if model.draft.endEnabled {
                    dateField(
                        "End",
                        date: $model.draft.customEnd,
                        focusCase: .timestampEnd,
                        editing: $editingEnd,
                        showingCalendar: $showingEndCalendar
                    )
                    .connectorSource(.timestampEnd)
                }
            }
        }
        .onChange(of: focus.wrappedValue) {
            // The border clears when the focus moves to another field.
            if focus.wrappedValue != .timestampStart { editingStart = false }
            if focus.wrappedValue != .timestampEnd { editingEnd = false }
        }
    }

    private func dateField(
        _ label: String,
        date: Binding<Date>,
        focusCase: EditorFocus,
        editing: Binding<Bool>,
        showingCalendar: Binding<Bool>
    ) -> some View {
        UptoField(
            label: label,
            isFocused: editing.wrappedValue || focus.wrappedValue == focusCase
        ) {
            ThemedDatePicker(date: date) { isEditing in
                editing.wrappedValue = isEditing
                if isEditing {
                    focus.wrappedValue = focusCase
                } else if focus.wrappedValue == focusCase {
                    focus.wrappedValue = nil
                }
            }
            Spacer(minLength: 0)
            Button {
                showingCalendar.wrappedValue.toggle()
                focus.wrappedValue = focusCase
            } label: {
                Image(systemName: "calendar")
                    .foregroundStyle(Theme.Colors.accentDim)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: showingCalendar, arrowEdge: .bottom) {
                CalendarPopover(date: date)
                    .presentationBackground(Theme.Colors.bgElevated)
            }
        }
    }
}
