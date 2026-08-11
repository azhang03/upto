import SwiftUI

@main
struct UptoApp: App {
    var body: some Scene {
        WindowGroup("upto", id: "editor") {
            EditorShellView()
        }

        MenuBarExtra("upto", systemImage: "dot.radiowaves.left.and.right") {
            MenuBarView()
        }
    }
}
