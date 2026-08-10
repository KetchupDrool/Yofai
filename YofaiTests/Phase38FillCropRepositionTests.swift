import XCTest
import SwiftData
import UIKit
import CoreGraphics
@testable import Yofai

@MainActor
final class Phase38FillCropRepositionTests: XCTestCase {
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

    private func isNearlyGreen(_ p: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 40) -> Bool {
        Int(p.g) > Int(p.r) + Int(tolerance) && Int(p.g) > Int(p.b) + Int(tolerance)
    }

    private func isNearlyBlue(_ p: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 40) -> Bool {
        Int(p.b) > Int(p.r) + Int(tolerance) && Int(p.b) > Int(p.g) + Int(tolerance)
    }

    private func framed(
        _ image: UIImage,
        preset: ListingExportPreset = .instagramSquare,
        background: ListingExportBackground = .white,
        fitMode: ListingExportFitMode,
        offsetX: Double = 0,
        offsetY: Double = 0
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

    func testMissingOffsetsResolveToCentered() throws {
        let legacyJSON = """
        {"filter":"Original","quarterTurns":0,"brightness":0,"contrast":1,"saturation":1,"exportPreset":"Etsy square","exportBackground":"White","exportFitMode":"Fill + Crop","watermarkEnabled":false,"watermarkText":""}
        """.data(using: .utf8)!
        let state = try JSONDecoder().decode(PhotoEditState.self, from: legacyJSON)
        XCTAssertEqual(state.fillCropOffsetX, 0)
        XCTAssertEqual(state.fillCropOffsetY, 0)
        XCTAssertTrue(state.isFillCropCentered)
    }

    func testCenteredOffsetsReproducePhase37CenterCrop() {
        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let phase37Style = framed(source, fitMode: .fillCrop, offsetX: 0, offsetY: 0)
        let explicitCenter = framed(source, fitMode: .fillCrop, offsetX: 0, offsetY: 0)
        XCTAssertEqual(Int(phase37Style.size.width), Int(explicitCenter.size.width))
        XCTAssertEqual(Int(phase37Style.size.height), Int(explicitCenter.size.height))

        let w = Int(phase37Style.size.width)
        let h = Int(phase37Style.size.height)
        guard let a = pixelRGBA(in: phase37Style, x: w / 2, y: h / 2),
              let b = pixelRGBA(in: explicitCenter, x: w / 2, y: h / 2) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertEqual(a.r, b.r)
        XCTAssertEqual(a.g, b.g)
        XCTAssertEqual(a.b, b.b)
    }

    func testHorizontalRepositionChangesCropKeepsDimensions() {
        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let leftBias = framed(source, background: .black, fitMode: .fillCrop, offsetX: 1, offsetY: 0)
        let rightBias = framed(source, background: .black, fitMode: .fillCrop, offsetX: -1, offsetY: 0)
        XCTAssertEqual(Int(leftBias.size.width), 1080)
        XCTAssertEqual(Int(leftBias.size.height), 1080)
        XCTAssertEqual(Int(rightBias.size.width), 1080)
        XCTAssertEqual(Int(rightBias.size.height), 1080)

        let w = Int(leftBias.size.width)
        let h = Int(leftBias.size.height)
        guard let leftEdge = pixelRGBA(in: leftBias, x: 4, y: h / 2),
              let rightEdge = pixelRGBA(in: rightBias, x: w - 5, y: h / 2) else {
            return XCTFail("Missing pixels")
        }
        // +1 aligns left of source → left edge from left stripes; -1 aligns right → right stripes
        XCTAssertTrue(isNearlyRed(leftEdge) || isNearlyGreen(leftEdge), "\(leftEdge)")
        XCTAssertTrue(isNearlyBlue(rightEdge) || isNearlyYellowish(rightEdge), "\(rightEdge)")
    }

    private func isNearlyYellowish(_ p: (r: UInt8, g: UInt8, b: UInt8, a: UInt8), tolerance: UInt8 = 40) -> Bool {
        Int(p.r) > Int(p.b) + Int(tolerance) && Int(p.g) > Int(p.b) + Int(tolerance)
    }

    func testVerticalRepositionChangesCropKeepsDimensions() {
        let source = makeVerticalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 100, height: 400)
        )
        let topBias = framed(source, background: .black, fitMode: .fillCrop, offsetX: 0, offsetY: 1)
        let bottomBias = framed(source, background: .black, fitMode: .fillCrop, offsetX: 0, offsetY: -1)
        XCTAssertEqual(Int(topBias.size.width), 1080)
        XCTAssertEqual(Int(topBias.size.height), 1080)

        let w = Int(topBias.size.width)
        let h = Int(topBias.size.height)
        guard let top = pixelRGBA(in: topBias, x: w / 2, y: 4),
              let bottom = pixelRGBA(in: bottomBias, x: w / 2, y: h - 5) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertTrue(isNearlyRed(top) || isNearlyGreen(top), "\(top)")
        XCTAssertTrue(isNearlyBlue(bottom) || isNearlyYellowish(bottom), "\(bottom)")
    }

    func testOffsetsClampToValidRange() {
        XCTAssertEqual(ListingExportFillCropPosition.clamp(2), 1)
        XCTAssertEqual(ListingExportFillCropPosition.clamp(-3), -1)
        XCTAssertEqual(ListingExportFillCropPosition.clamp(0.25), 0.25)

        var state = PhotoEditState()
        state.setFillCropOffsets(x: 5, y: -9)
        XCTAssertEqual(state.fillCropOffsetX, 1)
        XCTAssertEqual(state.fillCropOffsetY, -1)
    }

    func testFillCropNeverExposesBlankCanvas() {
        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        for ox in [-1.0, -0.5, 0.0, 0.5, 1.0] {
            let output = framed(source, background: .white, fitMode: .fillCrop, offsetX: ox, offsetY: 0)
            let w = Int(output.size.width)
            let h = Int(output.size.height)
            let samples = [
                pixelRGBA(in: output, x: 2, y: 2),
                pixelRGBA(in: output, x: w - 3, y: 2),
                pixelRGBA(in: output, x: 2, y: h - 3),
                pixelRGBA(in: output, x: w - 3, y: h - 3),
                pixelRGBA(in: output, x: w / 2, y: h / 2)
            ]
            for sample in samples {
                guard let pixel = sample else {
                    return XCTFail("Missing sample")
                }
                XCTAssertFalse(isNearlyWhite(pixel), "Blank canvas exposed at offset \(ox): \(pixel)")
            }
        }
    }

    func testWideSourceAllowsHorizontalReposition() {
        let imageSize = CGSize(width: 400, height: 100)
        let canvas = ListingExportPreset.instagramSquare.pixelSize
        XCTAssertTrue(
            ListingExportFillCropPosition.canRepositionHorizontally(imagePixelSize: imageSize, canvas: canvas)
        )
        XCTAssertFalse(
            ListingExportFillCropPosition.canRepositionVertically(imagePixelSize: imageSize, canvas: canvas)
        )
    }

    func testTallSourceAllowsVerticalReposition() {
        let imageSize = CGSize(width: 100, height: 400)
        let canvas = ListingExportPreset.instagramSquare.pixelSize
        XCTAssertTrue(
            ListingExportFillCropPosition.canRepositionVertically(imagePixelSize: imageSize, canvas: canvas)
        )
        XCTAssertFalse(
            ListingExportFillCropPosition.canRepositionHorizontally(imagePixelSize: imageSize, canvas: canvas)
        )
    }

    func testAxisWithoutOverflowIgnoresOffsetSafely() {
        let square = makeSolidImage(color: solidRed, size: CGSize(width: 200, height: 200))
        let centered = framed(square, fitMode: .fillCrop, offsetX: 0, offsetY: 0)
        let panned = framed(square, fitMode: .fillCrop, offsetX: 1, offsetY: -1)
        XCTAssertEqual(Int(centered.size.width), Int(panned.size.width))
        XCTAssertEqual(Int(centered.size.height), Int(panned.size.height))
        guard let a = pixelRGBA(in: centered, x: 10, y: 10),
              let b = pixelRGBA(in: panned, x: 10, y: 10) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertEqual(a.r, b.r)
        XCTAssertEqual(a.g, b.g)
        XCTAssertEqual(a.b, b.b)
    }

    func testResetToCenterProducesCenteredOutput() {
        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 0.8, y: -0.6)
        XCTAssertTrue(state.hasFillCropReposition)
        state.resetFillCropPosition()
        XCTAssertTrue(state.isFillCropCentered)

        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let resetOut = framed(source, fitMode: .fillCrop, offsetX: state.fillCropOffsetX, offsetY: state.fillCropOffsetY)
        let centerOut = framed(source, fitMode: .fillCrop, offsetX: 0, offsetY: 0)
        let w = Int(resetOut.size.width)
        let h = Int(resetOut.size.height)
        guard let a = pixelRGBA(in: resetOut, x: w / 2, y: h / 2),
              let b = pixelRGBA(in: centerOut, x: w / 2, y: h / 2) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertEqual(a.r, b.r)
        XCTAssertEqual(a.g, b.g)
        XCTAssertEqual(a.b, b.b)
    }

    func testPersistenceEncodeDecode() throws {
        var state = PhotoEditState()
        state.exportFitMode = .fillCrop
        state.setFillCropOffsets(x: 0.4, y: -0.75)
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PhotoEditState.self, from: data)
        XCTAssertEqual(decoded.fillCropOffsetX, 0.4, accuracy: 0.0001)
        XCTAssertEqual(decoded.fillCropOffsetY, -0.75, accuracy: 0.0001)
    }

    func testBatchExportRespectsSavedPosition() throws {
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
        state.exportPreset = .instagramSquare
        state.exportBackground = .white
        state.setFillCropOffsets(x: 1, y: 0)
        photo.savedEditState = state

        let project = ItemProject(name: "Reposition batch", photos: [photo])
        project.listingExportPreset = .instagramSquare
        project.listingExportBackground = .white
        project.listingExportFitMode = .fillCrop
        context.insert(project)

        let exportState = photo.exportEditState(project: project)
        XCTAssertEqual(exportState.fillCropOffsetX, 1, accuracy: 0.0001)
        XCTAssertEqual(exportState.exportFitMode, .fillCrop)

        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(result.successCount, 1)
        guard let url = LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: "01.jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data),
              let corner = pixelRGBA(in: image, x: 4, y: Int(image.size.height) / 2) else {
            return XCTFail("Missing batch JPEG")
        }
        XCTAssertEqual(Int(image.size.width), 1080)
        XCTAssertEqual(Int(image.size.height), 1080)
        XCTAssertTrue(isNearlyRed(corner) || isNearlyGreen(corner), "\(corner)")
    }

    func testContainPadIgnoresCropPosition() {
        let source = makeHorizontalStripeImage(
            colors: [solidRed, solidGreen, solidBlue, solidYellow],
            size: CGSize(width: 400, height: 100)
        )
        let a = framed(source, background: .white, fitMode: .containPad, offsetX: 0, offsetY: 0)
        let b = framed(source, background: .white, fitMode: .containPad, offsetX: 1, offsetY: -1)
        guard let pa = pixelRGBA(in: a, x: 2, y: 2),
              let pb = pixelRGBA(in: b, x: 2, y: 2),
              let ca = pixelRGBA(in: a, x: Int(a.size.width) / 2, y: Int(a.size.height) / 2),
              let cb = pixelRGBA(in: b, x: Int(b.size.width) / 2, y: Int(b.size.height) / 2) else {
            return XCTFail("Missing pixels")
        }
        XCTAssertTrue(isNearlyWhite(pa))
        XCTAssertTrue(isNearlyWhite(pb))
        XCTAssertEqual(ca.r, cb.r)
        XCTAssertEqual(ca.g, cb.g)
        XCTAssertEqual(ca.b, cb.b)
    }

    func testSevenPresetSizesUnchanged() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.etsyListing.pixelSize, CGSize(width: 3000, height: 2400))
        XCTAssertEqual(ListingExportPreset.instagramSquare.pixelSize, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(ListingExportPreset.facebookPost.pixelSize, CGSize(width: 1200, height: 630))
        XCTAssertEqual(ListingExportPreset.marketplace.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
    }

    func testBulkEditCanCopyFillCropPosition() {
        var source = PhotoEditState()
        source.setFillCropOffsets(x: 0.5, y: -0.25)
        var target = PhotoEditState()
        let merged = BulkEditSupport.merge(source: source, into: target, including: [.fillCropPosition])
        XCTAssertEqual(merged.fillCropOffsetX, 0.5, accuracy: 0.0001)
        XCTAssertEqual(merged.fillCropOffsetY, -0.25, accuracy: 0.0001)
    }
}
