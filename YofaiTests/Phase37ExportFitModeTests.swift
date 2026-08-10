import XCTest
import SwiftData
import UIKit
import CoreGraphics
@testable import Yofai

@MainActor
final class Phase37ExportFitModeTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private let solidRed = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    private let solidGreen = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    private let solidBlue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    private let solidYellow = UIColor(red: 1, green: 1, blue: 0, alpha: 1)
    private let solidOrange = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    private let solidCyan = UIColor(red: 0, green: 1, blue: 1, alpha: 1)
    private let solidMagenta = UIColor(red: 1, green: 0, blue: 1, alpha: 1)

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

    /// Horizontal stripes of equal width left→right.
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

    /// Vertical stripes of equal height top→bottom.
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
        // Draw a 1×1 RGBA sample so byte order is independent of CGImage layout (BGRA vs RGBA).
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

    private func isNearlyWhite(_ pixel: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 12) -> Bool {
        pixel.r >= 255 &- tolerance && pixel.g >= 255 &- tolerance && pixel.b >= 255 &- tolerance
    }

    private func isNearlyRed(_ pixel: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 40) -> Bool {
        Int(pixel.r) > Int(pixel.g) + Int(tolerance) && Int(pixel.r) > Int(pixel.b) + Int(tolerance)
    }

    private func isNearlyGreen(_ pixel: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 40) -> Bool {
        Int(pixel.g) > Int(pixel.r) + Int(tolerance) && Int(pixel.g) > Int(pixel.b) + Int(tolerance)
    }

    private func isNearlyBlue(_ pixel: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 40) -> Bool {
        Int(pixel.b) > Int(pixel.r) + Int(tolerance) && Int(pixel.b) > Int(pixel.g) + Int(tolerance)
    }

    private func framed(
        _ image: UIImage,
        preset: ListingExportPreset = .instagramSquare,
        background: ListingExportBackground = .white,
        fitMode: ListingExportFitMode
    ) -> UIImage {
        let result = ImageEditing.applyListingFrame(
            image,
            preset: preset,
            background: background,
            fitMode: fitMode,
            watermarkEnabled: false,
            watermarkText: "",
            maxDimension: nil
        )
        XCTAssertNotNil(result)
        return result!
    }

    // MARK: - Model / persistence

    func testFitModeRawValuesEncodeDecode() throws {
        XCTAssertEqual(ListingExportFitMode.containPad.rawValue, "Contain + Pad")
        XCTAssertEqual(ListingExportFitMode.fillCrop.rawValue, "Fill + Crop")
        XCTAssertEqual(ListingExportFitMode(rawValue: "Contain + Pad"), .containPad)
        XCTAssertEqual(ListingExportFitMode(rawValue: "Fill + Crop"), .fillCrop)
        XCTAssertNil(ListingExportFitMode(rawValue: "cover"))
        XCTAssertEqual(ListingExportFitMode.resolved(rawValue: nil), .containPad)
        XCTAssertEqual(ListingExportFitMode.resolved(rawValue: ""), .containPad)
        XCTAssertEqual(ListingExportFitMode.resolved(rawValue: "unknown"), .containPad)
        XCTAssertEqual(ListingExportFitMode.default, .containPad)

        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PhotoEditState.self, from: data)
        XCTAssertEqual(decoded.exportFitMode, .fillCrop)
    }

    func testMissingFitModeInPhotoEditStateDefaultsToContainPad() throws {
        let legacyJSON = """
        {"filter":"Original","quarterTurns":0,"brightness":0,"contrast":1,"saturation":1,"exportPreset":"Etsy square","exportBackground":"White","watermarkEnabled":false,"watermarkText":""}
        """.data(using: .utf8)!
        let state = try JSONDecoder().decode(PhotoEditState.self, from: legacyJSON)
        XCTAssertEqual(state.exportFitMode, .containPad)
    }

    func testSellerDefaultsMissingFitModeDefaultsAndPreserves() throws {
        let legacyJSON = """
        {"category":"Hats","materials":"","shippingProfile":"","processingTime":"","exportPresetRaw":"Etsy square","exportBackgroundRaw":"White","watermarkText":""}
        """.data(using: .utf8)!
        let defaults = try JSONDecoder().decode(SellerDefaults.self, from: legacyJSON)
        XCTAssertEqual(defaults.exportFitMode, .containPad)
        XCTAssertEqual(defaults.exportFitModeRaw, ListingExportFitMode.containPad.rawValue)

        var updated = defaults
        updated.exportFitMode = .fillCrop
        let encoded = try JSONEncoder().encode(updated)
        let roundTrip = try JSONDecoder().decode(SellerDefaults.self, from: encoded)
        XCTAssertEqual(roundTrip.exportFitMode, .fillCrop)
    }

    func testProjectMissingOrUnknownFitModeResolvesToContainPad() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Legacy", photos: [])
        context.insert(project)
        XCTAssertEqual(project.listingExportFitMode, .containPad)

        project.listingExportFitModeRaw = ""
        XCTAssertEqual(project.listingExportFitMode, .containPad)
        project.listingExportFitModeRaw = "garbage"
        XCTAssertEqual(project.listingExportFitMode, .containPad)

        project.listingExportFitMode = .fillCrop
        XCTAssertEqual(project.listingExportFitModeRaw, "Fill + Crop")
    }

    // MARK: - Framing behavior

    func testContainPadKeepsFullImageWithPaddingOnMismatch() {
        let source = makeSolidImage(color: solidRed, size: CGSize(width: 400, height: 100))
        let output = framed(source, background: .white, fitMode: .containPad)
        let canvas = ListingExportPreset.instagramSquare.pixelSize
        XCTAssertEqual(Int(output.size.width), Int(canvas.width))
        XCTAssertEqual(Int(output.size.height), Int(canvas.height))

        guard let topLeft = pixelRGBA(in: output, x: 2, y: 2),
              let center = pixelRGBA(in: output, x: Int(canvas.width) / 2, y: Int(canvas.height) / 2) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertTrue(isNearlyWhite(topLeft), "Contain+Pad should show background padding at corners: \(topLeft)")
        XCTAssertTrue(isNearlyRed(center), "Contain+Pad should keep source content centered: \(center)")
    }

    func testFillCropOutputMatchesCanvasExactly() {
        let source = makeSolidImage(color: solidBlue, size: CGSize(width: 300, height: 150))
        for preset in ListingExportPreset.allCases {
            let output = framed(source, preset: preset, background: .white, fitMode: .fillCrop)
            XCTAssertEqual(Int(output.size.width), Int(preset.pixelSize.width), preset.rawValue)
            XCTAssertEqual(Int(output.size.height), Int(preset.pixelSize.height), preset.rawValue)
        }
    }

    func testFillCropPreservesAspectRatioNoStretch() {
        // 2:1 source on square: scale by height; width overflows equally → horizontal crop only.
        let colors = [solidRed, solidGreen, solidBlue, solidYellow]
        let source = makeHorizontalStripeImage(colors: colors, size: CGSize(width: 400, height: 200))
        let output = framed(source, preset: .instagramSquare, background: .white, fitMode: .fillCrop)
        let w = Int(output.size.width)
        let h = Int(output.size.height)
        XCTAssertEqual(w, 1080)
        XCTAssertEqual(h, 1080)

        guard let left = pixelRGBA(in: output, x: 4, y: h / 2),
              let right = pixelRGBA(in: output, x: w - 5, y: h / 2),
              let mid = pixelRGBA(in: output, x: w / 2, y: h / 2) else {
            return XCTFail("Missing pixels")
        }
        // Visible source region after center crop is the middle half (green+blue).
        XCTAssertTrue(isNearlyGreen(left) || isNearlyBlue(left), "Left edge should be from mid stripes, not red pad: \(left)")
        XCTAssertTrue(isNearlyGreen(right) || isNearlyBlue(right), "Right edge should be from mid stripes: \(right)")
        XCTAssertFalse(isNearlyWhite(mid), "Canvas should be fully filled: \(mid)")
        XCTAssertFalse(isNearlyWhite(left))
    }

    func testFillCropWideSourceCropsHorizontalOverflow() {
        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let output = framed(source, preset: .instagramSquare, background: .black, fitMode: .fillCrop)
        let w = Int(output.size.width)
        let h = Int(output.size.height)
        guard let left = pixelRGBA(in: output, x: 2, y: h / 2),
              let right = pixelRGBA(in: output, x: w - 3, y: h / 2) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertFalse(isNearlyRed(left), "Far-left red stripe should be cropped away: \(left)")
        XCTAssertTrue(isNearlyGreen(left) || isNearlyBlue(left), "\(left)")
        XCTAssertTrue(isNearlyGreen(right) || isNearlyBlue(right), "\(right)")
    }

    func testFillCropTallSourceCropsVerticalOverflow() {
        let source = makeVerticalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 100, height: 400)
        )
        let output = framed(source, preset: .instagramSquare, background: .black, fitMode: .fillCrop)
        let w = Int(output.size.width)
        let h = Int(output.size.height)
        guard let top = pixelRGBA(in: output, x: w / 2, y: 2),
              let bottom = pixelRGBA(in: output, x: w / 2, y: h - 3) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertFalse(isNearlyRed(top), "Top red stripe should be cropped away: \(top)")
        XCTAssertTrue(isNearlyGreen(top) || isNearlyBlue(top), "\(top)")
        XCTAssertTrue(isNearlyGreen(bottom) || isNearlyBlue(bottom), "\(bottom)")
    }

    func testMatchingAspectFillCropHasNoMeaningfulCrop() {
        let source = makeSolidImage(color: solidRed, size: CGSize(width: 200, height: 200))
        let contain = framed(source, background: .white, fitMode: .containPad)
        let fill = framed(source, background: .white, fitMode: .fillCrop)
        XCTAssertEqual(Int(contain.size.width), Int(fill.size.width))
        XCTAssertEqual(Int(contain.size.height), Int(fill.size.height))

        // Matching square→square: both fill the canvas with the solid red (no pad strip).
        guard let containCorner = pixelRGBA(in: contain, x: 2, y: 2),
              let fillCorner = pixelRGBA(in: fill, x: 2, y: 2) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertTrue(isNearlyRed(containCorner), "\(containCorner)")
        XCTAssertTrue(isNearlyRed(fillCorner), "\(fillCorner)")
    }

    // MARK: - Batch / Photo Check / Phase 36 sizes

    func testBatchExporterHonorsFillCrop() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidOrange, size: CGSize(width: 400, height: 100))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Fit batch", photos: [photo])
        project.listingExportPreset = .instagramSquare
        project.listingExportBackground = .white
        project.listingExportFitMode = .fillCrop
        context.insert(project)

        let state = photo.exportEditState(project: project)
        XCTAssertEqual(state.exportFitMode, .fillCrop)

        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(result.successCount, 1)
        guard let url = LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: "01.jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return XCTFail("Missing batch JPEG")
        }
        XCTAssertEqual(Int(image.size.width), 1080)
        XCTAssertEqual(Int(image.size.height), 1080)
        guard let corner = pixelRGBA(in: image, x: 2, y: 2) else {
            return XCTFail("Missing corner pixel")
        }
        XCTAssertFalse(isNearlyWhite(corner), "Fill+Crop batch export should not show pad color at corners")
    }

    func testPhotoCheckDistinguishesPaddingVsCroppingExpected() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidCyan, size: CGSize(width: 3000, height: 1000))
        )
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Check", photos: [photo])
        project.listingExportPreset = .etsySquare
        project.listingExportFitMode = .containPad
        context.insert(project)

        var facts = PhotoTechnicalCheck.facts(for: photo, project: project)
        XCTAssertEqual(facts.exportFitMode, .containPad)
        XCTAssertEqual(facts.sourceAspectDiffersFromCanvas, true)
        XCTAssertEqual(facts.framingExpectation, "Padding expected (Contain + Pad)")

        project.listingExportFitMode = .fillCrop
        facts = PhotoTechnicalCheck.facts(for: photo, project: project)
        XCTAssertEqual(facts.exportFitMode, .fillCrop)
        XCTAssertEqual(facts.framingExpectation, "Cropping expected (Fill + Crop)")

        let matchFile = try LocalEditStore.saveProjectImage(
            makeSolidImage(color: solidMagenta, size: CGSize(width: 2000, height: 2000))
        )
        let matchPhoto = ItemProjectPhoto(localFileName: matchFile, sortOrder: 1)
        project.photos.append(matchPhoto)
        facts = PhotoTechnicalCheck.facts(for: matchPhoto, project: project)
        XCTAssertEqual(facts.sourceAspectDiffersFromCanvas, false)
        XCTAssertEqual(facts.framingExpectation, "No meaningful pad/crop from aspect mismatch")
    }

    func testPhase36SevenPresetRawValuesAndDimensionsUnchanged() {
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

    func testSellerDefaultsApplyFitModeToNewProject() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        var defaults = SellerDefaults()
        defaults.exportFitMode = .fillCrop
        let project = ItemProject(name: "From defaults", photos: [])
        defaults.apply(to: project)
        context.insert(project)
        XCTAssertEqual(project.listingExportFitMode, .fillCrop)
    }

    func testBulkEditCopiesFitModeWhenSelected() {
        var source = PhotoEditState()
        source.exportFitMode = .fillCrop
        var target = PhotoEditState()
        target.exportFitMode = .containPad
        let merged = BulkEditSupport.merge(
            source: source,
            into: target,
            including: [.fitMode]
        )
        XCTAssertEqual(merged.exportFitMode, .fillCrop)
        XCTAssertTrue(
            BulkEditSupport.recipeSummary(state: source, including: [.fitMode])
                .contains { $0.contains("Fill + Crop") }
        )
    }
}
