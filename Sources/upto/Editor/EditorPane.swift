import SwiftUI
import UptoCore

// The left side of the window: the pinned application row, the tab
// bar, and the active tab's fields.
struct EditorPane: View {
    @Bindable var model: EditorModel
    var focus: FocusState<EditorFocus?>.Binding

    @State private var selectedTab: EditorTab = .activity

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            ApplicationSection(focus: focus)
            SegmentedTabBar(
                selection: $selectedTab,
                options: EditorTab.allCases,
                label: { $0.title }
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    switch selectedTab {
                    case .activity:
                        ActivitySection(model: model, focus: focus)
                    case .images:
                        ImagesSection(model: model, focus: focus)
                    case .timing:
                        TimestampsSection(model: model, focus: focus)
                    case .party:
                        PartySection(model: model, focus: focus)
                    case .buttons:
                        ButtonsSection(model: model, focus: focus)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Theme.Spacing.s)
            }
            .withoutTopScrollEdge()
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.l)
        .background(Theme.Colors.bgWindow)
        .connectorViewport()
        .onChange(of: selectedTab) {
            // A field on a hidden tab cannot keep the focus.
            if let tab = focus.wrappedValue?.tab, tab != selectedTab {
                focus.wrappedValue = nil
            }
        }
    }
}
