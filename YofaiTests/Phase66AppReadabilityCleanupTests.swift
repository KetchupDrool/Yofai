import XCTest
@testable import Yofai

@MainActor
final class Phase66AppReadabilityCleanupTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        super.tearDown()
    }

    func testReadableTextTokensAreBrighterThanLegacyFloor() {
        // Opacity floors chosen so secondary/tertiary/placeholder stay scannable on dark cards.
        XCTAssertGreaterThanOrEqual(DarkroomReadability.secondaryOnDarkContrast, 4.5)
        XCTAssertGreaterThanOrEqual(DarkroomReadability.tertiaryOnDarkContrast, 4.5)
        XCTAssertGreaterThanOrEqual(DarkroomReadability.placeholderOnDarkContrast, 4.5)
        XCTAssertGreaterThanOrEqual(DarkroomReadability.primaryOnDarkContrast, 7.0)
        XCTAssertEqual(DarkroomReadability.minTapTarget, 44)
        XCTAssertGreaterThanOrEqual(DarkroomReadability.listBottomClearance, 24)
    }

    func testSharedFormChromeHelpersExist() {
        XCTAssertEqual(DarkroomTheme.listRowCornerRadius, 14)
        XCTAssertNotEqual(DarkroomTheme.surfaceRaised, DarkroomTheme.surface)
        _ = DarkroomListRowBackground()
        DarkroomReadableChrome.applyIfNeeded()
        XCTAssertTrue(DarkroomReadableChrome.hasAppliedForTesting)
    }

    func testFreePrimaryWorkflowRemainsAvailable() {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .exportNotes, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .viewAndReshareExportedFiles, state: free).allowsUse)
        XCTAssertFalse(
            EntitlementPolicy.access(for: .advancedMultiMarketTools, state: free).allowsUse
        )
    }

    func testProMultiMarketStillGated() {
        let free = EntitlementState.launchFree
        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertFalse(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: free))
        XCTAssertTrue(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: pro))
        XCTAssertFalse(MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: free))
        XCTAssertTrue(MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: pro))
    }

    func testApplyTemplateStillFillsBlankFieldsOnly() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .etsy)
        draft.category = "Keep"
        draft.draftDescription = ""
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .etsy
        template.defaultCategory = "Replace?"
        template.defaultDescription = "Filled"
        _ = MarketplaceTemplateDefaultsSupport.applyToBlankFields(template, onto: draft)
        XCTAssertEqual(draft.category, "Keep")
        XCTAssertEqual(draft.draftDescription, "Filled")
    }

    func testNoBannedUploadPublishAPIWordingInReadabilityChromeCopy() {
        let samples = [
            MarketplaceListingDraftCopy.proLockedDetail,
            MarketplaceListingDraftCopy.manualPackageReminder,
            MarketplaceTemplateDefaultsCopy.lockedDetail,
            MarketplaceDraftWorkflowCopy.copyShareHelper,
            MarketplaceDraftWorkflowCopy.reviewBeforeManualUpload,
            AppStoreLaunchSupport.privacySummary
        ]
        for text in samples {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("ready to publish"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"), text)
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
        }
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

    func testSellerDefaultsKeyUnchanged() {
        XCTAssertEqual(SellerDefaultsStore.storageKey, "com.shawnwright.yofai.sellerDefaults")
        XCTAssertEqual(
            MarketplaceTemplateDefaultsStore.storageKey,
            "com.shawnwright.yofai.marketplaceTemplateDefaults.v1"
        )
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
    }
}
