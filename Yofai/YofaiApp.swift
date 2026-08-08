import SwiftUI
import SwiftData

@main
struct YofaiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SavedEdit.self)
    }
}
