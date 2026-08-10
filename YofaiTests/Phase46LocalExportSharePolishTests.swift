import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase46LocalExportSharePolishTests: XCTestCase {
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

    private func insertBatch(
        project: ItemProject,
        note: String = "",
        marketplace: String = "eBay",
        successCount: Int = 6,
        fit: ListingExportFitMode = .fillCrop,
        watermark: Bool = false,
        folder: String = "phase46"
    ) -> ProjectExportBatch {
        ProjectExportBatch(
            createdAt: Date(),
            batchFolderName: folder,
            orderedFileNames: (1...successCount).map { String(format: "%02d.jpg", $0) },
            successCount: successCount,
            project: project,
            marketplaceTargetRaw: marketplace,
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: fit.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            watermarkEnabled: watermark,
            sellerNote: note
        )
    }

    // MARK: - Share / package labels

    func testResultSummaryUsesLocalJPEGWording() {
        let project = ItemProject(name: "Sum", photos: [])
        let batch = insertBatch(project: project, note: "eBay draft", successCount: 6)
        let text = LocalExportShareSupport.resultSummaryText(for: batch)

        XCTAssertTrue(text.contains("local JPEG"))
        XCTAssertTrue(text.contains("For eBay"))
        XCTAssertTrue(text.contains("1600×1600"))
        XCTAssertTrue(text.contains("Fill + Crop"))
        XCTAssertTrue(text.contains("Manual upload"))
        XCTAssertTrue(text.contains("Note: eBay draft"))
        XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text))
        XCTAssertFalse(text.lowercased().contains("published"))
        XCTAssertFalse(text.lowercased().contains("direct upload"))
    }

    func testHistoryExportedForNotPublished() {
        let project = ItemProject(name: "Hist", photos: [])
        let batch = insertBatch(project: project, note: "eBay draft")

        XCTAssertEqual(batch.exportedForLine, "Exported for eBay")
        XCTAssertFalse(batch.exportedForLine.lowercased().contains("published"))
        XCTAssertEqual(batch.historyPrimaryLine, "eBay • 1600×1600 • 6 photos")
        XCTAssertTrue(batch.historySecondaryLine.contains("Local JPEGs"))
        XCTAssertEqual(batch.historyNoteLine, "Note: eBay draft")
        XCTAssertTrue(LocalExportShareSupport.packageSummaryLine(for: batch).contains("Local JPEGs"))
    }

    func testShareActionTitlesAreLocalOnly() {
        XCTAssertEqual(LocalExportShareSupport.shareExportedPhotosTitle, "Share Exported Photos")
        XCTAssertEqual(LocalExportShareSupport.shareWithNoteTitle, "Share with Note")
        XCTAssertEqual(LocalExportShareSupport.copyExportNoteTitle, "Copy Export Note")
        for title in [
            LocalExportShareSupport.shareExportedPhotosTitle,
            LocalExportShareSupport.shareWithNoteTitle,
            LocalExportShareSupport.copyExportNoteTitle,
            LocalExportShareSupport.manualUploadLabel,
            LocalExportShareSupport.localJPEGsLabel
        ] {
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(title))
            XCTAssertFalse(title.lowercased().contains("publish"))
            XCTAssertFalse(title.lowercased().contains("direct upload"))
        }
    }

    // MARK: - Export note share / copy

    func testShareCaptionOptionalOffByDefaultAndBlankProducesNil() {
        let project = ItemProject(name: "Cap", photos: [])
        let withNote = insertBatch(project: project, note: "eBay draft", folder: "a")
        let blank = insertBatch(project: project, note: "   ", folder: "b")

        XCTAssertNil(LocalExportShareSupport.shareCaption(for: withNote, includeNote: false))
        XCTAssertEqual(
            LocalExportShareSupport.shareCaption(for: withNote, includeNote: true),
            "Exported for eBay — eBay draft"
        )
        XCTAssertNil(LocalExportShareSupport.shareCaption(for: blank, includeNote: true))
        XCTAssertNil(LocalExportShareSupport.copyableNoteText(for: blank))
        XCTAssertEqual(LocalExportShareSupport.copyableNoteText(for: withNote), "eBay draft")
    }

    func testShareBatchItemCaptionDoesNotMutateFilesOrSettings() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Share",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        project.listingExportFitMode = .fillCrop
        project.listingWatermarkEnabled = false
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)
        batch.setSellerNote("reference only")
        try context.save()

        let urlsBefore = batch.fileURLs
        XCTAssertFalse(urlsBefore.isEmpty)
        let dataBefore = try Data(contentsOf: urlsBefore[0])
        let settingsBefore = (
            project.listingMarketplaceTarget,
            project.listingExportPreset,
            project.listingExportFitMode,
            project.listingWatermarkEnabled,
            batch.sellerNote
        )

        let caption = LocalExportShareSupport.shareCaption(for: batch, includeNote: true)
        let item = ShareBatchItem(urls: urlsBefore, caption: caption)
        XCTAssertEqual(item.activityItems.count, urlsBefore.count + 1)
        XCTAssertEqual(item.activityItems.first as? String, caption)
        XCTAssertEqual(LocalExportShareSupport.copyableNoteText(for: batch), "reference only")

        let dataAfter = try Data(contentsOf: urlsBefore[0])
        XCTAssertEqual(dataBefore, dataAfter)
        XCTAssertEqual(project.listingMarketplaceTarget, settingsBefore.0)
        XCTAssertEqual(project.listingExportPreset, settingsBefore.1)
        XCTAssertEqual(project.listingExportFitMode, settingsBefore.2)
        XCTAssertEqual(project.listingWatermarkEnabled, settingsBefore.3)
        XCTAssertEqual(batch.sellerNote, settingsBefore.4)
    }

    func testLongNoteRemainsCappedByPhase44() {
        let long = String(repeating: "a", count: 500)
        let normalized = ExportBatchNoteSupport.normalized(long)
        XCTAssertEqual(normalized.count, ExportBatchNoteSupport.maxLength)
        XCTAssertEqual(ExportBatchNoteSupport.maxLength, 240)

        let project = ItemProject(name: "Long", photos: [])
        let batch = insertBatch(project: project)
        batch.setSellerNote(long)
        XCTAssertEqual(batch.sellerNote.count, 240)
        let caption = LocalExportShareSupport.shareCaption(for: batch, includeNote: true)!
        XCTAssertTrue(caption.hasSuffix(batch.sellerNote))
    }

    // MARK: - Regression

    func testPhase44NotesPersistAndPhase41FiltersUnchanged() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Reg", photos: [])
        context.insert(project)
        let ebay = insertBatch(project: project, note: "eBay draft", marketplace: "eBay", folder: "e1")
        let etsy = insertBatch(
            project: project,
            note: "",
            marketplace: "Etsy",
            successCount: 2,
            folder: "e2"
        )
        etsy.exportPresetRaw = ListingExportPreset.etsySquare.rawValue
        etsy.exportCanvasWidth = 2000
        etsy.exportCanvasHeight = 2000
        context.insert(ebay)
        context.insert(etsy)
        try context.save()

        XCTAssertTrue(ebay.hasSellerNote)
        let all = ExportHistorySupport.completedBatches(in: project)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.ebay)).count, 1)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.etsy)).count, 1)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .all).count, 2)

        ebay.applyExportSettings(to: project)
        XCTAssertEqual(project.listingMarketplaceTarget, .ebay)
        XCTAssertEqual(project.listingExportPreset, .ebay)
        XCTAssertEqual(project.listingExportFitMode, .fillCrop)
    }

    func testSevenPresetsUnchangedTargetSeparateLocalExportNoUploadStatus() throws {
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
        XCTAssertFalse(batch.resultSummaryText.lowercased().contains("upload status"))
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
        XCTAssertTrue(batch.resultSummaryText.contains("local JPEG"))
        XCTAssertTrue(batch.exportedForLine.contains("Exported for"))
    }
}
