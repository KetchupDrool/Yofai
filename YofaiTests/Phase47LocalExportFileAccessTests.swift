import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase47LocalExportFileAccessTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor = .gray) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40), format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
    }

    private func makeProject(in context: ModelContext) -> ItemProject {
        let project = ItemProject(name: "Phase47", photos: [])
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        project.listingExportFitMode = .fillCrop
        context.insert(project)
        return project
    }

    private func writeBatchFiles(folderName: String, names: [String]) throws {
        let folder = LocalEditStore.exportBatchFolderURL(folderName: folderName)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for name in names {
            try LocalEditStore.saveExportBatchJPEG(makeImage(), folderName: folderName, fileName: name)
        }
    }

    // MARK: - Exported file access

    func testResolvesExistingJPEGsInStoredOrder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = makeProject(in: context)
        let folder = "batch-phase47-order"
        let names = ["03.jpg", "01.jpg", "02.jpg"]
        try writeBatchFiles(folderName: folder, names: names)

        let batch = ProjectExportBatch(
            batchFolderName: folder,
            orderedFileNames: names,
            successCount: 3,
            project: project,
            marketplaceTargetRaw: "eBay",
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.fillCrop.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600
        )
        context.insert(batch)

        let resolved = ExportBatchFileAccessSupport.resolvedFiles(for: batch)
        XCTAssertEqual(resolved.map(\.fileName), names)
        XCTAssertTrue(resolved.allSatisfy(\.isAvailable))
        XCTAssertEqual(ExportBatchFileAccessSupport.shareableURLs(for: batch).map(\.lastPathComponent), names)
        XCTAssertEqual(ExportBatchFileAccessSupport.availability(for: batch), .available(count: 3))
        XCTAssertNil(ExportBatchFileAccessSupport.availabilityMessage(for: batch))
    }

    func testMissingBatchFolderHandledSafely() throws {
        let project = ItemProject(name: "MissingFolder", photos: [])
        let batch = ProjectExportBatch(
            batchFolderName: "batch-does-not-exist-\(UUID().uuidString)",
            orderedFileNames: ["01.jpg", "02.jpg"],
            successCount: 2,
            project: project
        )

        let resolved = ExportBatchFileAccessSupport.resolvedFiles(for: batch)
        XCTAssertEqual(resolved.count, 2)
        XCTAssertTrue(resolved.allSatisfy { !$0.isAvailable })
        XCTAssertTrue(ExportBatchFileAccessSupport.shareableURLs(for: batch).isEmpty)
        XCTAssertFalse(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertEqual(
            ExportBatchFileAccessSupport.availabilityMessage(for: batch),
            ExportBatchFileAccessSupport.filesUnavailableMessage
        )
        XCTAssertEqual(ExportBatchFileAccessSupport.availability(for: batch), .unavailable)
    }

    func testMissingIndividualJPEGHandledSafely() throws {
        let folder = "batch-phase47-partial"
        try writeBatchFiles(folderName: folder, names: ["01.jpg", "03.jpg"])

        let batch = ProjectExportBatch(
            batchFolderName: folder,
            orderedFileNames: ["01.jpg", "02.jpg", "03.jpg"],
            successCount: 3
        )

        let resolved = ExportBatchFileAccessSupport.resolvedFiles(for: batch)
        XCTAssertEqual(resolved.map(\.fileName), ["01.jpg", "02.jpg", "03.jpg"])
        XCTAssertTrue(resolved[0].isAvailable)
        XCTAssertFalse(resolved[1].isAvailable)
        XCTAssertTrue(resolved[2].isAvailable)
        XCTAssertEqual(ExportBatchFileAccessSupport.shareableURLs(for: batch).count, 2)
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertEqual(
            ExportBatchFileAccessSupport.availability(for: batch),
            .partial(available: 2, expected: 3)
        )
        XCTAssertNil(ExportBatchFileAccessSupport.availabilityMessage(for: batch))
    }

    func testLegacyRowWithoutFileNamesHandledSafely() {
        let batch = ProjectExportBatch(
            batchFolderName: "legacy-empty-names",
            orderedFileNames: [],
            successCount: 2
        )

        XCTAssertTrue(ExportBatchFileAccessSupport.resolvedFiles(for: batch).isEmpty)
        XCTAssertEqual(ExportBatchFileAccessSupport.availability(for: batch), .noRecordedFiles)
        XCTAssertFalse(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertEqual(
            ExportBatchFileAccessSupport.availabilityMessage(for: batch),
            ExportBatchFileAccessSupport.filesUnavailableMessage
        )
    }

    func testZeroAvailableFilesHandledSafely() throws {
        let folder = "batch-phase47-empty"
        let folderURL = LocalEditStore.exportBatchFolderURL(folderName: folder)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let batch = ProjectExportBatch(
            batchFolderName: folder,
            orderedFileNames: ["01.jpg"],
            successCount: 1
        )

        XCTAssertEqual(ExportBatchFileAccessSupport.availability(for: batch), .unavailable)
        XCTAssertFalse(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertEqual(
            ExportBatchFileAccessSupport.availabilityMessage(for: batch),
            ExportBatchFileAccessSupport.filesUnavailableMessage
        )
    }

    // MARK: - Re-share

    func testReshareUsesExistingFilesWithoutNewHistoryOrMutation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage(color: .red))
        let project = ItemProject(
            name: "Reshare",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        project.listingExportFitMode = .containPad
        project.listingWatermarkEnabled = true
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        batch.setSellerNote("keep note")
        context.insert(batch)
        try context.save()

        let historyCountBefore = ExportHistorySupport.completedBatches(in: project).count
        let urls = ExportBatchFileAccessSupport.shareableURLs(for: batch)
        XCTAssertFalse(urls.isEmpty)
        let dataBefore = try Data(contentsOf: urls[0])
        let settingsBefore = (
            project.listingMarketplaceTarget,
            project.listingExportPreset,
            project.listingExportFitMode,
            project.listingWatermarkEnabled,
            batch.sellerNote
        )

        let caption = LocalExportShareSupport.shareCaption(for: batch, includeNote: true)
        let item = ShareBatchItem(urls: urls, caption: caption)
        XCTAssertEqual(item.urls, urls)

        XCTAssertEqual(ExportHistorySupport.completedBatches(in: project).count, historyCountBefore)
        XCTAssertEqual(project.listingMarketplaceTarget, settingsBefore.0)
        XCTAssertEqual(project.listingExportPreset, settingsBefore.1)
        XCTAssertEqual(project.listingExportFitMode, settingsBefore.2)
        XCTAssertEqual(project.listingWatermarkEnabled, settingsBefore.3)
        XCTAssertEqual(batch.sellerNote, settingsBefore.4)
        XCTAssertEqual(try Data(contentsOf: urls[0]), dataBefore)
    }

    func testNoteShareActionsOnlyWhenNoteExists() {
        let withNote = ProjectExportBatch(
            batchFolderName: "n1",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            sellerNote: "eBay draft"
        )
        let withoutNote = ProjectExportBatch(
            batchFolderName: "n2",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            sellerNote: ""
        )

        XCTAssertTrue(ExportBatchFileAccessSupport.canOfferShareWithNote(withNote))
        XCTAssertTrue(ExportBatchFileAccessSupport.canOfferCopyNote(withNote))
        XCTAssertFalse(ExportBatchFileAccessSupport.canOfferShareWithNote(withoutNote))
        XCTAssertFalse(ExportBatchFileAccessSupport.canOfferCopyNote(withoutNote))
    }

    // MARK: - Deletion

    func testDeletingHistoryRemovesOnlyExportBatchFolder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let photoFile = try LocalEditStore.saveProjectImage(makeImage(color: .blue))
        let project = ItemProject(
            name: "DeleteSafe",
            photos: [ItemProjectPhoto(localFileName: photoFile, sortOrder: 0)]
        )
        context.insert(project)

        let folder = "batch-phase47-delete"
        try writeBatchFiles(folderName: folder, names: ["01.jpg"])
        let batch = ProjectExportBatch(
            batchFolderName: folder,
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project
        )
        context.insert(batch)
        try context.save()

        let exportURL = LocalEditStore.exportBatchFileURL(folderName: folder, fileName: "01.jpg")
        XCTAssertNotNil(exportURL)
        let projectPhotoURL = LocalEditStore.projectFileURL(for: photoFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectPhotoURL.path))

        LocalEditStore.deleteExportBatchFolder(folderName: batch.batchFolderName)
        context.delete(batch)
        try context.save()

        XCTAssertNil(LocalEditStore.exportBatchFileURL(folderName: folder, fileName: "01.jpg"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: LocalEditStore.exportBatchFolderURL(folderName: folder).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectPhotoURL.path))
        XCTAssertEqual(project.photos.count, 1)
    }

    // MARK: - Regression

    func testPhase46WordingAndPhase44NotesAndPhase41Filters() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = makeProject(in: context)
        let batch = ProjectExportBatch(
            batchFolderName: "reg47",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: "eBay",
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.fillCrop.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            sellerNote: "eBay draft"
        )
        context.insert(batch)

        let summary = LocalExportShareSupport.resultSummaryText(for: batch)
        XCTAssertTrue(summary.contains("local JPEG"))
        XCTAssertTrue(summary.contains("Manual upload"))
        XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(summary))
        XCTAssertEqual(LocalExportShareSupport.viewExportedFilesTitle, "View Exported Files")
        XCTAssertTrue(batch.hasSellerNote)

        let all = ExportHistorySupport.completedBatches(in: project)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.ebay)).count, 1)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.etsy)).count, 0)

        batch.applyExportSettings(to: project)
        XCTAssertEqual(project.listingMarketplaceTarget, .ebay)
        XCTAssertEqual(project.listingExportPreset, .ebay)
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
            name: "Local",
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
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
    }
}
