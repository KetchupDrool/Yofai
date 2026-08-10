import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase54ConnectSubscriptionsReadinessTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        PurchaseManager.shared.resetForTesting()
        super.tearDown()
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24), format: format)
        return renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
    }

    // MARK: - Legal links

    func testPaywallLegalLinksUseDocumentedURLs() {
        XCTAssertEqual(YofaiProLegalLinks.termsOfUseTitle, "Terms of Use")
        XCTAssertEqual(YofaiProLegalLinks.privacyStatementTitle, "Privacy Statement")
        XCTAssertEqual(
            YofaiProLegalLinks.termsOfUseURLString,
            "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        )
        XCTAssertEqual(
            YofaiProLegalLinks.privacyStatementURLString,
            "https://ketchupdrool.github.io/Yofai/privacy-policy.html"
        )
        XCTAssertEqual(
            YofaiProLegalLinks.privacyStatementURLString,
            AppStoreLaunchSupport.privacyPolicyURLString
        )
        XCTAssertEqual(YofaiProLegalLinks.restorePurchasesTitle, "Restore Purchases")
        XCTAssertTrue(FreemiumCopy.subscriptionTermsFooter.lowercased().contains("manage or cancel"))
        XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(FreemiumCopy.subscriptionTermsFooter))
    }

    func testUnavailableStateStaysSafeWithoutFakePrice() async {
        let service = MockPurchaseService(resolvedPlan: .free)
        service.loadShouldFail = true
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()

        XCTAssertEqual(manager.productsLoadState, .unavailable)
        XCTAssertTrue(manager.products.isEmpty)
        XCTAssertEqual(manager.statusMessage, FreemiumCopy.purchasesUnavailable)
        XCTAssertFalse(FreemiumCopy.purchasesUnavailable.contains("$"))
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
        // Legal link constants remain available even when products fail.
        XCTAssertFalse(YofaiProLegalLinks.termsOfUseURLString.isEmpty)
        XCTAssertFalse(YofaiProLegalLinks.privacyStatementURLString.isEmpty)
        XCTAssertEqual(YofaiProLegalLinks.restorePurchasesTitle, FreemiumCopy.restorePurchases)
    }

    // MARK: - StoreKit readiness

    func testProductIDsUnchanged() {
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
        XCTAssertEqual(YofaiProductIDs.intendedMonthlyPriceNote, "$4.99/month")
        XCTAssertEqual(YofaiProductIDs.intendedYearlyPriceNote, "$39.99/year")
    }

    func testVerifiedProStillUnlocksAndFreeDefault() async {
        EntitlementStore.shared.resetToLaunchFree()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)

        let service = MockPurchaseService(resolvedPlan: .pro, ownedProductIDs: [YofaiProductIDs.monthly])
        service.products = MockPurchaseService.sampleProducts
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .pro)
        XCTAssertTrue(
            EntitlementPolicy.canCreateProduct(activeProductCount: 100, state: EntitlementStore.shared.state)
        )
    }

    // MARK: - Free safety

    func testFreeCoreExportAndOverLimitSafety() throws {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)

        var limits = FreemiumLimits.launch
        limits.freeActiveProductLimit = 12
        let atLimit = EntitlementState(plan: .free, limits: limits)
        XCTAssertTrue(EntitlementPolicy.canCreateProduct(activeProductCount: 11, state: atLimit))
        XCTAssertFalse(EntitlementPolicy.canCreateProduct(activeProductCount: 12, state: atLimit))

        let container = try makeContainer()
        let context = ModelContext(container)
        for i in 1...13 {
            context.insert(ItemProject(name: "P\(i)", photos: []))
        }
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<ItemProject>()).count, 13)

        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Export",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        context.insert(project)
        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        batch.setSellerNote("note")
        context.insert(batch)
        XCTAssertTrue(batch.hasSellerNote)
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(FreemiumCopy.proBenefitsIntro))
    }

    func testPresetsUnchanged() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
    }
}
