import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase43ExportPrepTipsTests: XCTestCase {
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
        imageSize: CGSize = CGSize(width: 2000, height: 2000)
    ) throws -> ItemProject {
        let file = try LocalEditStore.saveProjectImage(makeSolidImage(color: solidRed, size: imageSize))
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Phase43", photos: [photo])
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

    // MARK: - Tip generation

    func testNoPhotosAddPhotoTip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Empty", photos: [])
        context.insert(project)

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertEqual(tips.first?.id, .addPhotos)
        XCTAssertEqual(tips.first?.action, .captureAndCheckPhotos)
        XCTAssertEqual(tips.count, 1)
    }

    func testLowResolutionReviewSmallPhotosTip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context, imageSize: CGSize(width: 80, height: 80))
        project.listingExportPreset = .etsySquare

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertTrue(tips.contains { $0.id == .reviewSmallPhotos })
        XCTAssertEqual(tips.first { $0.id == .reviewSmallPhotos }?.action, .openPhotoCheck)
    }

    func testExpectedPaddingFitTip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let project = ItemProject(name: "Pad", photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        context.insert(project)

        let tips = ExportPrepTipSupport.tips(for: project)
        let fit = tips.first { $0.id == .reviewFitPadding }
        XCTAssertNotNil(fit)
        XCTAssertEqual(fit?.action, .focusFit)
        XCTAssertTrue(fit?.detail.lowercased().contains("contain") == true)
        XCTAssertFalse(tips.contains { $0.action == .openReposition })
    }

    func testExpectedCroppingFitTip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let project = ItemProject(name: "Crop", photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .fillCrop
        context.insert(project)

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertTrue(tips.contains { $0.id == .reviewFitCropping })
        XCTAssertTrue(tips.contains { $0.id == .adjustCropPosition && $0.action == .openReposition })
    }

    func testFillCropRepositionApplicableTip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let project = ItemProject(name: "Repo", photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .fillCrop
        context.insert(project)

        XCTAssertNotNil(ExportPrepTipSupport.repositionPhoto(in: project))
        let tip = ExportPrepTipSupport.tips(for: project).first { $0.action == .openReposition }
        XCTAssertEqual(tip?.actionLabel, "Reposition")
    }

    func testAdjustedPhase38PositionIsNotAnError() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingExportFitMode = .fillCrop
        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 0.3, y: -0.2)
        project.sortedPhotos[0].savedEditState = state

        let tips = ExportPrepTipSupport.tips(for: project)
        let check = tips.first { $0.id == .checkCropPosition }
        XCTAssertNotNil(check)
        XCTAssertFalse(check!.detail.lowercased().contains("error"))
        XCTAssertFalse(check!.title.lowercased().contains("error"))
        let readiness = ExportReadiness.summary(for: project)
        XCTAssertNotEqual(readiness.status, .needsAttention)
    }

    func testReadyCaseDoesNotCreateFalseWarnings() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertEqual(tips.count, 1)
        XCTAssertEqual(tips[0].id, .readyPreview)
        XCTAssertFalse(tips.contains { $0.id == .reviewSmallPhotos })
        XCTAssertFalse(tips.contains { $0.id == .reviewFitPadding })
        XCTAssertFalse(tips.contains { $0.id == .reviewFitCropping })
    }

    func testWatermarkOffCreatesNoWarning() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingWatermarkEnabled = false

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertFalse(tips.contains { $0.title.lowercased().contains("watermark") })
        XCTAssertFalse(tips.contains { $0.detail.lowercased().contains("watermark") })
    }

    func testGuidanceOnlyMarketplaceWithValidCanvasNoFalseWarning() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingMarketplaceTarget = .facebookMarketplace
        project.listingExportPreset = .marketplace

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertFalse(tips.contains { $0.id == .invalidExportSize })
        XCTAssertFalse(tips.contains { $0.detail.lowercased().contains("compliant") })
        XCTAssertFalse(tips.contains { $0.detail.lowercased().contains("approved") })
        XCTAssertEqual(ExportReadiness.summary(for: project).status, .ready)
    }

    // MARK: - Priority

    func testBlockingRanksAboveReviewAndMaxCount() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let low = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidRed, size: CGSize(width: 50, height: 50))
        )
        let wide = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let project = ItemProject(
            name: "Many",
            photos: [
                ItemProjectPhoto(localFileName: low, sortOrder: 0),
                ItemProjectPhoto(localFileName: wide, sortOrder: 1),
                ItemProjectPhoto(localFileName: "missing-file.jpg", sortOrder: 2)
            ]
        )
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        // Incomplete listing → another review tip candidate
        context.insert(project)

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertLessThanOrEqual(tips.count, ExportPrepTipSupport.maxVisibleTips)
        XCTAssertEqual(tips.first?.id, .missingFiles)
        XCTAssertEqual(Set(tips.map(\.id)).count, tips.count)
    }

    // MARK: - Actions do not mutate

    func testTipGenerationDoesNotMutateExportSettings() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let project = ItemProject(name: "Stable", photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .fillCrop
        project.listingMarketplaceTarget = .etsy
        project.listingWatermarkEnabled = false
        context.insert(project)

        let beforeFit = project.listingExportFitMode
        let beforePreset = project.listingExportPreset
        let beforeMarket = project.listingMarketplaceTarget
        let beforeOffsets = project.sortedPhotos[0].savedEditState?.fillCropOffsetX

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertTrue(tips.contains { $0.action == .focusFit })
        XCTAssertTrue(tips.contains { $0.action == .openReposition })

        XCTAssertEqual(project.listingExportFitMode, beforeFit)
        XCTAssertEqual(project.listingExportPreset, beforePreset)
        XCTAssertEqual(project.listingMarketplaceTarget, beforeMarket)
        XCTAssertEqual(project.sortedPhotos[0].savedEditState?.fillCropOffsetX, beforeOffsets)
    }

    func testRepositionActionOnlyWhenFillCropApplicable() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingExportFitMode = .containPad

        XCTAssertNil(ExportPrepTipSupport.repositionPhoto(in: project))
        XCTAssertFalse(ExportPrepTipSupport.tips(for: project).contains { $0.action == .openReposition })

        project.listingExportFitMode = .fillCrop
        // Matching aspect + centered → no reposition tip
        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertFalse(tips.contains { $0.action == .openReposition })
    }

    // MARK: - Regression

    func testReadinessStatusUnchangedFromPhase42() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let empty = ItemProject(name: "E", photos: [])
        context.insert(empty)
        XCTAssertEqual(ExportReadiness.summary(for: empty).status, .needsAttention)

        let ready = try makeReadyProject(in: context)
        XCTAssertEqual(ExportReadiness.summary(for: ready).status, .ready)
        XCTAssertEqual(ExportReadiness.summary(for: ready).items.count, 6)
    }

    func testSevenPresetsAndPhase38OffsetsUnchanged() throws {
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)

        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingExportFitMode = .fillCrop
        var state = PhotoEditState()
        state.setFillCropOffsets(x: 0.2, y: -0.15)
        project.sortedPhotos[0].savedEditState = state
        _ = ExportPrepTipSupport.tips(for: project)
        XCTAssertEqual(project.sortedPhotos[0].savedEditState?.fillCropOffsetX ?? 0, 0.2, accuracy: 0.0001)
        XCTAssertEqual(project.sortedPhotos[0].savedEditState?.fillCropOffsetY ?? 0, -0.15, accuracy: 0.0001)
    }

    func testPhase39Through41UnchangedAndTipsNotPersisted() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(in: context)
        project.listingMarketplaceTarget = .mercari
        project.listingExportPreset = .instagramSquare
        XCTAssertEqual(project.listingMarketplaceTarget, .mercari)
        XCTAssertEqual(project.listingExportPreset, .instagramSquare)

        let batch = ProjectExportBatch(
            createdAt: Date(),
            batchFolderName: "p43",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            marketplaceTargetRaw: "Mercari",
            exportPresetRaw: ListingExportPreset.instagramSquare.rawValue,
            exportFitModeRaw: ListingExportFitMode.containPad.rawValue,
            exportCanvasWidth: 1080,
            exportCanvasHeight: 1080,
            watermarkEnabled: false
        )
        context.insert(batch)
        _ = ExportPrepTipSupport.tips(for: project)
        XCTAssertEqual(project.sortedCompletedExportBatches.count, 1)

        let all = ExportHistorySupport.completedBatches(in: project)
        XCTAssertEqual(ExportHistorySupport.filtered(all, by: .marketplace(.mercari)).count, 1)
        // Tips are computed — regenerating after watermark toggle changes output without stored tip state.
        project.listingWatermarkEnabled = true
        let again = ExportPrepTipSupport.tips(for: project)
        XCTAssertFalse(again.contains { $0.detail.lowercased().contains("watermark") })
    }
}
