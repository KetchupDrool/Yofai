import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase40ExportBatchHistoryTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor, size: CGFloat = 64) -> UIImage {
        let sz = CGSize(width: size, height: size)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: sz, format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: sz))
        }
    }

    private func makeProject(photoCount: Int = 2, in context: ModelContext) throws -> ItemProject {
        var photos: [ItemProjectPhoto] = []
        for index in 0..<photoCount {
            let file = try LocalEditStore.saveProjectImage(makeImage(color: index % 2 == 0 ? .red : .blue))
            photos.append(ItemProjectPhoto(localFileName: file, sortOrder: index))
        }
        let project = ItemProject(name: "History Project", photos: photos)
        context.insert(project)
        return project
    }

    // MARK: - Persistence / presets

    func testProjectWithNoPhase40HistoryLoadsNormally() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        XCTAssertTrue(project.sortedCompletedExportBatches.isEmpty)
        XCTAssertEqual(project.listingMarketplaceTarget, .other)
        XCTAssertEqual(project.listingExportFitMode, .containPad)
    }

    func testLegacyBatchWithoutMetadataFallsBackSafely() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        let result = try ProjectBatchExporter.export(project: project)
        let legacy = ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            project: project
        )
        context.insert(legacy)
        XCTAssertEqual(legacy.marketplaceTargetRaw, "")
        XCTAssertEqual(legacy.recordedMarketplaceTarget, .other)
        XCTAssertTrue(legacy.sellerSummaryLabel.contains("Earlier export"))
        XCTAssertEqual(legacy.recordedFitMode, .containPad)
    }

    func testSevenPresetRawValuesAndDimensionsUnchanged() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.etsyListing.rawValue, "Etsy listing")
        XCTAssertEqual(ListingExportPreset.instagramSquare.rawValue, "Instagram square")
        XCTAssertEqual(ListingExportPreset.facebookPost.rawValue, "Facebook post")
        XCTAssertEqual(ListingExportPreset.marketplace.rawValue, "Marketplace")
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertEqual(ListingExportPreset.marketplace.pixelSize, CGSize(width: 1600, height: 1600))
    }

    // MARK: - History recording

    func testSuccessfulExportCreatesOneHistoryEntryWithMetadata() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 3, in: context)
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        project.listingExportFitMode = .fillCrop
        project.listingWatermarkEnabled = true
        project.listingWatermarkText = "Shop"

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)
        XCTAssertNotNil(batch)
        context.insert(batch!)
        try context.save()

        XCTAssertEqual(project.sortedCompletedExportBatches.count, 1)
        let saved = project.sortedCompletedExportBatches[0]
        XCTAssertEqual(saved.marketplaceTargetRaw, "eBay")
        XCTAssertEqual(saved.exportPresetRaw, "eBay")
        XCTAssertEqual(saved.exportCanvasWidth, 1600)
        XCTAssertEqual(saved.exportCanvasHeight, 1600)
        XCTAssertEqual(saved.exportFitModeRaw, "Fill + Crop")
        XCTAssertEqual(saved.successCount, 3)
        XCTAssertTrue(saved.watermarkEnabled)
        XCTAssertTrue(saved.createdAt.timeIntervalSinceNow < 5)
        XCTAssertEqual(saved.sellerSummaryLabel, "eBay • 1600×1600 • 3 photos")
        XCTAssertEqual(saved.exportedForLine, "Exported for eBay")
        XCTAssertFalse(saved.resultSummaryText.lowercased().contains("publish"))
        XCTAssertFalse(saved.resultSummaryText.lowercased().contains("compliance"))
    }

    func testZeroSuccessDoesNotCreateHistoryEntry() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Empty", photos: [])
        context.insert(project)
        let emptyResult = ProjectBatchExportResult(
            batchFolderName: "none",
            orderedFileNames: [],
            successCount: 0,
            errorMessages: ["failed"]
        )
        XCTAssertNil(ProjectExportBatch.recordSuccessfulExport(from: emptyResult, project: project))
        XCTAssertTrue(project.sortedCompletedExportBatches.isEmpty)
    }

    func testFacebookMarketplaceGuidanceLabelUsesChosenCanvas() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        project.listingMarketplaceTarget = .facebookMarketplace
        project.listingExportPreset = .marketplace
        project.listingExportFitMode = .containPad

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)

        XCTAssertEqual(batch.recordedMarketplaceTarget, .facebookMarketplace)
        XCTAssertEqual(batch.exportPresetRaw, "Marketplace")
        XCTAssertEqual(batch.pixelSizeLabel, "1600×1600")
        XCTAssertEqual(batch.sellerSummaryLabel, "Facebook Marketplace • 1600×1600 • 1 photo")
        XCTAssertFalse(batch.sellerSummaryLabel.lowercased().contains("verified"))
    }

    func testMultiTargetExportsCreateDistinctEntriesNewestFirst() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)

        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        let etsyResult = try ProjectBatchExporter.export(project: project)
        context.insert(ProjectExportBatch.recordSuccessfulExport(from: etsyResult, project: project)!)

        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        let ebayResult = try ProjectBatchExporter.export(project: project)
        context.insert(ProjectExportBatch.recordSuccessfulExport(from: ebayResult, project: project)!)

        let batches = project.sortedCompletedExportBatches
        XCTAssertEqual(batches.count, 2)
        XCTAssertEqual(batches[0].recordedMarketplaceTarget, .ebay)
        XCTAssertEqual(batches[1].recordedMarketplaceTarget, .etsy)
        XCTAssertEqual(batches[0].pixelSizeLabel, "1600×1600")
        XCTAssertEqual(batches[1].pixelSizeLabel, "2000×2000")
    }

    // MARK: - Re-export settings

    func testApplyExportSettingsRestoresExportLevelOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        var state = PhotoEditState()
        state.quarterTurns = 1
        state.filter = .mono
        state.brightness = 0.2
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 0.7, y: -0.4)
        project.sortedPhotos[0].savedEditState = state

        project.listingMarketplaceTarget = .poshmark
        project.listingExportPreset = .poshmark
        project.listingExportFitMode = .fillCrop
        project.listingWatermarkEnabled = true

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)

        // Change project settings away from the batch.
        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        project.listingWatermarkEnabled = false

        batch.applyExportSettings(to: project)

        XCTAssertEqual(project.listingMarketplaceTarget, .poshmark)
        XCTAssertEqual(project.listingExportPreset, .poshmark)
        XCTAssertEqual(project.listingExportFitMode, .fillCrop)
        XCTAssertTrue(project.listingWatermarkEnabled)

        let photoState = project.sortedPhotos[0].savedEditState
        XCTAssertEqual(photoState?.quarterTurns, 1)
        XCTAssertEqual(photoState?.filter, .mono)
        XCTAssertEqual(photoState?.brightness ?? 0, 0.2, accuracy: 0.0001)
        XCTAssertEqual(photoState?.fillCropOffsetX ?? 0, 0.7, accuracy: 0.0001)
        XCTAssertEqual(photoState?.fillCropOffsetY ?? 0, -0.4, accuracy: 0.0001)
    }

    func testRecordReloadPreservesMetadata() throws {
        let container = try makeContainer()
        let batchID: PersistentIdentifier
        do {
            let context = ModelContext(container)
            let project = try makeProject(photoCount: 2, in: context)
            project.listingMarketplaceTarget = .mercari
            project.listingExportPreset = .instagramSquare
            project.listingExportFitMode = .containPad
            let result = try ProjectBatchExporter.export(project: project)
            let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
            context.insert(batch)
            try context.save()
            batchID = batch.persistentModelID
        }
        let reload = ModelContext(container)
        let batch = reload.model(for: batchID) as! ProjectExportBatch
        XCTAssertEqual(batch.recordedMarketplaceTarget, .mercari)
        XCTAssertEqual(batch.exportPresetRaw, "Instagram square")
        XCTAssertEqual(batch.exportCanvasWidth, 1080)
        XCTAssertEqual(batch.exportCanvasHeight, 1080)
        XCTAssertEqual(batch.recordedFitMode, .containPad)
        XCTAssertEqual(batch.successCount, 2)
    }

    // MARK: - Regressions

    func testPhase38OffsetsStillHonoredAfterHistoryCapture() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 100), format: format)
        let wideImage = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 100, y: 0, width: 100, height: 100))
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 200, y: 0, width: 100, height: 100))
            UIColor.yellow.setFill()
            ctx.fill(CGRect(x: 300, y: 0, width: 100, height: 100))
        }
        let file = try LocalEditStore.saveProjectImage(wideImage)
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 1, y: 0)
        photo.savedEditState = state
        let project = ItemProject(name: "Offsets", photos: [photo])
        project.listingExportFitMode = .fillCrop
        project.listingExportPreset = .instagramSquare
        project.listingMarketplaceTarget = .other
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)

        XCTAssertEqual(photo.savedEditState?.fillCropOffsetX ?? 0, 1, accuracy: 0.0001)
        guard let url = LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: "01.jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return XCTFail("Missing export")
        }
        XCTAssertEqual(Int(image.size.width), 1080)
        XCTAssertEqual(Int(image.size.height), 1080)
    }

    func testPhase39MarketplaceSwitchStillWorks() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        MarketplaceExportSupport.switchTarget(on: project, to: .ebay, applyRecommendedCanvas: true)
        XCTAssertEqual(project.listingMarketplaceTarget, .ebay)
        XCTAssertEqual(project.listingExportPreset, .ebay)
    }

    func testSellerDefaultsStillApply() throws {
        var defaults = SellerDefaults()
        defaults.marketplaceTarget = .etsy
        defaults.exportPreset = .etsySquare
        let project = ItemProject(name: "Defaults", photos: [])
        defaults.apply(to: project)
        XCTAssertEqual(project.listingMarketplaceTarget, .etsy)
        XCTAssertEqual(project.listingExportPreset, .etsySquare)
    }

    func testDeletingHistoryRemovesBatchFolderNotSourcePhotos() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        let sourceName = project.sortedPhotos[0].localFileName
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)

        LocalEditStore.deleteExportBatchFolder(folderName: batch.batchFolderName)
        context.delete(batch)

        XCTAssertNil(LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: "01.jpg"))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: sourceName))
    }
}
