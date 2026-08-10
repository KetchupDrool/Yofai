import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase50AppStorePrepTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
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

    func testLaunchPositioningAndProPlaceholderAreReviewSafe() {
        XCTAssertEqual(AppStoreLaunchSupport.displayName, "Yofai")
        XCTAssertEqual(AppStoreLaunchSupport.bundleID, "com.shawnwright.yofai")
        XCTAssertTrue(AppStoreLaunchSupport.oneLinePositioning.lowercased().contains("local jpeg"))
        XCTAssertTrue(AppStoreLaunchSupport.oneLinePositioning.lowercased().contains("manual upload"))
        XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(AppStoreLaunchSupport.oneLinePositioning))
        XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(AppStoreLaunchSupport.freemiumLaunchNote))
        XCTAssertTrue(FreemiumCopy.proNotAvailableYet.lowercased().contains("no purchase is charged"))
        XCTAssertFalse(FreemiumCopy.proNotAvailableYet.lowercased().contains("$"))
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
    }

    func testLocalExportHelpersAvoidRiskyClaims() {
        let batch = ProjectExportBatch(
            batchFolderName: "p50",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            marketplaceTargetRaw: "eBay",
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            sellerNote: "draft"
        )
        let samples = [
            batch.resultSummaryText,
            batch.exportedForLine,
            batch.historySecondaryLine,
            LocalExportShareSupport.packageSummaryLine(for: batch),
            LocalExportPostExportSupport.nextStepHint,
            AppStoreLaunchSupport.etsyConnectionUnavailableDetail,
            AppStoreLaunchSupport.listingAssistantUnavailableDetail,
            FreemiumCopy.proPlannedSummary
        ]
        for text in samples {
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
            XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(text), text)
            XCTAssertFalse(text.lowercased().contains("direct upload available"))
        }
    }

    func testFreeCoreExportAndPhase49LimitUnchanged() throws {
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport())
        XCTAssertEqual(FreemiumLimits.launch.freeActiveProductLimit, 12)

        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Launch",
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
        XCTAssertTrue(LocalExportPostExportSupport.actions(for: batch).showViewExportedFiles)
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertFalse(batch.resultSummaryText.lowercased().contains("upload status"))
    }

    func testPresetsUnchangedTargetSeparate() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
    }
}
