import XCTest
import SwiftUI
@testable import Yofai

@MainActor
final class Phase67PostReadabilityUIQATests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        super.tearDown()
    }

    func testTabClearanceIncreasedAfterQAPass() {
        XCTAssertGreaterThanOrEqual(DarkroomReadability.listBottomClearance, 72)
        XCTAssertGreaterThanOrEqual(DarkroomReadability.tabBarSafeAreaBoost, 48)
    }

    func testPlaceholderContrastFloorRaised() {
        XCTAssertGreaterThanOrEqual(DarkroomReadability.placeholderOnDarkContrast, 5.5)
        XCTAssertEqual(DarkroomTheme.textPlaceholder, Color.white.opacity(0.68))
    }

    func testFreePrimaryWorkflowRemainsAvailable() {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertFalse(
            EntitlementPolicy.access(for: .advancedMultiMarketTools, state: free).allowsUse
        )
    }

    func testProMultiMarketStillGated() {
        let free = EntitlementState.launchFree
        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertFalse(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: free))
        XCTAssertTrue(MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: pro))
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

    func testNoBannedUploadPublishAPIWording() {
        let samples = [
            MarketplaceListingDraftCopy.proLockedDetail,
            MarketplaceTemplateDefaultsCopy.lockedDetail,
            MarketplaceDraftWorkflowCopy.reviewBeforeManualUpload,
            AppStoreLaunchSupport.privacySummary
        ]
        for text in samples {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("ready to publish"), text)
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
        }
    }
}
