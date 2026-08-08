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
            return "Could not save a local History copy on this device."
        case .missingLocalFile:
            return "This History item’s full image is missing. The Photos copy was not deleted."
        }
    }
}

enum ImageEditing {
    private static let context = CIContext(options: nil)

    static func render(source: UIImage, state: PhotoEditState) -> UIImage? {
        let turns = state.normalizedTurns
        guard let rotated = rotate(source, quarterTurns: turns),
              var ciImage = CIImage(image: rotated) else {
            return nil
        }

        if let crop = state.cropRect {
            ciImage = cropImage(ciImage, normalizedRect: crop)
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
        return UIImage(cgImage: cgImage, scale: rotated.scale, orientation: .up)
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
