import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase53StoreKitProPaymentsTests: XCTestCase {
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

    // MARK: - Product IDs

    func testProductIDsAreCentralized() {
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
        XCTAssertEqual(YofaiProductIDs.allProSubscriptions, [
            YofaiProductIDs.monthly,
            YofaiProductIDs.yearly
        ])
        XCTAssertTrue(YofaiProductIDs.isProSubscription(YofaiProductIDs.monthly))
        XCTAssertTrue(YofaiProductIDs.isProSubscription(YofaiProductIDs.yearly))
        XCTAssertFalse(YofaiProductIDs.isProSubscription("com.other.app.pro"))
        XCTAssertEqual(YofaiProductIDs.intendedMonthlyPriceNote, "$4.99/month")
        XCTAssertEqual(YofaiProductIDs.intendedYearlyPriceNote, "$39.99/year")
    }

    // MARK: - Entitlement resolution

    func testDefaultNoPurchaseIsFree() async {
        let service = MockPurchaseService(resolvedPlan: .free, products: [])
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
        XCTAssertFalse(EntitlementStore.shared.state.isPro)
        XCTAssertEqual(manager.productsLoadState, .unavailable)
        XCTAssertEqual(manager.statusMessage, FreemiumCopy.purchasesUnavailable)
    }

    func testVerifiedMonthlyUnlocksPro() async {
        let service = MockPurchaseService(resolvedPlan: .pro, ownedProductIDs: [YofaiProductIDs.monthly])
        service.products = MockPurchaseService.sampleProducts
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .pro)
        XCTAssertTrue(EntitlementStore.shared.state.isPro)
        XCTAssertEqual(manager.products.count, 2)
        XCTAssertEqual(manager.productsLoadState, .loaded)
    }

    func testVerifiedYearlyUnlocksPro() async {
        let service = MockPurchaseService(resolvedPlan: .pro, ownedProductIDs: [YofaiProductIDs.yearly])
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .pro)
    }

    func testExpiredOrNoEntitlementIsFree() async {
        let service = MockPurchaseService(resolvedPlan: .free, ownedProductIDs: [])
        service.products = MockPurchaseService.sampleProducts
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
    }

    func testFailedVerificationStaysFree() {
        XCTAssertEqual(
            StoreEntitlementResolver.plan(fromVerifiedProductIDs: [], failedVerification: true),
            .free
        )
        XCTAssertEqual(
            StoreEntitlementResolver.plan(fromVerifiedProductIDs: [YofaiProductIDs.monthly], failedVerification: false),
            .pro
        )
    }

    func testCancellationDoesNotUnlockPro() async {
        let service = MockPurchaseService(resolvedPlan: .free)
        service.products = MockPurchaseService.sampleProducts
        service.nextPurchaseResult = .cancelled
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        let outcome = await manager.purchase(productID: YofaiProductIDs.monthly)
        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
    }

    func testPendingPurchaseDoesNotUnlockProUntilVerified() async {
        let service = MockPurchaseService(resolvedPlan: .free)
        service.products = MockPurchaseService.sampleProducts
        service.nextPurchaseResult = .pending
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        let outcome = await manager.purchase(productID: YofaiProductIDs.monthly)
        XCTAssertEqual(outcome, .pending)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
    }

    func testSuccessfulPurchaseUpdatesEntitlementAfterVerification() async {
        let service = MockPurchaseService(resolvedPlan: .free)
        service.products = MockPurchaseService.sampleProducts
        service.nextPurchaseResult = .success
        service.resolvedPlanAfterPurchase = .pro
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
        let outcome = await manager.purchase(productID: YofaiProductIDs.yearly)
        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .pro)
    }

    func testRestoreSuccessUpdatesEntitlement() async {
        let service = MockPurchaseService(resolvedPlan: .free)
        service.products = MockPurchaseService.sampleProducts
        service.nextRestoreResult = .success
        service.resolvedPlanAfterRestore = .pro
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        let outcome = await manager.restorePurchases()
        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .pro)
    }

    func testRestoreWithNoPurchasesRemainsFree() async {
        let service = MockPurchaseService(resolvedPlan: .free)
        service.products = MockPurchaseService.sampleProducts
        service.nextRestoreResult = .success
        service.resolvedPlanAfterRestore = .free
        let manager = PurchaseManager(service: service)
        let outcome = await manager.restorePurchases()
        XCTAssertEqual(outcome, .success)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
    }

    func testProductLoadFailureShowsUnavailableWithoutFakePurchase() async {
        let service = MockPurchaseService(resolvedPlan: .free)
        service.loadShouldFail = true
        let manager = PurchaseManager(service: service)
        await manager.refreshEntitlementsAndProducts()
        XCTAssertEqual(manager.productsLoadState, .unavailable)
        XCTAssertTrue(manager.products.isEmpty)
        XCTAssertEqual(manager.statusMessage, FreemiumCopy.purchasesUnavailable)
        XCTAssertFalse(FreemiumCopy.purchasesUnavailable.lowercased().contains("charged"))
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
    }

    // MARK: - Free safety

    func testFreeCoreWorkflowAndOverLimitRemainSafe() throws {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .coreLocalExport, state: free).allowsUse)

        var limits = FreemiumLimits.launch
        limits.freeActiveProductLimit = 2
        let limited = EntitlementState(plan: .free, limits: limits)
        XCTAssertFalse(EntitlementPolicy.canCreateProduct(activeProductCount: 2, state: limited))
        XCTAssertTrue(EntitlementPolicy.canCreateProduct(activeProductCount: 1, state: limited))

        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertTrue(EntitlementPolicy.canCreateProduct(activeProductCount: 100, state: pro))
    }

    func testOverLimitProductsNotDeletedWhenReturningToFree() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        for name in ["A", "B", "C", "D"] {
            context.insert(ItemProject(name: name, photos: []))
        }
        try context.save()

        EntitlementStore.shared.applyVerifiedStoreKitPlan(.pro)
        XCTAssertTrue(EntitlementStore.shared.state.isPro)
        EntitlementStore.shared.applyVerifiedStoreKitPlan(.free)
        var limits = FreemiumLimits.launch
        limits.freeActiveProductLimit = 2
        EntitlementStore.shared.limits = limits
        XCTAssertFalse(EntitlementStore.shared.state.isPro)

        let remaining = try context.fetch(FetchDescriptor<ItemProject>())
        XCTAssertEqual(remaining.count, 4)
        XCTAssertFalse(
            EntitlementPolicy.canCreateProduct(
                activeProductCount: remaining.count,
                state: EntitlementStore.shared.state
            )
        )
    }

    func testFreeLocalExportWithoutNetworkRequirement() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Free",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        batch.setSellerNote("keep")
        context.insert(batch)

        XCTAssertTrue(batch.hasSellerNote)
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
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
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
    }
}
