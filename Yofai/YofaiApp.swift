import SwiftUI
import SwiftData

@main
struct YofaiApp: App {
    @StateObject private var firstLaunchGuide = FirstLaunchGuidePresenter()

    private let modelContainer: ModelContainer = {
        let schema = YofaiModelSchema.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firstLaunchGuide)
                .task {
                    PurchaseManager.shared.startListeningForTransactionsIfNeeded()
                    await PurchaseManager.shared.refreshEntitlementsAndProducts()
                }
        }
        .modelContainer(modelContainer)
    }
}
