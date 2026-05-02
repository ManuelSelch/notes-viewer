import SwiftUI

@main
struct notesApp: App {
    var body: some Scene {
        WindowGroup {
            NoteListView(owner: "ManuelSelch", repo: "pi-memory-md")
        }
    }
}
