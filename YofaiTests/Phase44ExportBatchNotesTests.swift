import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase44ExportBatchNotesTests: XCTestCase {
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

    private func makeProject(in context: ModelContext) throws -> ItemProject {
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Phase44", photos: [photo])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        context.insert(project)
        return project
    }

    private func insertBatch(
        project: ItemProject,
        note: String = "",
        marketplace: String = "eBay",
        folder: String = "batch"
    ) -> ProjectExportBatch {
        ProjectExportBatch(
            createdAt: Date(),
            batchFolderName: folder,
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: marketplace,
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            watermarkEnabled: false,
            sellerNote: note
        )
    }

    // MARK: - Persistence

    func testLegacyBatchWithoutNoteLoadsEmpty() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let legacy = ProjectExportBatch(
            batchFolderName: "legacy",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project
        )
        context.insert(legacy)
        try context.save()

        XCTAssertEqual(legacy.sellerNote, "")
        XCTAssertFalse(legacy.hasSellerNote)
        XCTAssertNil(legacy.sellerNoteDisplayLine)
    }

    func testNewBatchDefaultsToNoNote() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)

        XCTAssertEqual(batch.sellerNote, "")
        XCTAssertFalse(batch.hasSellerNote)
    }

    func testNoteSavesReloadsAndEdits() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let batch = insertBatch(project: project)
        context.insert(batch)
        batch.setSellerNote("eBay draft")
        try context.save()

        let id = batch.persistentModelID
        let reload = ModelContext(container)
        let loaded = reload.model(for: id) as! ProjectExportBatch
        XCTAssertEqual(loaded.sellerNote, "eBay draft")
        XCTAssertTrue(loaded.hasSellerNote)

        loaded.setSellerNote("Second version with tighter crop")
        try reload.save()
        let reload2 = ModelContext(container)
        let loaded2 = reload2.model(for: id) as! ProjectExportBatch
        XCTAssertEqual(loaded2.sellerNote, "Second version with tighter crop")
    }

    func testClearingAndWhitespaceBecomeEmpty() {
        XCTAssertEqual(ExportBatchNoteSupport.normalized("   \n\t  "), "")
        XCTAssertEqual(ExportBatchNoteSupport.normalized("  hello  "), "hello")
        XCTAssertFalse(ExportBatchNoteSupport.hasNote("   "))

        let batch = ProjectExportBatch(batchFolderName: "n", successCount: 1, sellerNote: "keep")
        batch.setSellerNote("   ")
        XCTAssertEqual(batch.sellerNote, "")
        XCTAssertFalse(batch.hasSellerNote)
        XCTAssertNil(batch.sellerNoteDisplayLine)
    }

    func testLengthLimitEnforced() {
        let long = String(repeating: "a", count: ExportBatchNoteSupport.maxLength + 40)
        let normalized = ExportBatchNoteSupport.normalized(long)
        XCTAssertEqual(normalized.count, ExportBatchNoteSupport.maxLength)

        let batch = ProjectExportBatch(batchFolderName: "len", successCount: 1)
        batch.setSellerNote(long)
        XCTAssertEqual(batch.sellerNote.count, ExportBatchNoteSupport.maxLength)
    }

    // MARK: - Isolation

    func testEditingNoteDoesNotChangeExportMetadataOrOffsets() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        project.listingExportFitMode = .fillCrop
        var state = PhotoEditState()
        state.setFillCropOffsets(x: 0.4, y: -0.2)
        project.sortedPhotos[0].savedEditState = state

        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let batch = ProjectExportBatch(
            createdAt: created,
            batchFolderName: "iso",
            orderedFileNames: ["01.jpg", "02.jpg"],
            successCount: 2,
            project: project,
            marketplaceTargetRaw: "Etsy",
            exportPresetRaw: ListingExportPreset.etsySquare.rawValue,
            exportFitModeRaw: ListingExportFitMode.fillCrop.rawValue,
            exportCanvasWidth: 2000,
            exportCanvasHeight: 2000,
            watermarkEnabled: true
        )
        context.insert(batch)

        batch.setSellerNote("Client approved photos")

        XCTAssertEqual(batch.marketplaceTargetRaw, "Etsy")
        XCTAssertEqual(batch.exportPresetRaw, "Etsy square")
        XCTAssertEqual(batch.exportCanvasWidth, 2000)
        XCTAssertEqual(batch.exportCanvasHeight, 2000)
        XCTAssertEqual(batch.exportFitModeRaw, ListingExportFitMode.fillCrop.rawValue)
        XCTAssertTrue(batch.watermarkEnabled)
        XCTAssertEqual(batch.successCount, 2)
        XCTAssertEqual(batch.createdAt, created)
        XCTAssertEqual(project.sortedPhotos[0].savedEditState?.fillCropOffsetX ?? 0, 0.4, accuracy: 0.0001)
        XCTAssertEqual(project.sortedPhotos[0].savedEditState?.fillCropOffsetY ?? 0, -0.2, accuracy: 0.0001)
    }

    // MARK: - History

    func testNoteDisplayOnlyWhenPresentAndFiltersUnchanged() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let withNote = insertBatch(project: project, note: "Holiday listing", marketplace: "Etsy", folder: "a")
        let without = insertBatch(project: project, note: "", marketplace: "eBay", folder: "b")
        context.insert(withNote)
        context.insert(without)

        XCTAssertEqual(withNote.sellerNoteDisplayLine, "Holiday listing")
        XCTAssertNil(without.sellerNoteDisplayLine)

        let all = ExportHistorySupport.completedBatches(in: project)
        let etsy = ExportHistorySupport.filtered(all, by: .marketplace(.etsy))
        XCTAssertEqual(etsy.count, 1)
        XCTAssertEqual(etsy[0].marketplaceTargetRaw, "Etsy")
        // Filtering is marketplace-based only — note text does not affect it.
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.ebay)).count, 1)
    }

    func testUseTheseSettingsAndExportAgainIgnoreNote() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        project.listingMarketplaceTarget = .other
        project.listingExportPreset = .instagramSquare
        project.listingExportFitMode = .containPad
        project.listingWatermarkEnabled = false

        let batch = insertBatch(project: project, note: "Retook main image", marketplace: "Poshmark")
        batch.exportPresetRaw = ListingExportPreset.poshmark.rawValue
        batch.exportFitModeRaw = ListingExportFitMode.fillCrop.rawValue
        batch.exportCanvasWidth = 1000
        batch.exportCanvasHeight = 1000
        batch.watermarkEnabled = true
        context.insert(batch)

        batch.applyExportSettings(to: project)
        XCTAssertEqual(project.listingMarketplaceTarget, .poshmark)
        XCTAssertEqual(project.listingExportPreset, .poshmark)
        XCTAssertEqual(project.listingExportFitMode, .fillCrop)
        XCTAssertTrue(project.listingWatermarkEnabled)
        XCTAssertEqual(batch.sellerNote, "Retook main image")
    }

    func testDeleteRemovesBatchAndNoteTogether() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let batch = insertBatch(project: project, note: "gone soon", folder: "del-note")
        context.insert(batch)
        try context.save()

        LocalEditStore.deleteExportBatchFolder(folderName: batch.batchFolderName)
        context.delete(batch)
        project.touchModified()
        try context.save()

        XCTAssertTrue(project.sortedCompletedExportBatches.isEmpty)
        XCTAssertEqual(project.sortedPhotos.count, 1)
    }

    // MARK: - Regression

    func testExportDoesNotRequireNote() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertGreaterThan(result.successCount, 0)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)
        XCTAssertNotNil(batch)
        XCTAssertEqual(batch?.sellerNote, "")
    }

    func testPhase42And43UnchangedAndPresetsIntact() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let readiness = ExportReadiness.summary(for: project)
        XCTAssertEqual(readiness.items.count, 6)
        _ = ExportPrepTipSupport.tips(for: project)

        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportFitMode.containPad.displayTitle, "Contain + Pad")
        XCTAssertEqual(ListingExportFitMode.fillCrop.displayTitle, "Fill + Crop")

        let compare = ExportHistorySupport.compareNewestTwo([])
        XCTAssertFalse(compare.hasPrevious)
    }

    func testCompareDoesNotIncludeNotes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let older = ProjectExportBatch(
            createdAt: Date(timeIntervalSince1970: 1),
            batchFolderName: "old",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: "Etsy",
            exportPresetRaw: ListingExportPreset.etsySquare.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 2000,
            exportCanvasHeight: 2000,
            sellerNote: "first note"
        )
        let newer = ProjectExportBatch(
            createdAt: Date(timeIntervalSince1970: 2),
            batchFolderName: "new",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: "Etsy",
            exportPresetRaw: ListingExportPreset.etsySquare.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 2000,
            exportCanvasHeight: 2000,
            sellerNote: "second note"
        )
        context.insert(older)
        context.insert(newer)

        let lines = ExportHistorySupport.differenceLines(from: older, to: newer)
        XCTAssertFalse(lines.contains { $0.lowercased().contains("note") })
        XCTAssertFalse(lines.contains { $0.contains("first note") })
    }
}
