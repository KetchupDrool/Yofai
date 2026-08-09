import Foundation
import CoreGraphics

struct PhotoEditState: Equatable, Codable {
    var filter: PhotoFilter = .original
    var quarterTurns: Int = 0
    /// -0.5 ... 0.5
    var brightness: Double = 0
    /// 0.5 ... 1.5
    var contrast: Double = 1
    /// 0 ... 2
    var saturation: Double = 1
    /// Normalized crop after rotation (x, y, width, height in 0...1). nil = no crop.
    var cropRect: CGRect?
    /// Listing-ready export canvas (contain + pad).
    var exportPreset: ListingExportPreset = .etsySquare
    var exportBackground: ListingExportBackground = .white
    /// Seller watermark drawn on listing canvas after pad.
    var watermarkEnabled: Bool = false
    var watermarkText: String = ""

    static let watermarkMaxLength = 32

    var trimmedWatermarkText: String {
        watermarkText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var willDrawWatermark: Bool {
        watermarkEnabled && !trimmedWatermarkText.isEmpty
    }

    var normalizedTurns: Int {
        ((quarterTurns % 4) + 4) % 4
    }

    var didCrop: Bool {
        guard let cropRect else { return false }
        let full = CGRect(x: 0, y: 0, width: 1, height: 1)
        return cropRect.integralizedNormalized != full.integralizedNormalized
    }

    var hasAdjustments: Bool {
        abs(brightness) > 0.001 || abs(contrast - 1) > 0.001 || abs(saturation - 1) > 0.001
    }

    var hasEdits: Bool {
        filter != .original
            || normalizedTurns != 0
            || didCrop
            || hasAdjustments
            || exportPreset != .etsySquare
            || exportBackground != .white
            || watermarkEnabled
            || !trimmedWatermarkText.isEmpty
    }

    var adjustmentSummary: String {
        guard hasAdjustments else { return "None" }
        let b = Int((brightness * 100).rounded())
        let c = Int(((contrast - 1) * 100).rounded())
        let s = Int(((saturation - 1) * 100).rounded())
        return "B\(b) C\(c) S\(s)"
    }

    var listingSummary: String {
        "\(exportPreset.pickerLabel) · \(exportBackground.rawValue)"
    }

    /// Applies project-level listing frame / watermark on top of photo edits (or defaults).
    func applyingProjectExportSettings(from project: ItemProject) -> PhotoEditState {
        var copy = self
        copy.exportPreset = project.listingExportPreset
        copy.exportBackground = project.listingExportBackground
        copy.watermarkEnabled = project.listingWatermarkEnabled
        copy.watermarkText = project.listingWatermarkText
        return copy
    }

    static func centerSquareCrop() -> CGRect {
        CGRect(x: 0, y: 0, width: 1, height: 1).centerSquare
    }

    static func edgeInsetCrop(amount: CGFloat) -> CGRect {
        let inset = min(max(amount, 0), 0.4)
        let size = 1 - (inset * 2)
        return CGRect(x: inset, y: inset, width: size, height: size)
    }
}

private extension CGRect {
    var centerSquare: CGRect {
        let side = min(width, height)
        return CGRect(
            x: midX - side / 2,
            y: midY - side / 2,
            width: side,
            height: side
        )
    }

    var integralizedNormalized: CGRect {
        CGRect(
            x: (origin.x * 1000).rounded() / 1000,
            y: (origin.y * 1000).rounded() / 1000,
            width: (size.width * 1000).rounded() / 1000,
            height: (size.height * 1000).rounded() / 1000
        )
    }
}
