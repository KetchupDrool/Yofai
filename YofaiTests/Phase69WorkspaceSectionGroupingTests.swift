import XCTest
@testable import Yofai

@MainActor
final class Phase69WorkspaceSectionGroupingTests: XCTestCase {
    func testWorkspaceNavigationTitleAndGroupOrder() {
        XCTAssertEqual(ListingWorkspaceSectionOrder.navigationTitle, "Export JPEGs")
        XCTAssertEqual(SellerNavigationSupport.projectWorkspaceLinkTitle, "Export JPEGs")
        XCTAssertEqual(ListingWorkspaceSectionOrder.groupHeaders, [
            "Overview",
            "Listing Info",
            "Product Intake",
            "Photos (current order)",
            "Marketplace Drafts",
            "Marketplace",
            "Export size",
            "Fit",
            "Photo check",
            "Preview",
            "Export Readiness",
            "Prep Tips",
            "Export JPEGs",
            "Listing Package",
            "Export History",
            "Queue readiness",
            "Listing Queue"
        ])
    }

    func testExportSettingsPartOrderKeepsClustersContiguous() {
        XCTAssertEqual(
            ListingWorkspaceSectionOrder.exportSettingsPartOrder,
            [.marketplace, .exportSetup, .preview, .readiness]
        )
        XCTAssertEqual(MarketplaceExportSettingsPart.allCases.count, 4)
    }

    func testListingComesBeforePhotosBeforeMarketplaceBeforeExport() {
        let headers = ListingWorkspaceSectionOrder.groupHeaders
        let listing = headers.firstIndex(of: "Listing Info")!
        let photos = headers.firstIndex(of: "Photos (current order)")!
        let drafts = headers.firstIndex(of: "Marketplace Drafts")!
        let size = headers.firstIndex(of: "Export size")!
        let preview = headers.firstIndex(of: "Preview")!
        let readiness = headers.firstIndex(of: "Export Readiness")!
        let export = headers.firstIndex(of: "Export JPEGs")!
        let history = headers.firstIndex(of: "Export History")!
        let queueReady = headers.firstIndex(of: "Queue readiness")!
        let queue = headers.firstIndex(of: "Listing Queue")!

        XCTAssertLessThan(listing, photos)
        XCTAssertLessThan(photos, drafts)
        XCTAssertLessThan(drafts, size)
        XCTAssertLessThan(size, preview)
        XCTAssertLessThan(preview, readiness)
        XCTAssertLessThan(readiness, export)
        XCTAssertLessThan(export, history)
        XCTAssertLessThan(history, queueReady)
        XCTAssertLessThan(queueReady, queue)
    }

    func testQueueReadinessDistinctFromExportReadiness() {
        let headers = ListingWorkspaceSectionOrder.groupHeaders
        XCTAssertTrue(headers.contains("Export Readiness"))
        XCTAssertTrue(headers.contains("Queue readiness"))
        XCTAssertNotEqual(
            headers.firstIndex(of: "Export Readiness"),
            headers.firstIndex(of: "Queue readiness")
        )
    }

    func testPresetsAndProductModeUnchanged() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
    }

    func testGroupHeadersAvoidBannedUploadPublishClaims() {
        for header in ListingWorkspaceSectionOrder.groupHeaders {
            XCTAssertFalse(header.localizedCaseInsensitiveContains("Direct Upload"))
            XCTAssertFalse(header.localizedCaseInsensitiveContains("publish"))
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(header))
        }
    }
}
