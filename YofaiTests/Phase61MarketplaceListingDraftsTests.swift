import XCTest
import SwiftData
@testable import Yofai

@MainActor
final class Phase61MarketplaceListingDraftsTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        super.tearDown()
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    func testPrimaryListingFieldsRoundTripUnchangedWhenDraftAdded() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Lamp")
        project.listingTitle = "Vintage Lamp"
        project.listingDescription = "Brass base"
        project.listingPriceText = "42.00"
        project.listingCategory = "Home"
        project.listingTags = ["vintage", "brass"]
        project.listingMaterials = "Brass"
        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        context.insert(project)

        EntitlementStore.shared.setPlanForTesting(.pro)
        _ = try MarketplaceListingDraftSupport.createDraft(
            for: .ebay,
            on: project,
            in: context,
            state: EntitlementStore.shared.state
        )

        XCTAssertEqual(project.listingTitle, "Vintage Lamp")
        XCTAssertEqual(project.listingDescription, "Brass base")
        XCTAssertEqual(project.listingPriceText, "42.00")
        XCTAssertEqual(project.listingCategory, "Home")
        XCTAssertEqual(project.listingTags, ["vintage", "brass"])
        XCTAssertEqual(project.listingMaterials, "Brass")
        XCTAssertEqual(project.listingMarketplaceTarget, .etsy)
        XCTAssertEqual(project.listingExportPreset, .etsySquare)
        XCTAssertEqual(project.marketplaceDrafts.count, 1)
    }

    func testFreePrimaryWorkflowRemainsAvailableWithoutDrafts() {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .exportNotes, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .viewAndReshareExportedFiles, state: free).allowsUse)
        XCTAssertFalse(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: free))
        XCTAssertFalse(
            EntitlementPolicy.access(for: .advancedMultiMarketTools, state: free).allowsUse
        )
    }

    func testFreeCannotCreateAdditionalMarketplaceDrafts() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Free Product")
        context.insert(project)
        EntitlementStore.shared.resetToLaunchFree()

        XCTAssertThrowsError(
            try MarketplaceListingDraftSupport.createDraft(
                for: .poshmark,
                on: project,
                in: context,
                state: .launchFree
            )
        ) { error in
            XCTAssertEqual(error as? MarketplaceListingDraftError, .proRequired)
        }
        XCTAssertTrue(project.marketplaceDrafts.isEmpty)
        XCTAssertEqual(project.listingTitle, "")
    }

    func testProCanCreateAdditionalMarketplaceDrafts() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Pro Product")
        project.listingTitle = "Seed Title"
        project.listingPriceText = "10"
        context.insert(project)
        let pro = EntitlementState(plan: .pro, limits: .launch)

        let draft = try MarketplaceListingDraftSupport.createDraft(
            for: .mercari,
            on: project,
            in: context,
            state: pro
        )

        XCTAssertEqual(draft.marketplaceTarget, .mercari)
        XCTAssertEqual(draft.title, "Seed Title")
        XCTAssertEqual(draft.priceText, "10")
        XCTAssertEqual(project.listingTitle, "Seed Title")
        XCTAssertTrue(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: pro))
    }

    func testOneDraftPerMarketplacePerProduct() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Unique")
        context.insert(project)
        let pro = EntitlementState(plan: .pro, limits: .launch)

        _ = try MarketplaceListingDraftSupport.createDraft(for: .facebookMarketplace, on: project, in: context, state: pro)
        XCTAssertThrowsError(
            try MarketplaceListingDraftSupport.createDraft(for: .facebookMarketplace, on: project, in: context, state: pro)
        ) { error in
            XCTAssertEqual(error as? MarketplaceListingDraftError, .duplicateMarketplace)
        }
        XCTAssertEqual(project.marketplaceDrafts.count, 1)
    }

    func testAdvancedMultiMarketToolsGatesAdditionalDrafts() {
        let free = EntitlementState.launchFree
        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertEqual(
            EntitlementPolicy.access(for: .advancedMultiMarketTools, state: free),
            .lockedPro(message: FreemiumCopy.plannedProFeature)
        )
        XCTAssertTrue(EntitlementPolicy.access(for: .advancedMultiMarketTools, state: pro).allowsUse)
        XCTAssertEqual(
            MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: free),
            false
        )
        XCTAssertEqual(
            MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: pro),
            true
        )
    }

    func testFacebookAndMercariRecommendedPresetsRemainNil() {
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        XCTAssertEqual(MarketplaceTarget.etsy.recommendedExportPreset, .etsySquare)
        XCTAssertEqual(MarketplaceTarget.ebay.recommendedExportPreset, .ebay)
        XCTAssertEqual(MarketplaceTarget.poshmark.recommendedExportPreset, .poshmark)
    }

    func testExportPresetsUnchanged() {
        let expected: [(ListingExportPreset, String, CGFloat, CGFloat)] = [
            (.etsySquare, "Etsy square", 2000, 2000),
            (.etsyListing, "Etsy listing", 3000, 2400),
            (.instagramSquare, "Instagram square", 1080, 1080),
            (.facebookPost, "Facebook post", 1200, 630),
            (.marketplace, "Marketplace", 1600, 1600),
            (.ebay, "eBay", 1600, 1600),
            (.poshmark, "Poshmark", 1000, 1000)
        ]
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        for (preset, raw, w, h) in expected {
            XCTAssertEqual(preset.rawValue, raw)
            XCTAssertEqual(preset.pixelSize.width, w)
            XCTAssertEqual(preset.pixelSize.height, h)
        }
    }

    func testDraftCopyAvoidsRiskyClaims() {
        for text in MarketplaceListingDraftCopy.allUserFacingStrings {
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("post automatically"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("connect marketplace"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("marketplace automation"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"), text)
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
        }
        XCTAssertTrue(
            MarketplaceListingDraftCopy.preparePackagesLine.contains("Prepare listing packages")
        )
        XCTAssertTrue(
            MarketplaceListingDraftCopy.manualPackageReminder.localizedCaseInsensitiveContains("manual")
        )
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
    }

    func testSchemaIncludesMarketplaceListingDraft() {
        XCTAssertTrue(YofaiModelSchema.models.contains { $0 == MarketplaceListingDraft.self })
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
        XCTAssertEqual(FreemiumLimits.launch.freeActiveProductLimit, 12)
    }
}
