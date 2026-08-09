import XCTest
import SwiftData
@testable import Yofai

@MainActor
final class Phase35SellerFirstNavigationTests: XCTestCase {
    func testTabOrderAndPrimaryFlags() {
        XCTAssertEqual(YofaiAppTab.allCases.map(\.title), [
            "Home", "Products", "Originals", "History", "Settings"
        ])
        XCTAssertEqual(YofaiAppTab.defaultTab, .home)
        XCTAssertTrue(YofaiAppTab.home.isSellerPrimary)
        XCTAssertTrue(YofaiAppTab.products.isSellerPrimary)
        XCTAssertFalse(YofaiAppTab.originals.isSellerPrimary)
        XCTAssertFalse(YofaiAppTab.history.isSellerPrimary)
        XCTAssertFalse(YofaiAppTab.settings.isSellerPrimary)
    }

    func testSellerFacingLabels() {
        XCTAssertEqual(SellerNavigationSupport.startProductTitle, "Start Product")
        XCTAssertEqual(SellerNavigationSupport.productsListTitle, "Products")
        XCTAssertEqual(SellerNavigationSupport.projectIntakeLinkTitle, "Capture & Check Photos")
        XCTAssertEqual(SellerNavigationSupport.projectWorkspaceLinkTitle, "Prepare Listing & Export")
        XCTAssertEqual(SellerNavigationSupport.quickImportTitle, "Import Single Photo")
        XCTAssertTrue(SellerNavigationSupport.homeWorkflowHint.lowercased().contains("export"))
    }

    func testRecentProductsLimitPreservesOrder() {
        let values = Array(1...8)
        XCTAssertEqual(SellerNavigationSupport.recentProducts(values), [1, 2, 3, 4, 5])
        XCTAssertEqual(SellerNavigationSupport.recentProductLimit, 5)
    }

    func testExistingProjectsRemainCompatibleAndReachable() throws {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
        let context = ModelContext(container)

        let older = ItemProject(name: "Older Lamp", photos: [])
        older.modifiedAt = Date(timeIntervalSince1970: 100)
        let newer = ItemProject(name: "Newer Mug", photos: [])
        newer.modifiedAt = Date(timeIntervalSince1970: 200)
        context.insert(older)
        context.insert(newer)
        try context.save()

        let descriptor = FetchDescriptor<ItemProject>(sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)])
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.map(\.name), ["Newer Mug", "Older Lamp"])
        XCTAssertEqual(SellerNavigationSupport.recentProducts(fetched).map(\.name), ["Newer Mug", "Older Lamp"])
        XCTAssertTrue(YofaiModelSchema.models.contains { $0 == ItemProject.self })
        XCTAssertTrue(YofaiModelSchema.models.contains { $0 == ImportedOriginal.self })
        XCTAssertTrue(YofaiModelSchema.models.contains { $0 == SavedEdit.self })
    }

    func testOriginalsAndHistoryModelsStillInSchema() {
        let names = YofaiModelSchema.models.map { String(describing: $0) }
        XCTAssertTrue(names.contains(where: { $0.contains("ImportedOriginal") }))
        XCTAssertTrue(names.contains(where: { $0.contains("SavedEdit") }))
        XCTAssertTrue(names.contains(where: { $0.contains("ItemProject") }))
    }
}
