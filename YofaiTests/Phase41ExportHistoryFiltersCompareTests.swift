import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase41ExportHistoryFiltersCompareTests: XCTestCase {
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
        let project = ItemProject(name: "Phase41", photos: [photo])
        context.insert(project)
        return project
    }

    private func insertBatch(
        project: ItemProject,
        marketplace: String,
        preset: ListingExportPreset,
        fit: ListingExportFitMode,
        photos: Int,
        watermark: Bool,
        createdAt: Date,
        folder: String
    ) -> ProjectExportBatch {
        ProjectExportBatch(
            createdAt: createdAt,
            batchFolderName: folder,
            orderedFileNames: (0..<photos).map { String(format: "%02d.jpg", $0 + 1) },
            successCount: photos,
            project: project,
            marketplaceTargetRaw: marketplace,
            exportPresetRaw: preset.rawValue,
            exportFitModeRaw: fit.rawValue,
            exportCanvasWidth: Int(preset.pixelSize.width),
            exportCanvasHeight: Int(preset.pixelSize.height),
            watermarkEnabled: watermark
        )
    }

    // MARK: - Filters

    func testAllFilterReturnsEveryRowNewestFirst() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let older = insertBatch(
            project: project, marketplace: "Etsy", preset: .etsySquare, fit: .containPad,
            photos: 1, watermark: false, createdAt: Date(timeIntervalSince1970: 1000), folder: "a"
        )
        let newer = insertBatch(
            project: project, marketplace: "eBay", preset: .ebay, fit: .fillCrop,
            photos: 1, watermark: false, createdAt: Date(timeIntervalSince1970: 2000), folder: "b"
        )
        context.insert(older)
        context.insert(newer)

        let all = ExportHistorySupport.completedBatches(in: project)
        let filtered = ExportHistorySupport.filtered(all, by: .all)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered[0].marketplaceTargetRaw, "eBay")
        XCTAssertEqual(filtered[1].marketplaceTargetRaw, "Etsy")
    }

    func testEtsyAndEbayFilters() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        context.insert(insertBatch(
            project: project, marketplace: "Etsy", preset: .etsySquare, fit: .containPad,
            photos: 2, watermark: false, createdAt: .now, folder: "etsy"
        ))
        context.insert(insertBatch(
            project: project, marketplace: "eBay", preset: .ebay, fit: .containPad,
            photos: 2, watermark: false, createdAt: .now.addingTimeInterval(-10), folder: "ebay"
        ))

        let all = ExportHistorySupport.completedBatches(in: project)
        let etsy = ExportHistorySupport.filtered(all, by: .marketplace(.etsy))
        let ebay = ExportHistorySupport.filtered(all, by: .marketplace(.ebay))
        XCTAssertEqual(etsy.map(\.marketplaceTargetRaw), ["Etsy"])
        XCTAssertEqual(ebay.map(\.marketplaceTargetRaw), ["eBay"])
    }

    func testFacebookAndMercariFiltersUseStoredTargetNotCanvas() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        context.insert(insertBatch(
            project: project, marketplace: "Facebook Marketplace", preset: .marketplace, fit: .containPad,
            photos: 1, watermark: false, createdAt: .now, folder: "fb"
        ))
        context.insert(insertBatch(
            project: project, marketplace: "Mercari", preset: .instagramSquare, fit: .fillCrop,
            photos: 1, watermark: false, createdAt: .now.addingTimeInterval(-5), folder: "merc"
        ))
        // Same canvas as FB row but eBay target — must not appear in FB filter.
        context.insert(insertBatch(
            project: project, marketplace: "eBay", preset: .marketplace, fit: .containPad,
            photos: 1, watermark: false, createdAt: .now.addingTimeInterval(-20), folder: "ebay1600"
        ))

        let all = ExportHistorySupport.completedBatches(in: project)
        let fb = ExportHistorySupport.filtered(all, by: .marketplace(.facebookMarketplace))
        let mercari = ExportHistorySupport.filtered(all, by: .marketplace(.mercari))
        XCTAssertEqual(fb.count, 1)
        XCTAssertEqual(fb[0].marketplaceTargetRaw, "Facebook Marketplace")
        XCTAssertEqual(fb[0].pixelSizeLabel, "1600×1600")
        XCTAssertEqual(mercari.count, 1)
        XCTAssertEqual(mercari[0].marketplaceTargetRaw, "Mercari")
        XCTAssertEqual(mercari[0].pixelSizeLabel, "1080×1080")
    }

    func testLegacyRowsNotInferredAsNamedMarketplaces() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let legacy = ProjectExportBatch(
            createdAt: .now,
            batchFolderName: "legacy",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: "",
            exportPresetRaw: "eBay",
            exportFitModeRaw: "Contain + Pad",
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            watermarkEnabled: false
        )
        context.insert(legacy)
        context.insert(insertBatch(
            project: project, marketplace: "eBay", preset: .ebay, fit: .containPad,
            photos: 1, watermark: false, createdAt: .now.addingTimeInterval(-1), folder: "real-ebay"
        ))

        let all = ExportHistorySupport.completedBatches(in: project)
        let ebay = ExportHistorySupport.filtered(all, by: .marketplace(.ebay))
        let earlier = ExportHistorySupport.filtered(all, by: .earlierExport)
        XCTAssertEqual(ebay.count, 1)
        XCTAssertEqual(ebay[0].marketplaceTargetRaw, "eBay")
        XCTAssertEqual(earlier.count, 1)
        XCTAssertTrue(earlier[0].marketplaceTargetRaw.isEmpty)
        XCTAssertTrue(earlier[0].historyPrimaryLine.contains("Earlier export"))
    }

    func testEmptyFilterResultMessageAndAvailableFilters() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        context.insert(insertBatch(
            project: project, marketplace: "Etsy", preset: .etsySquare, fit: .containPad,
            photos: 1, watermark: false, createdAt: .now, folder: "only-etsy"
        ))
        let all = ExportHistorySupport.completedBatches(in: project)
        let posh = ExportHistorySupport.filtered(all, by: .marketplace(.poshmark))
        XCTAssertTrue(posh.isEmpty)
        XCTAssertEqual(ExportHistoryFilter.marketplace(.poshmark).emptyStateMessage, "No Poshmark exports yet.")

        let available = ExportHistorySupport.availableFilters(for: all)
        XCTAssertEqual(available.first, .all)
        XCTAssertTrue(available.contains(.marketplace(.etsy)))
        XCTAssertFalse(available.contains(.marketplace(.ebay)))
    }

    // MARK: - Comparison

    func testCompareNewestTwoReportsChangedFieldsOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        let previous = insertBatch(
            project: project, marketplace: "eBay", preset: .ebay, fit: .fillCrop,
            photos: 6, watermark: true, createdAt: Date(timeIntervalSince1970: 1000), folder: "prev"
        )
        let newest = insertBatch(
            project: project, marketplace: "Etsy", preset: .etsySquare, fit: .containPad,
            photos: 4, watermark: false, createdAt: Date(timeIntervalSince1970: 2000), folder: "new"
        )
        context.insert(previous)
        context.insert(newest)

        let comparison = ExportHistorySupport.compareNewestTwo(
            ExportHistorySupport.completedBatches(in: project)
        )
        XCTAssertTrue(comparison.hasPrevious)
        XCTAssertTrue(comparison.lines.contains("eBay → Etsy"))
        XCTAssertTrue(comparison.lines.contains("1600×1600 → 2000×2000"))
        XCTAssertTrue(comparison.lines.contains("Fill + Crop → Contain + Pad"))
        XCTAssertTrue(comparison.lines.contains("6 photos → 4 photos"))
        XCTAssertTrue(comparison.lines.contains("Watermark on → Watermark off"))
        XCTAssertTrue(comparison.summaryText.contains("Compared with previous export"))
        XCTAssertFalse(comparison.summaryText.lowercased().contains("compliance"))
        XCTAssertFalse(comparison.summaryText.lowercased().contains("quality"))
    }

    func testCompareOmitsUnchangedFields() throws {
        let previous = ProjectExportBatch(
            createdAt: Date(timeIntervalSince1970: 1),
            batchFolderName: "p",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            marketplaceTargetRaw: "Etsy",
            exportPresetRaw: ListingExportPreset.etsySquare.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 2000,
            exportCanvasHeight: 2000,
            watermarkEnabled: false
        )
        let newest = ProjectExportBatch(
            createdAt: Date(timeIntervalSince1970: 2),
            batchFolderName: "n",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            marketplaceTargetRaw: "Etsy",
            exportPresetRaw: ListingExportPreset.etsySquare.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 2000,
            exportCanvasHeight: 2000,
            watermarkEnabled: false
        )
        let lines = ExportHistorySupport.differenceLines(from: previous, to: newest)
        XCTAssertFalse(lines.contains { $0.contains("Etsy → Etsy") })
        XCTAssertFalse(lines.contains { $0.contains("2000×2000 → 2000×2000") })
        XCTAssertFalse(lines.contains { $0.contains("Contain + Pad → Contain + Pad") })
        // Date still differs.
        XCTAssertTrue(lines.contains { $0.contains("→") })
    }

    func testOneExportComparisonHandled() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        context.insert(insertBatch(
            project: project, marketplace: "Etsy", preset: .etsySquare, fit: .containPad,
            photos: 1, watermark: false, createdAt: .now, folder: "one"
        ))
        let comparison = ExportHistorySupport.compareNewestTwo(
            ExportHistorySupport.completedBatches(in: project)
        )
        XCTAssertFalse(comparison.hasPrevious)
        XCTAssertEqual(comparison.summaryText, "No previous export to compare.")
        XCTAssertTrue(comparison.lines.isEmpty)
    }

    func testLegacyMetadataCompareSafe() throws {
        let legacy = ProjectExportBatch(
            createdAt: Date(timeIntervalSince1970: 1),
            batchFolderName: "legacy",
            orderedFileNames: ["01.jpg"],
            successCount: 1
        )
        let newest = ProjectExportBatch(
            createdAt: Date(timeIntervalSince1970: 2),
            batchFolderName: "new",
            orderedFileNames: ["01.jpg"],
            successCount: 2,
            marketplaceTargetRaw: "Poshmark",
            exportPresetRaw: ListingExportPreset.poshmark.rawValue,
            exportFitModeRaw: ListingExportFitMode.fillCrop.rawValue,
            exportCanvasWidth: 1000,
            exportCanvasHeight: 1000,
            watermarkEnabled: false
        )
        let lines = ExportHistorySupport.differenceLines(from: legacy, to: newest)
        XCTAssertTrue(lines.contains("Earlier export → Poshmark"))
        XCTAssertTrue(lines.contains { $0.contains("1000×1000") })
    }

    // MARK: - Quick actions / regression

    func testExportAgainRestoresExportSettingsOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        var state = PhotoEditState()
        state.quarterTurns = 2
        state.filter = .mono
        state.brightness = -0.1
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: -0.5, y: 0.25)
        project.sortedPhotos[0].savedEditState = state

        let batch = insertBatch(
            project: project, marketplace: "Poshmark", preset: .poshmark, fit: .fillCrop,
            photos: 1, watermark: true, createdAt: .now, folder: "again"
        )
        context.insert(batch)

        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        project.listingWatermarkEnabled = false

        batch.applyExportSettings(to: project)

        XCTAssertEqual(project.listingMarketplaceTarget, .poshmark)
        XCTAssertEqual(project.listingExportPreset, .poshmark)
        XCTAssertEqual(project.listingExportFitMode, .fillCrop)
        XCTAssertTrue(project.listingWatermarkEnabled)

        let photo = project.sortedPhotos[0].savedEditState
        XCTAssertEqual(photo?.quarterTurns, 2)
        XCTAssertEqual(photo?.filter, .mono)
        XCTAssertEqual(photo?.brightness ?? 0, -0.1, accuracy: 0.0001)
        XCTAssertEqual(photo?.fillCropOffsetX ?? 0, -0.5, accuracy: 0.0001)
        XCTAssertEqual(photo?.fillCropOffsetY ?? 0, 0.25, accuracy: 0.0001)
    }

    func testPhase40HistoryAndFailedExportRegression() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)
        XCTAssertNotNil(batch)
        context.insert(batch!)
        XCTAssertEqual(project.sortedCompletedExportBatches.count, 1)

        let empty = ProjectBatchExportResult(
            batchFolderName: "fail",
            orderedFileNames: [],
            successCount: 0,
            errorMessages: ["none"]
        )
        XCTAssertNil(ProjectExportBatch.recordSuccessfulExport(from: empty, project: project))
    }

    func testSevenPresetsUnchangedAndFitModesIntact() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertEqual(ListingExportFitMode.containPad.rawValue, "Contain + Pad")
        XCTAssertEqual(ListingExportFitMode.fillCrop.rawValue, "Fill + Crop")
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
    }

    func testMarketplaceTargetRemainsSeparateFromCanvas() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(in: context)
        MarketplaceExportSupport.switchTarget(
            on: project,
            to: .facebookMarketplace,
            applyRecommendedCanvas: true
        )
        XCTAssertEqual(project.listingMarketplaceTarget, .facebookMarketplace)
        // No recommended canvas — preset unchanged from default etsy square unless seller picks one.
        XCTAssertEqual(project.listingExportPreset, .etsySquare)
    }
}
