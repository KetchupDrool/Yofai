import XCTest
@testable import Yofai

@MainActor
final class Phase68PaywallWalkthroughClarityTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        PurchaseManager.shared.resetForTesting()
        super.tearDown()
    }

    // MARK: - Paywall prices & Best value

    func testPaywallIntendedFallbackPricesAndBestValue() {
        XCTAssertEqual(FreemiumCopy.intendedMonthlyPriceLabel, "Monthly — $4.99")
        XCTAssertEqual(FreemiumCopy.intendedYearlyPriceLabel, "Yearly — $39.99")
        XCTAssertEqual(FreemiumCopy.bestValueLabel, "Best value")
        XCTAssertTrue(FreemiumCopy.intendedMonthlyPriceLabel.contains("$4.99"))
        XCTAssertTrue(FreemiumCopy.intendedYearlyPriceLabel.contains("$39.99"))
    }

    func testLiveStoreProductTitlesMatchMonthlyYearlyFormatAndBestValue() {
        let monthly = MockPurchaseService.sampleProducts.first { $0.id == YofaiProductIDs.monthly }!
        let yearly = MockPurchaseService.sampleProducts.first { $0.id == YofaiProductIDs.yearly }!
        XCTAssertEqual(monthly.purchaseButtonTitle, "Monthly — $4.99")
        XCTAssertEqual(yearly.purchaseButtonTitle, "Yearly — $39.99")
        XCTAssertFalse(monthly.isBestValue)
        XCTAssertTrue(yearly.isBestValue)
    }

    func testPaywallFreeIncludesAndProAdds() {
        XCTAssertEqual(FreemiumCopy.freeIncludesItems, [
            "Create products",
            "Edit photos",
            "Photo Check",
            "Export JPEGs"
        ])
        XCTAssertEqual(FreemiumCopy.proAddsItems, [
            "Unlimited products",
            "Advanced export history",
            "Marketplace Drafts",
            "Marketplace templates"
        ])
        XCTAssertEqual(FreemiumCopy.freeIncludesTitle, "Free includes")
        XCTAssertEqual(FreemiumCopy.proAddsTitle, "Pro adds")
    }

    func testPaywallDoesNotMarketCloudBackupOrDirectUpload() {
        let marketed = FreemiumCopy.freeIncludesItems + FreemiumCopy.proAddsItems
            + [FreemiumCopy.proBenefitsIntro, FreemiumCopy.proPlannedSummary]
        for text in marketed {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Cloud backup"))
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"))
        }
        XCTAssertEqual(
            FreemiumCopy.paywallExcludedFutureBenefitTitles,
            ["Cloud backup and sync", "Direct Upload Mode"]
        )
        for excluded in FreemiumCopy.paywallExcludedFutureBenefitTitles {
            XCTAssertFalse(marketed.contains(excluded))
        }
    }

    func testStoreKitProductIDsUnchanged() {
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
        XCTAssertEqual(YofaiProductIDs.intendedMonthlyPriceNote, "$4.99/month")
        XCTAssertEqual(YofaiProductIDs.intendedYearlyPriceNote, "$39.99/year")
    }

    func testKeepUsingFreeRestoreAndLegalTitlesRemain() {
        XCTAssertEqual(FreemiumCopy.keepUsingFree, "Keep using Free")
        XCTAssertEqual(FreemiumCopy.restorePurchases, "Restore Purchases")
        XCTAssertEqual(FreemiumCopy.termsOfUseTitle, "Terms of Use")
        XCTAssertEqual(FreemiumCopy.privacyStatementTitle, "Privacy Statement")
    }

    // MARK: - Walkthrough

    func testWalkthroughPagesExplainRequiredTopics() {
        XCTAssertEqual(FirstLaunchGuidePage.allCases.map(\.title), [
            "Yofai",
            "Start with a Product",
            "Add Photos",
            "Check Your Photos",
            "Crop and Focus",
            "Fit Your Photo",
            "Reposition the Crop",
            "Pick Export Size",
            "Choose Marketplace Target",
            "Export JPEGs",
            "Use Export History",
            "Yofai Pro"
        ])
        XCTAssertEqual(FirstLaunchGuidePage.walkthroughPages.count, 11)

        XCTAssertTrue(FirstLaunchGuidePage.photoCheck.bodyText.localizedCaseInsensitiveContains("Photo Check"))
        XCTAssertTrue(FirstLaunchGuidePage.crop.bodyText.localizedCaseInsensitiveContains("Crop"))
        XCTAssertTrue(FirstLaunchGuidePage.fitModes.bodyText.contains("Contain + Pad"))
        XCTAssertTrue(FirstLaunchGuidePage.fitModes.bodyText.contains("Fill + Crop"))
        XCTAssertTrue(FirstLaunchGuidePage.reposition.bodyText.localizedCaseInsensitiveContains("Reposition")
            || FirstLaunchGuidePage.reposition.bodyText.localizedCaseInsensitiveContains("Move the photo"))
        XCTAssertTrue(FirstLaunchGuidePage.exportSize.bodyText.localizedCaseInsensitiveContains("size"))
        XCTAssertTrue(FirstLaunchGuidePage.marketplaceTarget.bodyText.localizedCaseInsensitiveContains("does not upload"))
        XCTAssertTrue(FirstLaunchGuidePage.exportLocal.bodyText.localizedCaseInsensitiveContains("manual upload"))
        XCTAssertTrue(FirstLaunchGuidePage.exportHistory.bodyText.localizedCaseInsensitiveContains("Export"))
        XCTAssertTrue(FirstLaunchGuidePage.startProduct.bodyText.localizedCaseInsensitiveContains("listing info"))
        XCTAssertTrue(FirstLaunchGuidePage.yofaiPro.bodyText.localizedCaseInsensitiveContains("Free"))
    }

    func testWalkthroughCopyExcludesBannedUploadPublishWording() {
        for text in FirstLaunchGuideCopy.allUserFacingStrings {
            let lower = text.lowercased()
            for banned in FirstLaunchGuideCopy.bannedWalkthroughFragments {
                XCTAssertFalse(lower.contains(banned), "Banned '\(banned)' in: \(text)")
            }
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
            XCTAssertFalse(lower.contains("oauth"))
            XCTAssertFalse(FreemiumCopy.purchaseSuccessPro == text)
        }
        XCTAssertTrue(
            FirstLaunchGuidePage.marketplaceTarget.bullets.contains {
                $0.localizedCaseInsensitiveContains("does not upload or publish")
            }
        )
    }

    func testWalkthroughMotionIsSlowerAndHonorsReduceMotion() {
        XCTAssertGreaterThanOrEqual(FirstLaunchGuideMotion.welcomeDuration, 0.8)
        XCTAssertGreaterThanOrEqual(FirstLaunchGuideMotion.pageDuration, 0.5)
        XCTAssertGreaterThanOrEqual(FirstLaunchGuideMotion.stepContentDuration, 0.6)
        XCTAssertGreaterThanOrEqual(FirstLaunchGuideMotion.sceneActDelayNanoseconds, 700_000_000)
        XCTAssertGreaterThanOrEqual(FirstLaunchGuideMotion.sceneSettleDelayNanoseconds, 800_000_000)
        XCTAssertNil(FirstLaunchGuideMotion.welcomeAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.pageAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.sceneActAnimation(reduceMotion: true))
        XCTAssertNotNil(FirstLaunchGuideMotion.pageAnimation(reduceMotion: false))
        XCTAssertNotNil(FirstLaunchGuideMotion.sceneEnterAnimation(reduceMotion: false))
    }

    func testSceneKindsMapOneToOneWithPages() {
        XCTAssertEqual(FirstLaunchGuideSceneKind.allCases.count, FirstLaunchGuidePage.allCases.count)
        XCTAssertEqual(
            FirstLaunchGuidePage.allCases.map { FirstLaunchGuideSceneKind.kind(for: $0) },
            FirstLaunchGuideSceneKind.allCases
        )
    }

    // MARK: - Seller wording + presets

    func testFocusedSellerCTAWording() {
        XCTAssertEqual(SellerNavigationSupport.projectIntakeLinkTitle, "Photos")
        XCTAssertEqual(SellerNavigationSupport.projectWorkspaceLinkTitle, "Export JPEGs")
        XCTAssertEqual(MarketplaceListingDraftCopy.sectionTitle, "Marketplace Drafts")
        XCTAssertEqual(MarketplaceListingDraftCopy.openPrimaryWorkspace, "Open Export JPEGs")
        XCTAssertEqual(MarketplaceListingDraftCopy.copyListingText, "Copy listing text")
    }

    func testPresetsAndFuturePolicyUnchanged() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        // Future enum cases remain for policy; still locked even for Pro.
        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertFalse(EntitlementPolicy.access(for: .cloudBackupSync, state: pro).allowsUse)
        XCTAssertFalse(EntitlementPolicy.access(for: .directUploadMode, state: pro).allowsUse)
    }
}
