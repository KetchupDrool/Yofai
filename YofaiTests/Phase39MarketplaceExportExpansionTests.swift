import XCTest
import SwiftData
import UIKit
import CoreGraphics
@testable import Yofai

@MainActor
final class Phase39MarketplaceExportExpansionTests: XCTestCase {
    private let solidRed = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    private let solidGreen = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    private let solidBlue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    private let solidYellow = UIColor(red: 1, green: 1, blue: 0, alpha: 1)

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

    private func makeHorizontalStripeImage(colors: [UIColor], size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let stripeW = size.width / CGFloat(colors.count)
            for (index, color) in colors.enumerated() {
                color.setFill()
                context.fill(CGRect(x: CGFloat(index) * stripeW, y: 0, width: stripeW, height: size.height))
            }
        }
    }

    private func makeVerticalStripeImage(colors: [UIColor], size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let stripeH = size.height / CGFloat(colors.count)
            for (index, color) in colors.enumerated() {
                color.setFill()
                context.fill(CGRect(x: 0, y: CGFloat(index) * stripeH, width: size.width, height: stripeH))
            }
        }
    }

    private func pixelRGBA(in image: UIImage, x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8)? {
        guard let cgImage = image.cgImage,
              x >= 0, y >= 0, x < cgImage.width, y < cgImage.height else { return nil }
        var pixel: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .none
        context.translateBy(x: -CGFloat(x), y: -CGFloat(y))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        return (pixel[0], pixel[1], pixel[2], pixel[3])
    }

    private func isNearlyWhite(_ p: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 12) -> Bool {
        p.r >= 255 &- tolerance && p.g >= 255 &- tolerance && p.b >= 255 &- tolerance
    }

    private func isNearlyRed(_ p: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 40) -> Bool {
        Int(p.r) > Int(p.g) + Int(tolerance) && Int(p.r) > Int(p.b) + Int(tolerance)
    }

    private func framed(
        _ image: UIImage,
        preset: ListingExportPreset,
        fitMode: ListingExportFitMode,
        offsetX: Double = 0,
        offsetY: Double = 0,
        background: ListingExportBackground = .white
    ) -> UIImage {
        let result = ImageEditing.applyListingFrame(
            image,
            preset: preset,
            background: background,
            fitMode: fitMode,
            fillCropOffsetX: offsetX,
            fillCropOffsetY: offsetY,
            watermarkEnabled: false,
            watermarkText: "",
            maxDimension: nil
        )
        XCTAssertNotNil(result)
        return result!
    }

    // MARK: - Presets / marketplace targets

    func testAllSevenPresetRawValuesAndDimensionsUnchanged() {
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
    }

    func testNoFacebookMarketplaceOrMercariNamedPixelPresets() {
        let raw = ListingExportPreset.allCases.map(\.rawValue)
        XCTAssertFalse(raw.contains("Facebook Marketplace"))
        XCTAssertFalse(raw.contains("Mercari"))
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        XCTAssertFalse(MarketplaceTarget.facebookMarketplace.hasVerifiedYofaiCanvas)
        XCTAssertFalse(MarketplaceTarget.mercari.hasVerifiedYofaiCanvas)
    }

    func testVerifiedTargetsRecommendExistingCanvasesOnly() {
        XCTAssertEqual(MarketplaceTarget.etsy.recommendedExportPreset, .etsySquare)
        XCTAssertEqual(MarketplaceTarget.ebay.recommendedExportPreset, .ebay)
        XCTAssertEqual(MarketplaceTarget.poshmark.recommendedExportPreset, .poshmark)
        XCTAssertNil(MarketplaceTarget.other.recommendedExportPreset)
    }

    func testUnknownMarketplaceTargetDecodesSafely() {
        XCTAssertEqual(MarketplaceTarget.resolved(rawValue: nil), .other)
        XCTAssertEqual(MarketplaceTarget.resolved(rawValue: ""), .other)
        XCTAssertEqual(MarketplaceTarget.resolved(rawValue: "Not A Market"), .other)
        XCTAssertEqual(MarketplaceTarget(rawValue: "Facebook Marketplace"), .facebookMarketplace)
    }

    func testMarketplaceTargetDoesNotInventCanvas() {
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        XCTAssertTrue(
            MarketplaceTarget.facebookMarketplace.canvasGuidance.lowercased().contains("no fixed verified")
        )
        XCTAssertTrue(
            MarketplaceTarget.mercari.canvasGuidance.lowercased().contains("no fixed verified")
        )
    }

    // MARK: - Backward compatibility

    func testSellerDefaultsLegacyJSONLoadsWithoutMarketplaceKey() throws {
        let legacy = """
        {"category":"Hats","materials":"","shippingProfile":"","processingTime":"","exportPresetRaw":"Etsy square","exportBackgroundRaw":"White","exportFitModeRaw":"Contain + Pad","watermarkText":""}
        """.data(using: .utf8)!
        let defaults = try JSONDecoder().decode(SellerDefaults.self, from: legacy)
        XCTAssertEqual(defaults.marketplaceTarget, .other)
        XCTAssertEqual(defaults.exportFitMode, .containPad)
        XCTAssertEqual(defaults.exportPreset, .etsySquare)
    }

    func testPhase37FitModeFallbackStillWorks() {
        XCTAssertEqual(ListingExportFitMode.resolved(rawValue: nil), .containPad)
        XCTAssertEqual(ListingExportFitMode.resolved(rawValue: "nope"), .containPad)
    }

    func testPhase38MissingOffsetsStillCenter() throws {
        let legacyJSON = """
        {"filter":"Original","quarterTurns":0,"brightness":0,"contrast":1,"saturation":1,"exportPreset":"Etsy square","exportBackground":"White","exportFitMode":"Fill + Crop","watermarkEnabled":false,"watermarkText":""}
        """.data(using: .utf8)!
        let state = try JSONDecoder().decode(PhotoEditState.self, from: legacyJSON)
        XCTAssertEqual(state.fillCropOffsetX, 0)
        XCTAssertEqual(state.fillCropOffsetY, 0)
    }

    func testProjectMissingMarketplaceTargetResolvesToOther() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Legacy", photos: [])
        context.insert(project)
        XCTAssertEqual(project.listingMarketplaceTarget, .other)
        project.listingMarketplaceTargetRaw = ""
        XCTAssertEqual(project.listingMarketplaceTarget, .other)
    }

    // MARK: - Export behavior

    func testExactDimensionsForEveryPreset() {
        let source = makeSolidImage(color: solidRed, size: CGSize(width: 400, height: 300))
        for preset in ListingExportPreset.allCases {
            let output = framed(source, preset: preset, fitMode: .containPad)
            XCTAssertEqual(Int(output.size.width), Int(preset.pixelSize.width), preset.rawValue)
            XCTAssertEqual(Int(output.size.height), Int(preset.pixelSize.height), preset.rawValue)
        }
    }

    func testContainPadUnchangedAndIgnoresOffsets() {
        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let a = framed(source, preset: .instagramSquare, fitMode: .containPad, offsetX: 0, offsetY: 0)
        let b = framed(source, preset: .instagramSquare, fitMode: .containPad, offsetX: 1, offsetY: -1)
        guard let pa = pixelRGBA(in: a, x: 2, y: 2), let pb = pixelRGBA(in: b, x: 2, y: 2) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertTrue(isNearlyWhite(pa))
        XCTAssertTrue(isNearlyWhite(pb))
    }

    func testFillCropHorizontalAndVerticalOffsetsHonored() {
        let wide = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let left = framed(wide, preset: .instagramSquare, fitMode: .fillCrop, offsetX: 1, offsetY: 0, background: .black)
        guard let leftPixel = pixelRGBA(in: left, x: 4, y: Int(left.size.height) / 2) else {
            return XCTFail("Missing left pixel")
        }
        XCTAssertTrue(isNearlyRed(leftPixel) || (Int(leftPixel.g) > Int(leftPixel.r)), "\(leftPixel)")

        let tall = makeVerticalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 100, height: 400)
        )
        let top = framed(tall, preset: .instagramSquare, fitMode: .fillCrop, offsetX: 0, offsetY: 1, background: .black)
        guard let topPixel = pixelRGBA(in: top, x: Int(top.size.width) / 2, y: 4) else {
            return XCTFail("Missing top pixel")
        }
        XCTAssertTrue(isNearlyRed(topPixel) || (Int(topPixel.g) > Int(topPixel.b)), "\(topPixel)")
    }

    func testBatchExportHonorsOffsetsAndTargetSwitchPreservesThem() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let file = try LocalEditStore.saveProjectImage(source)
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 1, y: 0)
        photo.savedEditState = state

        let project = ItemProject(name: "Multi market", photos: [photo])
        project.listingExportFitMode = .fillCrop
        project.listingExportPreset = .instagramSquare
        context.insert(project)

        MarketplaceExportSupport.switchTarget(on: project, to: .ebay, applyRecommendedCanvas: true)
        XCTAssertEqual(project.listingMarketplaceTarget, .ebay)
        XCTAssertEqual(project.listingExportPreset, .ebay)
        XCTAssertEqual(photo.savedEditState?.fillCropOffsetX ?? -99, 1, accuracy: 0.0001)

        let exportState = photo.exportEditState(project: project)
        XCTAssertEqual(exportState.fillCropOffsetX, 1, accuracy: 0.0001)
        XCTAssertEqual(exportState.exportPreset, .ebay)
        XCTAssertEqual(exportState.exportFitMode, .fillCrop)

        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(result.successCount, 1)
        guard let url = LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: "01.jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return XCTFail("Missing batch JPEG")
        }
        XCTAssertEqual(Int(image.size.width), 1600)
        XCTAssertEqual(Int(image.size.height), 1600)
        // Offsets still present after export (no silent mutation)
        XCTAssertEqual(photo.savedEditState?.fillCropOffsetX ?? -99, 1, accuracy: 0.0001)
    }

    func testSwitchToUnverifiedTargetDoesNotInventPreset() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "FB", photos: [])
        project.listingExportPreset = .etsySquare
        context.insert(project)

        MarketplaceExportSupport.switchTarget(
            on: project,
            to: .facebookMarketplace,
            applyRecommendedCanvas: true
        )
        XCTAssertEqual(project.listingMarketplaceTarget, .facebookMarketplace)
        XCTAssertEqual(project.listingExportPreset, .etsySquare)
    }

    // MARK: - Readiness

    func testReadinessReadyCase() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidRed, size: CGSize(width: 2000, height: 2000))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Ready", photos: [photo])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        context.insert(project)

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .ready)
        XCTAssertFalse(summary.statusLine.lowercased().contains("compliance"))
    }

    func testReadinessLowResolutionReview() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidRed, size: CGSize(width: 100, height: 100))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Small", photos: [photo])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        context.insert(project)

        let summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .review)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("smaller") })
    }

    func testReadinessPaddingAndCropCases() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidBlue, size: CGSize(width: 3000, height: 1000))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Wide", photos: [photo])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        context.insert(project)

        var summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .review)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("padding") })

        project.listingExportFitMode = .fillCrop
        summary = ExportReadiness.summary(for: project)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("crop") })
    }

    func testReadinessAdjustedCropPositionAndNeedsAttention() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidRed, size: CGSize(width: 2000, height: 2000))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 0.5, y: 0)
        photo.savedEditState = state
        let project = ItemProject(name: "Adjusted", photos: [photo])
        project.listingTitle = "Hat"
        project.listingPriceText = "12"
        project.listingQuantity = 1
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .fillCrop
        context.insert(project)

        let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
        XCTAssertEqual(facts.fillCropPositionAdjusted, true)

        var summary = ExportReadiness.summary(for: project)
        XCTAssertEqual(summary.status, .review)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("adjusted") })

        let empty = ItemProject(name: "Empty", photos: [])
        context.insert(empty)
        summary = ExportReadiness.summary(for: empty)
        XCTAssertEqual(summary.status, .needsAttention)
        XCTAssertTrue(summary.reasons.contains { $0.lowercased().contains("no photos") })
        XCTAssertFalse(summary.statusLine.lowercased().contains("compliant"))
    }

    func testSellerDefaultsApplyMarketplaceTarget() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        var defaults = SellerDefaults()
        defaults.marketplaceTarget = .poshmark
        defaults.exportPreset = .poshmark
        let project = ItemProject(name: "From defaults", photos: [])
        defaults.apply(to: project)
        context.insert(project)
        XCTAssertEqual(project.listingMarketplaceTarget, .poshmark)
        XCTAssertEqual(project.listingExportPreset, .poshmark)
    }
}
