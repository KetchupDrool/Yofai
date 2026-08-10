import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var firstLaunchGuide: FirstLaunchGuidePresenter
    @State private var selectedTab: YofaiAppTab = .defaultTab
    @State private var presentNewProduct = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                onStartProduct: {
                    presentNewProduct = true
                    selectedTab = .products
                },
                onOpenProducts: {
                    selectedTab = .products
                },
                onOpenOriginals: {
                    selectedTab = .originals
                },
                onOpenHistory: {
                    selectedTab = .history
                }
            )
            .tabItem {
                Label(YofaiAppTab.home.title, systemImage: YofaiAppTab.home.systemImage)
            }
            .tag(YofaiAppTab.home)

            ProjectsView(presentNewProduct: $presentNewProduct)
                .tabItem {
                    Label(YofaiAppTab.products.title, systemImage: YofaiAppTab.products.systemImage)
                }
                .tag(YofaiAppTab.products)

            OriginalsView()
                .tabItem {
                    Label(YofaiAppTab.originals.title, systemImage: YofaiAppTab.originals.systemImage)
                }
                .tag(YofaiAppTab.originals)

            HistoryView()
                .tabItem {
                    Label(YofaiAppTab.history.title, systemImage: YofaiAppTab.history.systemImage)
                }
                .tag(YofaiAppTab.history)

            SettingsView()
                .tabItem {
                    Label(YofaiAppTab.settings.title, systemImage: YofaiAppTab.settings.systemImage)
                }
                .tag(YofaiAppTab.settings)
        }
        .darkroomScreen()
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .fullScreenCover(isPresented: $firstLaunchGuide.isPresented) {
            FirstLaunchGuideView {
                firstLaunchGuide.dismissFinished()
            }
        }
        .onAppear {
            firstLaunchGuide.presentIfNeededOnLaunch()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FirstLaunchGuidePresenter(store: FirstLaunchGuideStore()))
        .modelContainer(previewContainer)
}

@MainActor
private let previewContainer: ModelContainer = {
    let schema = YofaiModelSchema.schema
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()
