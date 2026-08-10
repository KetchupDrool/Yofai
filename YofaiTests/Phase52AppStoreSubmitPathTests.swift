import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase52AppStoreSubmitPathTests: XCTestCase {
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

    func testSubmitPackageCopyIsReviewSafe() {
        XCTAssertEqual(AppStoreLaunchSupport.displayName, "Yofai")
        XCTAssertEqual(AppStoreLaunchSupport.bundleID, "com.shawnwright.yofai")
        XCTAssertEqual(AppStoreLaunchSupport.marketingVersion, "1.0")
        XCTAssertEqual(AppStoreLaunchSupport.buildNumber, "1")
        XCTAssertTrue(AppStoreLaunchSupport.shortDescription.lowercased().contains("local jpeg"))
        XCTAssertTrue(AppStoreLaunchSupport.shortDescription.lowercased().contains("manual upload"))
        XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(AppStoreLaunchSupport.shortDescription))
        XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(AppStoreLaunchSupport.shortDescription))
        XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(AppStoreLaunchSupport.freemiumLaunchNote))
        XCTAssertTrue(FreemiumCopy.proNotAvailableYet.lowercased().contains("no purchase is charged"))
        XCTAssertFalse(FreemiumCopy.proNotAvailableYet.lowercased().contains("$"))

        for line in AppStoreLaunchSupport.appReviewNotesLines {
            XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(line), line)
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(line), line)
        }
        XCTAssertTrue(AppStoreLaunchSupport.appReviewNotesLines.contains { $0.lowercased().contains("no purchase is charged") })
        XCTAssertTrue(AppStoreLaunchSupport.appReviewNotesLines.contains { $0.lowercased().contains("direct upload mode is not implemented") })
        XCTAssertTrue(AppStoreLaunchSupport.appReviewNotesLines.contains { $0.lowercased().contains("no ai features") })
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
    }

    func testLocalExportHelpersRemainSubmitSafe() {
        let batch = ProjectExportBatch(
            batchFolderName: "p52",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            marketplaceTargetRaw: "Etsy",
            exportPresetRaw: ListingExportPreset.etsySquare.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 2000,
            exportCanvasHeight: 2000,
            sellerNote: "note"
        )
        let samples = [
            batch.resultSummaryText,
            batch.exportedForLine,
            LocalExportShareSupport.packageSummaryLine(for: batch),
            LocalExportPostExportSupport.nextStepHint,
            AppStoreLaunchSupport.etsyConnectionUnavailableDetail,
            AppStoreLaunchSupport.privacySummary
        ]
        for text in samples {
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
            XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(text), text)
            XCTAssertFalse(text.lowercased().contains("direct upload available"))
            XCTAssertFalse(text.lowercased().contains("upload status"))
        }
    }

    func testFreeCoreExportWithoutStoreKitOrUpload() throws {
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport())
        XCTAssertEqual(FreemiumLimits.launch.freeActiveProductLimit, 12)
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)

        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Submit",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        batch.setSellerNote("keep")
        context.insert(batch)

        XCTAssertTrue(batch.hasSellerNote)
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertTrue(LocalExportPostExportSupport.actions(for: batch).showViewExportedFiles)
        XCTAssertFalse(batch.resultSummaryText.lowercased().contains("upload status"))
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
    }

    func testPresetsUnchangedTargetSeparate() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
    }
}
