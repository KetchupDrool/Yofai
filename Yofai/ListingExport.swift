import Foundation
import CoreGraphics
import UIKit

/// Seller-facing grouping for local export canvases (Phase 33). Does not change stored raw values.
enum ListingExportPresetGroup: String, CaseIterable, Identifiable, Equatable {
    case listing = "Listing"
    case otherCanvas = "Other canvas"

    var id: String { rawValue }
}

enum ListingExportPreset: String, CaseIterable, Identifiable, Equatable, Codable {
    /// Stored raw value — do not change existing cases (persistence).
    case etsySquare = "Etsy square"
    case etsyListing = "Etsy listing"
    case instagramSquare = "Instagram square"
    case facebookPost = "Facebook post"
    case marketplace = "Marketplace"
    /// Phase 36 — verified recommended local canvases (new raw values only).
    case ebay = "eBay"
    case poshmark = "Poshmark"

    var id: String { rawValue }

    /// Locked pixel size (width × height).
    var pixelSize: CGSize {
        switch self {
        case .etsySquare: return CGSize(width: 2000, height: 2000)
        case .etsyListing: return CGSize(width: 3000, height: 2400)
        case .instagramSquare: return CGSize(width: 1080, height: 1080)
        case .facebookPost: return CGSize(width: 1200, height: 630)
        case .marketplace: return CGSize(width: 1600, height: 1600)
        case .ebay: return CGSize(width: 1600, height: 1600)
        case .poshmark: return CGSize(width: 1000, height: 1000)
        }
    }

    /// Seller-facing title. May differ from `rawValue` for clarity (e.g. Marketplace → Square 1600).
    var displayTitle: String {
        switch self {
        case .etsySquare: return "Etsy square"
        case .etsyListing: return "Etsy listing"
        case .instagramSquare: return "Instagram square"
        case .facebookPost: return "Facebook post"
        case .marketplace: return "Square 1600"
        case .ebay: return "eBay"
        case .poshmark: return "Poshmark"
        }
    }

    var pixelSizeLabel: String {
        "\(Int(pixelSize.width))×\(Int(pixelSize.height))"
    }

    var displaySubtitle: String {
        switch self {
        case .etsySquare, .etsyListing, .instagramSquare:
            return pixelSizeLabel
        case .facebookPost:
            return "\(pixelSizeLabel) · social post canvas, not Marketplace product"
        case .marketplace:
            return "\(pixelSizeLabel) · generic square canvas"
        case .ebay:
            return "\(pixelSizeLabel) · recommended local canvas (not a compliance guarantee)"
        case .poshmark:
            return "\(pixelSizeLabel) · recommended local canvas (not a compliance guarantee)"
        }
    }

    var sellerGroup: ListingExportPresetGroup {
        switch self {
        case .etsySquare, .etsyListing, .marketplace, .ebay, .poshmark:
            return .listing
        case .instagramSquare, .facebookPost:
            return .otherCanvas
        }
    }

    /// Picker / list label with pixel size.
    var pickerLabel: String {
        "\(displayTitle) (\(pixelSizeLabel))"
    }

    /// Compact chip label for Edit export row.
    var shortLabel: String {
        switch self {
        case .etsySquare: return "Etsy □"
        case .etsyListing: return "Etsy"
        case .instagramSquare: return "IG □"
        case .facebookPost: return "FB post"
        case .marketplace: return "1600 □"
        case .ebay: return "eBay □"
        case .poshmark: return "Posh □"
        }
    }

    var accessibilityLabel: String {
        "\(displayTitle), \(displaySubtitle)"
    }

    static let localExportDisclaimer =
        "Local export canvases only. Sizes shown are app presets — not marketplace compliance claims."

    /// Original five Phase 20/33 canvases (raw values and sizes locked).
    static let legacyPhase33Presets: [ListingExportPreset] = [
        .etsySquare, .etsyListing, .instagramSquare, .facebookPost, .marketplace
    ]

    static func presets(in group: ListingExportPresetGroup) -> [ListingExportPreset] {
        allCases.filter { $0.sellerGroup == group }
    }
}

enum ListingExportBackground: String, CaseIterable, Identifiable, Equatable, Codable {
    case white = "White"
    case black = "Black"
    case softGray = "Soft gray"

    var id: String { rawValue }

    var uiColor: UIColor {
        switch self {
        case .white: return .white
        case .black: return .black
        case .softGray: return UIColor(red: 0.90, green: 0.90, blue: 0.91, alpha: 1)
        }
    }
}

/// Phase 37 — seller-selectable export fit. Supersedes Phase 20 contain+pad-only lock.
enum ListingExportFitMode: String, CaseIterable, Identifiable, Equatable, Codable {
    case containPad = "Contain + Pad"
    case fillCrop = "Fill + Crop"

    var id: String { rawValue }

    var displayTitle: String { rawValue }

    var sellerExplanation: String {
        switch self {
        case .containPad:
            return "Keeps the whole photo; may add borders."
        case .fillCrop:
            return "Fills the canvas; may crop edges."
        }
    }

    static var `default`: ListingExportFitMode { .containPad }

    /// Resolves missing/unknown stored values to Contain + Pad (backward compatible).
    static func resolved(rawValue: String?) -> ListingExportFitMode {
        guard let rawValue, let mode = ListingExportFitMode(rawValue: rawValue) else {
            return .containPad
        }
        return mode
    }
}

/// Phase 38 — normalized Fill + Crop pan within the overflow range. Center = (0, 0).
enum ListingExportFillCropPosition {
    static let minOffset: Double = -1
    static let maxOffset: Double = 1

    static func clamp(_ value: Double) -> Double {
        min(maxOffset, max(minOffset, value))
    }

    static func clampPair(x: Double, y: Double) -> (x: Double, y: Double) {
        (clamp(x), clamp(y))
    }

    /// Draw rect for fill-scale image on canvas. Offsets in -1...1 shift within valid pan only.
    static func drawRect(
        imagePixelSize: CGSize,
        canvas: CGSize,
        offsetX: Double,
        offsetY: Double
    ) -> CGRect? {
        guard imagePixelSize.width >= 1, imagePixelSize.height >= 1,
              canvas.width >= 1, canvas.height >= 1 else { return nil }

        let fill = max(canvas.width / imagePixelSize.width, canvas.height / imagePixelSize.height)
        let drawSize = CGSize(
            width: (imagePixelSize.width * fill).rounded(.down),
            height: (imagePixelSize.height * fill).rounded(.down)
        )
        guard drawSize.width >= 1, drawSize.height >= 1 else { return nil }

        let ox = clamp(offsetX)
        let oy = clamp(offsetY)
        let overflowX = max(0, drawSize.width - canvas.width)
        let overflowY = max(0, drawSize.height - canvas.height)
        let x = ((canvas.width - drawSize.width) / 2 + CGFloat(ox) * (overflowX / 2)).rounded(.down)
        let y = ((canvas.height - drawSize.height) / 2 + CGFloat(oy) * (overflowY / 2)).rounded(.down)
        return CGRect(x: x, y: y, width: drawSize.width, height: drawSize.height)
    }

    /// True when the filled image is larger than the canvas on that axis (reposition has effect).
    static func canRepositionHorizontally(imagePixelSize: CGSize, canvas: CGSize) -> Bool {
        guard let rect = drawRect(imagePixelSize: imagePixelSize, canvas: canvas, offsetX: 0, offsetY: 0) else {
            return false
        }
        return rect.width > canvas.width + 0.5
    }

    static func canRepositionVertically(imagePixelSize: CGSize, canvas: CGSize) -> Bool {
        guard let rect = drawRect(imagePixelSize: imagePixelSize, canvas: canvas, offsetX: 0, offsetY: 0) else {
            return false
        }
        return rect.height > canvas.height + 0.5
    }
}
