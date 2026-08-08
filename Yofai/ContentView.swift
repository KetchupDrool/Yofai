import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            OriginalsView()
                .tabItem {
                    Label("Originals", systemImage: "photo.on.rectangle")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .darkroomScreen()
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}

@MainActor
private let previewContainer: ModelContainer = {
    let schema = Schema([SavedEdit.self, ImportedOriginal.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()
