import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase42ExportReadinessChecklistTests: XCTestCase {
    private let solidRed = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    private let solidBlue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeSolidImage(color: UIColor, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeReadyProject(
        in context: ModelContext,
        imageSize: CGSize = CGSize(width: 2000, height: 2000),
        photoCount: Int = 1
    ) throws -> ItemProject {
        var photos: [ItemProjectPhoto] = []
        for index in 0..<photoCount {
            let file = try LocalEditStore.saveProjectImage(makeSolidImage(color: solidRed, size: imageSize))
            photos.append(ItemProjectPhoto(localFileName: file, sortOrder: index))
        }
        let project = ItemProject(name: "Phase42", photos: photos)
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        project.listingExportFitMode = .containPad
        project.listingWatermarkEnabled = false
        context.insert(project)
        return project
    }

    private func item(_ summary: ExportReadinessSummary, _ id: ExportReadinessRowID) -> ExportReadinessItem {
        guard let row = summary.items.first(where: { $0.id == id }) else {
            XCTFail("Missing checklist row \(id)")
            return ExportReadinessItem(id: id, title: "", level: .ready, fact: "")
        }
        return row
    }

    // MARK: - Overall status

    func testNoPhotosNeedsAttention() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Empty", photos: [])
        context.insert(project)

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .needsAttention)
        XCTAssertEqual(summary.overallHeadline, "Needs attention")
        XCTAssertEqual(item(summary, .photos).level, .needsAttention)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("no photos") })
    }

    func testValidBasicProjectReady() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context, photoCount: 6)

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .ready)
        XCTAssertEqual(summary.overallHeadline, "Ready to export")
        XCTAssertFalse(summary.statusLine.lowercased().contains("compliance"))
        XCTAssertFalse(summary.overallHeadline.lowercased().contains("publish"))
    }

    func testLowResolutionSourceReview() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(
            in: context,
            imageSize: CGSize(width: 100, height: 100)
        )
        project.listingExportPreset = .etsySquare

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .review)
        XCTAssertEqual(summary.overallHeadline, "Review before export")
        XCTAssertEqual(item(summary, .photoCheck).level, .review)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("smaller") })
    }

    func testExpectedPaddingReview() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Pad", photos: [photo])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        context.insert(project)

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .review)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("padding") })
        XCTAssertEqual(item(summary, .photoCheck).level, .review)
        XCTAssertTrue(item(summary, .photoCheck).statusLine.lowercased().contains("pad"))
    }

    func testExpectedCroppingReview() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Crop", photos: [photo])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .fillCrop
        context.insert(project)

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .review)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("crop") })
        XCTAssertTrue(item(summary, .photoCheck).statusLine.lowercased().contains("crop"))
    }

    func testPhase38RepositionIsNotAnError() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingExportFitMode = .fillCrop
        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 0.4, y: -0.2)
        project.sortedPhotos[0].savedEditState = state

        let summary = ExportReadiness.summary(for: project)
        XCTAssertNotEqual(summary.status, .needsAttention)
        XCTAssertEqual(item(summary, .fit).level, .ready)
        // May be Review for informational adjusted crop, never Needs Attention from reposition alone.
        XCTAssertFalse(summary.reasons.contains { $0.lowercased().contains("error") })
    }

    func testWatermarkOffDoesNotReduceReadiness() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingWatermarkEnabled = false

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .ready)
        XCTAssertEqual(item(summary, .watermark).level, .optional)
        XCTAssertTrue(item(summary, .watermark).statusLine.contains("Off"))
    }

    func testGuidanceOnlyMarketplaceWithValidCanvasCanBeReady() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingMarketplaceTarget = .facebookMarketplace
        project.listingExportPreset = .marketplace

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .ready)
        XCTAssertEqual(item(summary, .marketplace).level, .ready)
        XCTAssertEqual(item(summary, .marketplace).fact, "Facebook Marketplace")
        XCTAssertEqual(item(summary, .exportSize).fact, "1600×1600")
        XCTAssertFalse(summary.statusLine.lowercased().contains("compliant"))
    }

    // MARK: - Checklist rows

    func testChecklistRowFacts() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context, photoCount: 3)
        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .fillCrop
        project.listingWatermarkEnabled = true
        project.listingWatermarkText = "Shop"

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.items.map(\.id), [
            .photos, .marketplace, .exportSize, .fit, .photoCheck, .watermark
        ])
        XCTAssertEqual(item(summary, .photos).title, "Photos")
        XCTAssertTrue(item(summary, .photos).statusLine.contains("3 photos"))
        XCTAssertEqual(item(summary, .marketplace).fact, "Etsy")
        XCTAssertEqual(item(summary, .exportSize).fact, "2000×2000")
        XCTAssertEqual(item(summary, .fit).fact, ListingExportFitMode.fillCrop.displayTitle)
        XCTAssertEqual(item(summary, .watermark).level, .optional)
        XCTAssertTrue(item(summary, .watermark).statusLine.contains("On"))
        XCTAssertEqual(item(summary, .photoCheck).level, .ready)
    }

    func testPhotoCheckSummaryCounts() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let low = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidRed, size: CGSize(width: 80, height: 80))
        )
        let wide = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let ok = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidRed, size: CGSize(width: 2000, height: 2000))
        )
        let project = ItemProject(
            name: "Counts",
            photos: [
                ItemProjectPhoto(localFileName: low, sortOrder: 0),
                ItemProjectPhoto(localFileName: wide, sortOrder: 1),
                ItemProjectPhoto(localFileName: ok, sortOrder: 2)
            ]
        )
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        context.insert(project)

        let summary = ExportReadiness.summary(for: project)
        let photoCheck = item(summary, .photoCheck)
        XCTAssertEqual(photoCheck.level, .review)
        XCTAssertTrue(photoCheck.fact.lowercased().contains("below") || photoCheck.statusLine.lowercased().contains("below") || photoCheck.explanation?.lowercased().contains("below") == true || summary.reasons.contains { $0.lowercased().contains("smaller") })
        XCTAssertTrue(photoCheck.statusLine.lowercased().contains("pad") || photoCheck.fact.lowercased().contains("pad"))
    }

    // MARK: - Regression

    func testMarketplaceTargetRemainsSeparateFromCanvas() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingMarketplaceTarget = .mercari
        project.listingExportPreset = .instagramSquare

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(item(summary, .marketplace).fact, "Mercari")
        XCTAssertEqual(item(summary, .exportSize).fact, "1080×1080")
        XCTAssertEqual(project.listingMarketplaceTarget, .mercari)
        XCTAssertEqual(project.listingExportPreset, .instagramSquare)
    }

    func testPhase40HistoryUnchangedByReadiness() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        let batch = ProjectExportBatch(
            createdAt: Date(),
            batchFolderName: "batch-42",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: MarketplaceTarget.ebay.rawValue,
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            watermarkEnabled: false
        )
        context.insert(batch)

        _ = ExportReadiness.summary(for: project)
        XCTAssertEqual(project.sortedCompletedExportBatches.count, 1)
        XCTAssertEqual(project.sortedCompletedExportBatches[0].marketplaceTargetRaw, "eBay")
    }

    func testPhase41FiltersCompareUnchanged() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
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
            watermarkEnabled: false
        )
        let newer = ProjectExportBatch(
            createdAt: Date(timeIntervalSince1970: 2),
            batchFolderName: "new",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: "eBay",
            exportPresetRaw: ListingExportPreset.ebay.rawValue,
            exportFitModeRaw: ListingExportFitMode.fillCrop.rawValue,
            exportCanvasWidth: 1600,
            exportCanvasHeight: 1600,
            watermarkEnabled: true
        )
        context.insert(older)
        context.insert(newer)

        let all = ExportHistorySupport.completedBatches(in: project)
        let etsy = ExportHistorySupport.filtered(all, by: .marketplace(.etsy))
        XCTAssertEqual(etsy.count, 1)
        let compare = ExportHistorySupport.compareNewestTwo(all)
        XCTAssertTrue(compare.hasPrevious)
        XCTAssertTrue(compare.lines.contains { $0.contains("Etsy") && $0.contains("eBay") })
    }

    func testSevenPresetsAndFitModesUnchanged() {
        let expected: [(ListingExportPreset, String, CGFloat, CGFloat)] = [
            (.etsySquare, "Etsy square", 2000, 2000),
            (.etsyListing, "Etsy listing", 3000, 2400),
            (.instagramSquare, "Instagram square", 1080, 1080),
            (.facebookPost, "Facebook post", 1200, 630),
            (.marketplace, "Marketplace", 1600, 1600),
            (.ebay, "eBay", 1600, 1600),
            (.poshmark, "Poshmark", 1000, 1000)
        ]
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        for (preset, raw, w, h) in expected {
            XCTAssertEqual(preset.rawValue, raw)
            XCTAssertEqual(preset.pixelSize.width, w)
            XCTAssertEqual(preset.pixelSize.height, h)
        }
        XCTAssertEqual(ListingExportFitMode.containPad.displayTitle, "Contain + Pad")
        XCTAssertEqual(ListingExportFitMode.fillCrop.displayTitle, "Fill + Crop")
    }

    func testPhase38OffsetsPreservedAndReadinessNotPersisted() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingExportFitMode = .fillCrop
        var state = PhotoEditState()
        state.setFillCropOffsets(x: 0.25, y: -0.1)
        project.sortedPhotos[0].savedEditState = state

        let first = ExportReadiness.summary(for: project)
        let offsets = project.sortedPhotos[0].savedEditState
        XCTAssertEqual(offsets?.fillCropOffsetX ?? 0, 0.25, accuracy: 0.0001)
        XCTAssertEqual(offsets?.fillCropOffsetY ?? 0, -0.1, accuracy: 0.0001)

        project.listingWatermarkEnabled = true
        let second = ExportReadiness.summary(for: project)
        XCTAssertEqual(item(first, .watermark).fact, "Off")
        XCTAssertEqual(item(second, .watermark).fact, "On")
        // Still computed from live state — not a stored readiness field on the project.
        XCTAssertEqual(project.sortedPhotos[0].savedEditState?.fillCropOffsetX ?? 0, 0.25, accuracy: 0.0001)
    }
}
