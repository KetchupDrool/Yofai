import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

enum PhotoFilter: String, CaseIterable, Identifiable {
    case original = "Original"
    case mono = "Mono"
    case sepia = "Sepia"
    case vivid = "Vivid"

    var id: String { rawValue }
}

enum PhotoSaveError: LocalizedError {
    case permissionDenied
    case renderFailed
    case saveFailed
    case loadFailed
    case localSaveFailed
    case missingLocalFile
    case cropFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photos access was denied. Allow adding photos in Settings to save a copy."
        case .renderFailed:
            return "Could not prepare the edited image."
        case .saveFailed:
            return "Could not save the photo. Please try again."
        case .loadFailed:
            return "Could not load that photo. Try choosing a different image."
        case .localSaveFailed:
            return "Could not save a local copy on this device. You can still edit this photo for now."
        case .missingLocalFile:
            return "This image file is missing from Yofai. Your Photos library was not changed."
        case .cropFailed:
            return "Could not apply that crop. Try a larger crop area."
        }
    }
}

enum ImageEditing {
    private static let context = CIContext(options: nil)

    /// Longest side for on-screen edit preview / crop canvas (points×scale not required).
    static let previewMaxDimension: CGFloat = 1600

    /// Full-quality listing-ready render for Save Listing Copy / Share.
    static func render(source: UIImage, state: PhotoEditState) -> UIImage? {
        guard let edited = renderPipeline(source: source, state: state) else { return nil }
        return applyListingFrame(
            edited,
            preset: state.exportPreset,
            background: state.exportBackground,
            watermarkEnabled: state.watermarkEnabled,
            watermarkText: state.watermarkText,
            maxDimension: nil
        )
    }

    /// Faster on-screen preview; may downscale large sources first, then frame to a capped canvas.
    static func renderPreview(source: UIImage, state: PhotoEditState) -> UIImage? {
        let previewSource = downscaled(source, maxDimension: previewMaxDimension)
        guard let edited = renderPipeline(source: previewSource, state: state) else { return nil }
        return applyListingFrame(
            edited,
            preset: state.exportPreset,
            background: state.exportBackground,
            watermarkEnabled: state.watermarkEnabled,
            watermarkText: state.watermarkText,
            maxDimension: previewMaxDimension
        )
    }

    /// Rotated source for freeform crop UI; downscaled so large photos stay responsive.
    static func imageForCropping(source: UIImage, quarterTurns: Int) -> UIImage? {
        let normalized = normalizedOrientation(source)
        let turns = ((quarterTurns % 4) + 4) % 4
        guard let rotated = rotate(normalized, quarterTurns: turns) else { return nil }
        return downscaled(rotated, maxDimension: previewMaxDimension)
    }

    /// Bakes `imageOrientation` into pixel data so preview and full Save/Share match.
    /// Does not apply user quarter-turn edits — call before rotate/crop/filter.
    static func normalizedOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// Returns `image` unchanged when already within `maxDimension` (after orientation normalize).
    static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let image = normalizedOrientation(image)
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        guard longest > maxDimension, pixelWidth > 0, pixelHeight > 0 else {
            return image
        }

        let scale = maxDimension / longest
        let target = CGSize(
            width: (image.size.width * scale).rounded(.down),
            height: (image.size.height * scale).rounded(.down)
        )
        guard target.width >= 1, target.height >= 1 else { return image }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private static func renderPipeline(source: UIImage, state: PhotoEditState) -> UIImage? {
        // Full Save uses the original import UIImage; preview often already drew via downscale.
        // Normalize first so EXIF orientation cannot diverge between those paths.
        let source = normalizedOrientation(source)
        let turns = state.normalizedTurns
        guard let rotated = rotate(source, quarterTurns: turns),
              var ciImage = CIImage(image: rotated) else {
            return nil
        }

        if let crop = state.cropRect {
            let normalized = clampNormalizedCrop(crop)
            guard normalized.width > 0.02, normalized.height > 0.02 else {
                return nil
            }
            ciImage = cropImage(ciImage, normalizedRect: normalized)
        }

        ciImage = applyAdjustments(
            to: ciImage,
            brightness: Float(state.brightness),
            contrast: Float(state.contrast),
            saturation: Float(state.saturation)
        )

        ciImage = apply(state.filter, to: ciImage)

        let extent = ciImage.extent.integral
        guard extent.width > 1, extent.height > 1,
              let cgImage = context.createCGImage(ciImage, from: extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    /// Contain + pad onto locked listing canvas. Optional `maxDimension` caps preview canvases.
    /// Watermark is drawn after pad when enabled with non-empty trimmed text.
    static func applyListingFrame(
        _ image: UIImage,
        preset: ListingExportPreset,
        background: ListingExportBackground,
        watermarkEnabled: Bool,
        watermarkText: String,
        maxDimension: CGFloat?
    ) -> UIImage? {
        let canvas = listingCanvasSize(for: preset, maxDimension: maxDimension)
        guard canvas.width >= 1, canvas.height >= 1 else { return nil }

        let imagePixelSize = CGSize(
            width: max(1, image.size.width * image.scale),
            height: max(1, image.size.height * image.scale)
        )
        let fit = min(canvas.width / imagePixelSize.width, canvas.height / imagePixelSize.height)
        let drawSize = CGSize(
            width: (imagePixelSize.width * fit).rounded(.down),
            height: (imagePixelSize.height * fit).rounded(.down)
        )
        guard drawSize.width >= 1, drawSize.height >= 1 else { return nil }

        let origin = CGPoint(
            x: ((canvas.width - drawSize.width) / 2).rounded(.down),
            y: ((canvas.height - drawSize.height) / 2).rounded(.down)
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)
        return renderer.image { _ in
            background.uiColor.setFill()
            UIRectFill(CGRect(origin: .zero, size: canvas))
            image.draw(in: CGRect(origin: origin, size: drawSize))
            drawWatermarkIfNeeded(
                text: watermarkText,
                enabled: watermarkEnabled,
                background: background,
                canvas: canvas
            )
        }
    }

    private static func drawWatermarkIfNeeded(
        text: String,
        enabled: Bool,
        background: ListingExportBackground,
        canvas: CGSize
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard enabled, !trimmed.isEmpty else { return }

        let limited: String
        if trimmed.count > PhotoEditState.watermarkMaxLength {
            limited = String(trimmed.prefix(PhotoEditState.watermarkMaxLength))
        } else {
            limited = trimmed
        }

        let side = min(canvas.width, canvas.height)
        let fontSize = max(12, (side * 0.028).rounded())
        let margin = max(8, (side * 0.03).rounded())
        let color: UIColor = {
            switch background {
            case .black:
                return UIColor.white.withAlphaComponent(0.92)
            case .white, .softGray:
                return UIColor.black.withAlphaComponent(0.72)
            }
        }()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: color
        ]
        let nsText = limited as NSString
        let textSize = nsText.size(withAttributes: attributes)
        let point = CGPoint(
            x: max(margin, canvas.width - textSize.width - margin),
            y: max(margin, canvas.height - textSize.height - margin)
        )
        nsText.draw(at: point, withAttributes: attributes)
    }

    static func listingCanvasSize(for preset: ListingExportPreset, maxDimension: CGFloat?) -> CGSize {
        var width = preset.pixelSize.width
        var height = preset.pixelSize.height
        if let maxDimension {
            let longest = max(width, height)
            if longest > maxDimension {
                let scale = maxDimension / longest
                width = (width * scale).rounded(.down)
                height = (height * scale).rounded(.down)
            }
        }
        return CGSize(width: max(1, width), height: max(1, height))
    }

    static func clampNormalizedCrop(_ rect: CGRect) -> CGRect {
        var x = max(0, min(rect.origin.x, 1))
        var y = max(0, min(rect.origin.y, 1))
        var w = max(0.05, min(rect.width, 1 - x))
        var h = max(0.05, min(rect.height, 1 - y))
        if x + w > 1 { x = max(0, 1 - w) }
        if y + h > 1 { y = max(0, 1 - h) }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoSaveError.permissionDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw PhotoSaveError.saveFailed
        }
    }

    private static func cropImage(_ image: CIImage, normalizedRect: CGRect) -> CIImage {
        let extent = image.extent
        let rect = CGRect(
            x: extent.minX + normalizedRect.minX * extent.width,
            y: extent.minY + (1 - normalizedRect.maxY) * extent.height,
            width: normalizedRect.width * extent.width,
            height: normalizedRect.height * extent.height
        ).integral
        return image.cropped(to: rect).transformed(by: CGAffineTransform(
            translationX: -rect.origin.x,
            y: -rect.origin.y
        ))
    }

    private static func applyAdjustments(
        to image: CIImage,
        brightness: Float,
        contrast: Float,
        saturation: Float
    ) -> CIImage {
        let controls = CIFilter.colorControls()
        controls.inputImage = image
        controls.brightness = brightness
        controls.contrast = contrast
        controls.saturation = saturation
        return controls.outputImage ?? image
    }

    private static func apply(_ filter: PhotoFilter, to image: CIImage) -> CIImage {
        switch filter {
        case .original:
            return image
        case .mono:
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = image
            return mono.outputImage ?? image
        case .sepia:
            let sepia = CIFilter.sepiaTone()
            sepia.inputImage = image
            sepia.intensity = 0.8
            return sepia.outputImage ?? image
        case .vivid:
            let controls = CIFilter.colorControls()
            controls.inputImage = image
            controls.contrast = 1.15
            controls.saturation = 1.25
            controls.brightness = 0.01
            return controls.outputImage ?? image
        }
    }

    private static func rotate(_ image: UIImage, quarterTurns: Int) -> UIImage? {
        guard quarterTurns != 0 else { return image }

        let radians = CGFloat(quarterTurns) * (.pi / 2)
        let originalSize = image.size
        var newSize = originalSize
        if quarterTurns % 2 != 0 {
            newSize = CGSize(width: originalSize.height, height: originalSize.width)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            let cg = context.cgContext
            cg.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            cg.rotate(by: radians)
            image.draw(in: CGRect(
                x: -originalSize.width / 2,
                y: -originalSize.height / 2,
                width: originalSize.width,
                height: originalSize.height
            ))
        }
    }
}
