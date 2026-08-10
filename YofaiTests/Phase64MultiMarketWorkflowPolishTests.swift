import XCTest
import SwiftData
@testable import Yofai

@MainActor
final class Phase64MultiMarketWorkflowPolishTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        super.tearDown()
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeTemplateStore() -> MarketplaceTemplateDefaultsStore {
        let suiteName = "yofai.tests.phase64.templates.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removeObject(forKey: MarketplaceTemplateDefaultsStore.storageKey)
        return MarketplaceTemplateDefaultsStore(defaults: suite)
    }

    private func makeSellerDefaultsStore() -> SellerDefaultsStore {
        let suiteName = "yofai.tests.phase64.sellerDefaults.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removeObject(forKey: SellerDefaultsStore.storageKey)
        return SellerDefaultsStore(defaults: suite)
    }

    func testFreePrimaryWorkflowRemainsAvailable() {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .exportNotes, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .viewAndReshareExportedFiles, state: free).allowsUse)
        XCTAssertFalse(MarketplaceDraftCompletionSupport.canUseWorkflowPolish(state: free))
    }

    func testFreeLockedCopyExplainsProWithoutBlockingPrimaryExport() {
        let locked = MarketplaceListingDraftCopy.proLockedDetail
        XCTAssertTrue(locked.localizedCaseInsensitiveContains("advanced multi-market"))
        XCTAssertTrue(locked.localizedCaseInsensitiveContains("primary listing workflow"))
        XCTAssertTrue(locked.localizedCaseInsensitiveContains("local export"))
        XCTAssertFalse(locked.localizedCaseInsensitiveContains("cannot export"))
        XCTAssertFalse(locked.localizedCaseInsensitiveContains("upload directly"))
        XCTAssertEqual(locked, MarketplaceDraftWorkflowCopy.polishLockedDetail)
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: .launchFree))
    }

    func testProDraftOverviewStatusHelpers() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .etsy)
        XCTAssertEqual(
            MarketplaceDraftCompletionSupport.snapshot(for: draft).quickStatusLine,
            MarketplaceDraftWorkflowCopy.missingTitle
        )

        draft.title = "Lamp"
        XCTAssertEqual(
            MarketplaceDraftCompletionSupport.snapshot(for: draft).quickStatusLine,
            MarketplaceDraftWorkflowCopy.missingDescription
        )

        draft.draftDescription = "Brass base"
        XCTAssertEqual(
            MarketplaceDraftCompletionSupport.snapshot(for: draft).quickStatusLine,
            MarketplaceDraftWorkflowCopy.noPrice
        )

        draft.priceText = "42"
        let complete = MarketplaceDraftCompletionSupport.snapshot(for: draft)
        XCTAssertEqual(complete.quickStatusLine, MarketplaceDraftWorkflowCopy.readyToCopy)
        XCTAssertTrue(complete.isBasicsComplete)
        XCTAssertEqual(complete.primaryActionHint, MarketplaceDraftWorkflowCopy.draftBasicsComplete)
        XCTAssertEqual(
            MarketplaceDraftCompletionSupport.preparedForLine(for: draft),
            "Prepared for \(MarketplaceTarget.etsy.displayTitle)"
        )
    }

    func testDraftCompletionIndicatorsAvoidCompliancePublishWording() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .ebay)
        draft.title = "Camera"
        draft.draftDescription = "Works"
        draft.priceText = "100"
        let snapshot = MarketplaceDraftCompletionSupport.snapshot(for: draft)
        let lines = [
            snapshot.quickStatusLine,
            snapshot.primaryActionHint,
            MarketplaceDraftWorkflowCopy.reviewBeforeManualUpload
        ] + snapshot.missingHints + MarketplaceDraftWorkflowCopy.allUserFacingStrings

        for text in lines {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("marketplace ready"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("ready to publish"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("approved"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("compliant"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
        }
    }

    func testTemplateAvailabilityTextReflectsSavedState() {
        XCTAssertEqual(
            MarketplaceDraftCompletionSupport.templateAvailabilityText(hasTemplate: true),
            MarketplaceDraftWorkflowCopy.templateAvailable
        )
        XCTAssertEqual(
            MarketplaceDraftCompletionSupport.templateAvailabilityText(hasTemplate: false),
            MarketplaceDraftWorkflowCopy.noSavedTemplate
        )
        XCTAssertEqual(MarketplaceTemplateDefaultsCopy.templateAvailable, "Template available")
        XCTAssertEqual(MarketplaceTemplateDefaultsCopy.noSavedTemplate, "No saved template")
    }

    func testApplyTemplateStillFillsBlankFieldsOnly() throws {
        let store = makeTemplateStore()
        let pro = EntitlementState(plan: .pro, limits: .launch)
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .poshmark
        template.defaultCategory = "Template Cat"
        template.defaultDescription = "Template Desc"
        template.defaultMaterials = "Template Mat"
        try store.save(template, state: pro)

        let draft = MarketplaceListingDraft(marketplaceTarget: .poshmark)
        draft.category = "Keep Me"
        draft.draftDescription = ""
        draft.materials = ""

        let loaded = try XCTUnwrap(store.template(for: .poshmark))
        _ = MarketplaceTemplateDefaultsSupport.applyToBlankFields(loaded, onto: draft)
        XCTAssertEqual(draft.category, "Keep Me")
        XCTAssertEqual(draft.draftDescription, "Template Desc")
        XCTAssertEqual(draft.materials, "Template Mat")
    }

    func testCopyShareTextRemainsManualLocal() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .mercari)
        draft.title = "Bag"
        draft.draftDescription = "Leather"
        draft.priceText = "40"
        let packageText = MarketplaceDraftPackageSupport.listingDetailsText(for: draft)
        let helpers = [
            packageText,
            MarketplaceDraftWorkflowCopy.copyShareHelper,
            MarketplaceListingDraftCopy.manualUploadFooter,
            MarketplaceListingDraftCopy.copyListingText,
            MarketplaceListingDraftCopy.copyDraftDetails,
            MarketplaceListingDraftCopy.shareListingText
        ]
        for text in helpers {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("OAuth"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("ready to publish"), text)
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
        }
        XCTAssertTrue(MarketplaceDraftWorkflowCopy.copyShareHelper.contains("manually creating"))
        XCTAssertTrue(packageText.localizedCaseInsensitiveContains("manual"))
        XCTAssertTrue(packageText.contains("Local JPEGs") || packageText.localizedCaseInsensitiveContains("local"))
    }

    func testExistingSellerDefaultsRemainPreserved() {
        let store = makeSellerDefaultsStore()
        var value = SellerDefaults()
        value.category = "Home"
        value.materials = "wood"
        store.save(value)
        let reloaded = store.load()
        XCTAssertEqual(reloaded.category, "Home")
        XCTAssertEqual(reloaded.materials, "wood")
        XCTAssertEqual(SellerDefaultsStore.storageKey, "com.shawnwright.yofai.sellerDefaults")
        XCTAssertNotEqual(SellerDefaultsStore.storageKey, MarketplaceTemplateDefaultsStore.storageKey)
    }

    func testAdvancedMultiMarketToolsGatesPolish() {
        let free = EntitlementState.launchFree
        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertFalse(EntitlementPolicy.access(for: .advancedMultiMarketTools, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .advancedMultiMarketTools, state: pro).allowsUse)
        XCTAssertEqual(MarketplaceDraftCompletionSupport.canUseWorkflowPolish(state: free), false)
        XCTAssertEqual(MarketplaceDraftCompletionSupport.canUseWorkflowPolish(state: pro), true)
        XCTAssertEqual(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: free), false)
        XCTAssertEqual(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: pro), true)
    }

    func testFacebookAndMercariRecommendedPresetsRemainNil() {
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
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

    func testPhase64CopyAvoidsBannedWording() {
        let all = MarketplaceDraftWorkflowCopy.allUserFacingStrings
            + MarketplaceListingDraftCopy.allUserFacingStrings
        for text in Set(all) {
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("post automatically"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("connect marketplace"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("marketplace automation"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("ready to publish"), text)
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
        }
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
    }

    func testPhotoPresenceIsDeterministic() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Photos")
        context.insert(project)
        let draft = MarketplaceListingDraft(marketplaceTarget: .other, project: project)
        context.insert(draft)
        XCTAssertFalse(MarketplaceDraftCompletionSupport.snapshot(for: draft, project: project).hasUsablePhoto)

        let photo = ItemProjectPhoto(localFileName: "placeholder.jpg", sortOrder: 0)
        project.photos.append(photo)
        XCTAssertTrue(MarketplaceDraftCompletionSupport.snapshot(for: draft, project: project).hasUsablePhoto)
    }
}
