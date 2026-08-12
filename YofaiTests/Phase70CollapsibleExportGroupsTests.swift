import XCTest
@testable import Yofai

@MainActor
final class Phase70CollapsibleExportGroupsTests: XCTestCase {
    func testDefaultExpandedIncludesPrimaryWorkflow() {
        let expanded = ExportJPEGCollapseGroup.defaultExpanded
        XCTAssertTrue(expanded.contains(.listingInfo))
        XCTAssertTrue(expanded.contains(.photos))
        XCTAssertTrue(expanded.contains(.marketplace))
        XCTAssertTrue(expanded.contains(.exportSetup))
        XCTAssertTrue(expanded.contains(.exportReadiness))
        XCTAssertTrue(expanded.contains(.exportJPEGs))
        XCTAssertFalse(expanded.contains(.exportHistory))
        XCTAssertFalse(expanded.contains(.queue))
    }

    func testDefaultCollapsedIsHistoryAndQueue() {
        XCTAssertEqual(
            ExportJPEGCollapseGroup.defaultCollapsed,
            [.exportHistory, .queue]
        )
        XCTAssertTrue(
            ExportJPEGCollapseGroup.defaultExpanded.isDisjoint(with: ExportJPEGCollapseGroup.defaultCollapsed)
        )
    }

    func testCollapsibleGroupOrderMatchesWorkspaceFlow() {
        XCTAssertEqual(
            ListingWorkspaceSectionOrder.collapsibleGroups,
            [
                .listingInfo,
                .photos,
                .marketplace,
                .exportSetup,
                .exportReadiness,
                .exportJPEGs,
                .exportHistory,
                .queue
            ]
        )
        XCTAssertEqual(ExportJPEGCollapseGroup.listingInfo.title, "Listing Info")
        XCTAssertEqual(ExportJPEGCollapseGroup.exportSetup.title, "Export size & fit")
        XCTAssertEqual(ExportJPEGCollapseGroup.exportReadiness.title, "Export readiness")
        XCTAssertEqual(ExportJPEGCollapseGroup.exportJPEGs.title, "Export JPEGs")
    }

    func testScrollAnchorsExpandCorrectGroups() {
        XCTAssertEqual(
            ExportJPEGCollapseGroup.group(forScrollAnchor: .exportSize),
            .exportSetup
        )
        XCTAssertEqual(
            ExportJPEGCollapseGroup.group(forScrollAnchor: .fit),
            .exportSetup
        )
        XCTAssertEqual(
            ExportJPEGCollapseGroup.group(forScrollAnchor: .preview),
            .exportSetup
        )
        XCTAssertEqual(
            ExportJPEGCollapseGroup.group(forScrollAnchor: .readiness),
            .exportReadiness
        )
        XCTAssertEqual(
            ExportJPEGCollapseGroup.group(forScrollAnchor: .prepTips),
            .exportReadiness
        )
    }

    func testEnsureExpandedInsertsGroup() {
        var expanded = ExportJPEGCollapseGroup.defaultExpanded
        XCTAssertFalse(expanded.contains(.exportHistory))
        ExportJPEGCollapseSupport.ensureExpanded(&expanded, group: .exportHistory)
        XCTAssertTrue(expanded.contains(.exportHistory))
    }

    func testPresetsUnchanged() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
    }
}
