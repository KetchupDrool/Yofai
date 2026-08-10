import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase48FinalLocalExportPolishTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32), format: format)
        return renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }
    }

    // MARK: - Post-export next step

    func testSuccessfulExportExposesViewExportedFilesNextStep() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Next",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)

        let summary = batch.resultSummaryText
        XCTAssertTrue(summary.contains("local JPEG"))
        XCTAssertTrue(summary.contains("Manual upload"))

        let actions = LocalExportPostExportSupport.actions(for: batch)
        XCTAssertTrue(actions.showViewExportedFiles)
        XCTAssertEqual(LocalExportPostExportSupport.primaryNextStepTitle, "View Exported Files")
        XCTAssertTrue(actions.showShareExportedPhotos)
        XCTAssertTrue(actions.showAddEditNote)
        XCTAssertFalse(actions.showShareWithNote)
        XCTAssertFalse(actions.showCopyExportNote)
    }

    func testNextStepUsesJustCreatedBatchWithoutNewHistoryOrMutation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Stable",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .fillCrop
        project.listingWatermarkEnabled = false
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        batch.setSellerNote("draft note")
        context.insert(batch)
        try context.save()

        let historyBefore = ExportHistorySupport.completedBatches(in: project).count
        let urls = batch.fileURLs
        XCTAssertFalse(urls.isEmpty)
        let dataBefore = try Data(contentsOf: urls[0])
        let settingsBefore = (
            project.listingMarketplaceTarget,
            project.listingExportPreset,
            project.listingExportFitMode,
            project.listingWatermarkEnabled,
            batch.sellerNote
        )

        let actions = LocalExportPostExportSupport.actions(for: batch)
        XCTAssertTrue(actions.showViewExportedFiles)
        XCTAssertTrue(actions.showShareExportedPhotos)
        XCTAssertTrue(actions.showShareWithNote)
        XCTAssertTrue(actions.showCopyExportNote)

        let share = ShareBatchItem(
            urls: ExportBatchFileAccessSupport.shareableURLs(for: batch),
            caption: LocalExportShareSupport.shareCaption(for: batch, includeNote: true)
        )
        XCTAssertEqual(share.urls, urls)

        XCTAssertEqual(ExportHistorySupport.completedBatches(in: project).count, historyBefore)
        XCTAssertEqual(project.listingMarketplaceTarget, settingsBefore.0)
        XCTAssertEqual(project.listingExportPreset, settingsBefore.1)
        XCTAssertEqual(project.listingExportFitMode, settingsBefore.2)
        XCTAssertEqual(project.listingWatermarkEnabled, settingsBefore.3)
        XCTAssertEqual(batch.sellerNote, settingsBefore.4)
        XCTAssertEqual(try Data(contentsOf: urls[0]), dataBefore)
    }

    // MARK: - Wording + actions

    func testLocalExportHelpersAvoidPublishUploadWording() {
        let batch = ProjectExportBatch(
            batchFolderName: "w48",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            marketplaceTargetRaw: "eBay",
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            sellerNote: "eBay draft"
        )

        let samples = [
            batch.resultSummaryText,
            batch.exportedForLine,
            batch.historyPrimaryLine,
            batch.historySecondaryLine,
            LocalExportShareSupport.packageSummaryLine(for: batch),
            LocalExportPostExportSupport.nextStepHint,
            LocalExportPostExportSupport.primaryNextStepTitle,
            LocalExportShareSupport.shareExportedPhotosTitle,
            LocalExportShareSupport.manualUploadLabel,
            ExportBatchFileAccessSupport.filesUnavailableMessage
        ]

        for text in samples {
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
            XCTAssertFalse(text.lowercased().contains("published"))
            XCTAssertFalse(text.lowercased().contains("direct upload"))
            XCTAssertFalse(text.lowercased().contains("sent to marketplace"))
            XCTAssertFalse(text.lowercased().contains("connect marketplace"))
        }
    }

    func testNoteAndMissingFileActionAvailability() {
        let withNote = ProjectExportBatch(
            batchFolderName: "missing-files",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            sellerNote: "keep"
        )
        let noNote = ProjectExportBatch(
            batchFolderName: "missing-files-2",
            orderedFileNames: ["01.jpg"],
            successCount: 1
        )

        let missingWithNote = LocalExportPostExportSupport.actions(for: withNote)
        XCTAssertTrue(missingWithNote.showViewExportedFiles)
        XCTAssertFalse(missingWithNote.showShareExportedPhotos)
        XCTAssertFalse(missingWithNote.showShareWithNote)
        XCTAssertTrue(missingWithNote.showCopyExportNote)

        let missingNoNote = LocalExportPostExportSupport.actions(for: noNote)
        XCTAssertFalse(missingNoNote.showShareWithNote)
        XCTAssertFalse(missingNoNote.showCopyExportNote)
        XCTAssertEqual(
            ExportBatchFileAccessSupport.availabilityMessage(for: withNote),
            ExportBatchFileAccessSupport.filesUnavailableMessage
        )
    }

    // MARK: - Regression

    func testPhase47FileAccessAndPhase44NotesAndPhase41Filters() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Reg48", photos: [])
        context.insert(project)

        let folder = "batch-phase48-reg"
        let folderURL = LocalEditStore.exportBatchFolderURL(folderName: folder)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        try LocalEditStore.saveExportBatchJPEG(makeImage(), folderName: folder, fileName: "02.jpg")
        try LocalEditStore.saveExportBatchJPEG(makeImage(), folderName: folder, fileName: "01.jpg")

        let batch = ProjectExportBatch(
            batchFolderName: folder,
            orderedFileNames: ["01.jpg", "02.jpg"],
            successCount: 2,
            project: project,
            marketplaceTargetRaw: "eBay",
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.fillCrop.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            sellerNote: "eBay draft"
        )
        context.insert(batch)

        XCTAssertEqual(
            ExportBatchFileAccessSupport.resolvedFiles(for: batch).map(\.fileName),
            ["01.jpg", "02.jpg"]
        )
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertTrue(batch.hasSellerNote)

        let all = ExportHistorySupport.completedBatches(in: project)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.ebay)).count, 1)
        batch.applyExportSettings(to: project)
        XCTAssertEqual(project.listingExportFitMode, .fillCrop)
    }

    func testSevenPresetsUnchangedLocalExportNoUpload() throws {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.etsyListing.rawValue, "Etsy listing")
        XCTAssertEqual(ListingExportPreset.instagramSquare.rawValue, "Instagram square")
        XCTAssertEqual(ListingExportPreset.facebookPost.rawValue, "Facebook post")
        XCTAssertEqual(ListingExportPreset.marketplace.rawValue, "Marketplace")
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.etsyListing.pixelSize, CGSize(width: 3000, height: 2400))
        XCTAssertEqual(ListingExportPreset.instagramSquare.pixelSize, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(ListingExportPreset.facebookPost.pixelSize, CGSize(width: 1200, height: 630))
        XCTAssertEqual(ListingExportPreset.marketplace.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))

        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Local48",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .facebookMarketplace
        project.listingExportPreset = .marketplace
        context.insert(project)
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)

        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
        XCTAssertFalse(batch.resultSummaryText.lowercased().contains("upload status"))
        XCTAssertTrue(LocalExportPostExportSupport.actions(for: batch).showViewExportedFiles)
    }
}
