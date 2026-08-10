import XCTest
import SwiftData
@testable import Yofai

@MainActor
final class Phase62DraftAwareListingPackagesTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        super.tearDown()
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    func testPrimaryListingDetailsStillUsesItemProjectFields() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Primary")
        project.listingTitle = "Primary Title"
        project.listingDescription = "Primary Desc"
        project.listingPriceText = "9.99"
        project.listingQuantity = 3
        project.listingCategory = "Home"
        project.listingTags = ["a", "b"]
        project.listingMaterials = "wood"
        project.listingShippingProfile = "USPS"
        project.listingProcessingTime = "2 days"
        context.insert(project)

        EntitlementStore.shared.setPlanForTesting(.pro)
        let draft = try MarketplaceListingDraftSupport.createDraft(
            for: .ebay,
            on: project,
            in: context,
            state: EntitlementStore.shared.state
        )
        draft.title = "Draft Title"
        draft.draftDescription = "Draft Desc"
        draft.priceText = "1.00"

        let primaryText = ListingPackageSupport.listingDetailsText(for: project)
        XCTAssertTrue(primaryText.contains("Title: Primary Title"))
        XCTAssertTrue(primaryText.contains("Description: Primary Desc"))
        XCTAssertTrue(primaryText.contains("Price: 9.99"))
        XCTAssertFalse(primaryText.contains("Draft Title"))
        XCTAssertFalse(primaryText.contains("Prepared for:"))
    }

    func testDraftListingDetailsUsesDraftFieldsNotItemProject() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Mixed")
        project.listingTitle = "Project Title"
        project.listingDescription = "Project Desc"
        project.listingPriceText = "50"
        project.listingMarketplaceTarget = .etsy
        context.insert(project)

        EntitlementStore.shared.setPlanForTesting(.pro)
        let draft = try MarketplaceListingDraftSupport.createDraft(
            for: .poshmark,
            on: project,
            in: context,
            state: EntitlementStore.shared.state
        )
        draft.draftLabel = "Posh Closet"
        draft.title = "Draft Only Title"
        draft.draftDescription = "Draft Only Desc"
        draft.priceText = "22.00"
        draft.quantity = 4
        draft.category = "Dresses"
        draft.condition = "Like new"
        draft.tags = ["posh", "dress"]
        draft.materials = "Cotton"
        draft.shippingNotes = "Ship in 1 day"
        draft.processingTime = "Same day"
        draft.returnsPolicy = "No returns"
        draft.personalizationNotes = "Add monogram"
        draft.marketplaceSellerNotes = "Local pickup note"

        let text = ListingPackageSupport.listingDetailsText(for: draft)
        XCTAssertTrue(text.contains("Prepared for: \(MarketplaceTarget.poshmark.displayTitle)"))
        XCTAssertTrue(text.contains("Draft: Posh Closet"))
        XCTAssertTrue(text.contains("Title: Draft Only Title"))
        XCTAssertTrue(text.contains("Description: Draft Only Desc"))
        XCTAssertTrue(text.contains("Price: 22.00"))
        XCTAssertTrue(text.contains("Quantity: 4"))
        XCTAssertTrue(text.contains("Category: Dresses"))
        XCTAssertTrue(text.contains("Condition: Like new"))
        XCTAssertTrue(text.contains("Tags: posh, dress"))
        XCTAssertTrue(text.contains("Materials: Cotton"))
        XCTAssertTrue(text.contains("Shipping notes: Ship in 1 day"))
        XCTAssertTrue(text.contains("Processing time: Same day"))
        XCTAssertTrue(text.contains("Returns policy: No returns"))
        XCTAssertTrue(text.contains("Personalization: Add monogram"))
        XCTAssertTrue(text.contains("Marketplace seller notes: Local pickup note"))
        XCTAssertFalse(text.contains("Project Title"))
        XCTAssertFalse(text.contains("Project Desc"))
        XCTAssertFalse(text.contains("Price: 50"))
    }

    func testDraftTextIncludesPreparedForAndManualLocalWording() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .etsy)
        draft.title = "Mug"
        let text = MarketplaceDraftPackageSupport.listingDetailsText(for: draft)
        XCTAssertTrue(text.localizedCaseInsensitiveContains("Prepared for"))
        XCTAssertTrue(text.localizedCaseInsensitiveContains("manual"))
        XCTAssertTrue(text.localizedCaseInsensitiveContains("Local JPEGs") || text.contains("Local JPEGs"))
        XCTAssertTrue(text.localizedCaseInsensitiveContains("Draft"))
        XCTAssertEqual(MarketplaceDraftPackageSupport.manualUploadNote.contains("Manual listing package"), true)
    }

    func testDraftTextExcludesDirectUploadPublishLoginOAuthAPI() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .ebay)
        draft.title = "Camera"
        draft.marketplaceSellerNotes = "Seller reminder"
        let text = MarketplaceDraftPackageSupport.listingDetailsText(for: draft)
        XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("post automatically"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("connect marketplace"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("OAuth"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("login"))
        XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text))
        XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text))
    }

    func testFreePrimaryPackageExportRemainsAvailableWithoutPro() {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .exportNotes, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .viewAndReshareExportedFiles, state: free).allowsUse)
        XCTAssertFalse(MarketplaceListingDraftSupport.canUseDraftPackageTools(state: free))
        XCTAssertFalse(MarketplaceDraftPackageSupport.canUse(state: free))
    }

    func testDraftPackageCopyToolsGatedByAdvancedMultiMarketTools() {
        let free = EntitlementState.launchFree
        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertFalse(
            EntitlementPolicy.access(for: .advancedMultiMarketTools, state: free).allowsUse
        )
        XCTAssertTrue(
            EntitlementPolicy.access(for: .advancedMultiMarketTools, state: pro).allowsUse
        )
        XCTAssertEqual(MarketplaceListingDraftSupport.canUseDraftPackageTools(state: free), false)
        XCTAssertEqual(MarketplaceListingDraftSupport.canUseDraftPackageTools(state: pro), true)
        XCTAssertEqual(MarketplaceDraftPackageSupport.canUse(state: free), false)
        XCTAssertEqual(MarketplaceDraftPackageSupport.canUse(state: pro), true)
    }

    func testProCanAccessDraftSpecificCopyPackageTools() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .mercari)
        draft.title = "Bag"
        draft.draftDescription = "Leather"
        draft.priceText = "40"
        draft.quantity = 1
        draft.category = "Accessories"
        draft.condition = "Good"
        draft.tags = ["bag"]
        draft.materials = "Leather"
        draft.shippingNotes = "Boxed"
        draft.processingTime = "1 day"
        draft.returnsPolicy = "7 days"
        draft.personalizationNotes = "Initials"
        draft.marketplaceSellerNotes = "Smoke free"

        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertTrue(MarketplaceDraftPackageSupport.canUse(state: pro))
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .title, draft: draft),
            "Bag"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .description, draft: draft),
            "Leather"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .price, draft: draft),
            "40"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .quantity, draft: draft),
            "1"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .category, draft: draft),
            "Accessories"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .condition, draft: draft),
            "Good"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .tags, draft: draft),
            "bag"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .materials, draft: draft),
            "Leather"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .shippingNotes, draft: draft),
            "Boxed"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .processingTime, draft: draft),
            "1 day"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .returnsPolicy, draft: draft),
            "7 days"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .personalization, draft: draft),
            "Initials"
        )
        XCTAssertEqual(
            MarketplaceDraftPackageSupport.copyableText(for: .marketplaceSellerNotes, draft: draft),
            "Smoke free"
        )
        let all = MarketplaceDraftPackageSupport.copyableText(for: .allListingText, draft: draft)
        XCTAssertEqual(all, MarketplaceDraftPackageSupport.listingDetailsText(for: draft))
        XCTAssertTrue(all.contains("Title: Bag"))
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

    func testFacebookAndMercariRecommendedPresetsRemainNil() {
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
    }

    func testPhase62CopyAvoidsBannedWording() {
        for text in MarketplaceListingDraftCopy.allUserFacingStrings {
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("post automatically"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("connect marketplace"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("marketplace automation"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("OAuth"), text)
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
        }
        XCTAssertEqual(MarketplaceListingDraftCopy.copyListingText, "Copy listing text")
        XCTAssertEqual(MarketplaceListingDraftCopy.copyDraftDetails, "Copy draft details")
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
    }
}
