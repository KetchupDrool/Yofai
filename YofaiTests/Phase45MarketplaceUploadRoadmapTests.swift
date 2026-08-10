import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase45MarketplaceUploadRoadmapTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64), format: format)
        return renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        }
    }

    func testLocalExportModeIsCurrentAndDirectUploadNotImplemented() {
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertTrue(YofaiProductMode.localExport.isImplemented)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertFalse(YofaiProductMode.directUpload.sellerFacingSummary.lowercased().contains("available now"))
        XCTAssertTrue(YofaiProductMode.localExport.sellerFacingSummary.lowercased().contains("locally"))
    }

    func testSevenPresetsUnchangedAndTargetSeparateFromCanvas() throws {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))

        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Modes", photos: [])
        project.listingMarketplaceTarget = .facebookMarketplace
        project.listingExportPreset = .marketplace
        context.insert(project)
        XCTAssertEqual(project.listingMarketplaceTarget, .facebookMarketplace)
        XCTAssertEqual(project.listingExportPreset, .marketplace)
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
    }

    func testLocalExportCreatesHistoryWithoutUploadStatusOrAuth() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(name: "Local", photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)])
        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)
        XCTAssertNotNil(batch)
        context.insert(batch!)

        XCTAssertTrue(batch!.exportedForLine.lowercased().contains("exported for"))
        XCTAssertFalse(batch!.exportedForLine.lowercased().contains("published"))
        XCTAssertFalse(batch!.resultSummaryText.lowercased().contains("upload status"))
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
        XCTAssertEqual(YofaiProductMode.current, .localExport)
    }

    func testPhase44NotesAndPhase41FiltersStillWork() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Notes", photos: [])
        context.insert(project)
        let batch = ProjectExportBatch(
            batchFolderName: "n45",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: "eBay",
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            sellerNote: "eBay draft"
        )
        context.insert(batch)

        XCTAssertTrue(batch.hasSellerNote)
        let all = ExportHistorySupport.completedBatches(in: project)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.ebay)).count, 1)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.etsy)).count, 0)
    }

    func testReadinessAndPrepTipsStillWork() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let empty = ItemProject(name: "Empty", photos: [])
        context.insert(empty)
        XCTAssertEqual(ExportReadiness.summary(for: empty).status, .needsAttention)
        XCTAssertEqual(ExportPrepTipSupport.tips(for: empty).first?.id, .addPhotos)
    }

    func testContainPadAndFillCropUnchanged() {
        XCTAssertEqual(ListingExportFitMode.containPad.displayTitle, "Contain + Pad")
        XCTAssertEqual(ListingExportFitMode.fillCrop.displayTitle, "Fill + Crop")
    }
}
