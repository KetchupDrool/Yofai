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
    /// Listing-ready export canvas.
    var exportPreset: ListingExportPreset = .etsySquare
    var exportBackground: ListingExportBackground = .white
    /// Phase 37 — contain+pad (default) or fill+crop.
    var exportFitMode: ListingExportFitMode = .containPad
    /// Phase 38 — Fill + Crop pan (-1...1). Ignored for Contain + Pad. Missing → centered (0).
    var fillCropOffsetX: Double = 0
    var fillCropOffsetY: Double = 0
    /// Seller watermark drawn on listing canvas after framing.
    var watermarkEnabled: Bool = false
    var watermarkText: String = ""

    static let watermarkMaxLength = 32

    enum CodingKeys: String, CodingKey {
        case filter
        case quarterTurns
        case brightness
        case contrast
        case saturation
        case cropRect
        case exportPreset
        case exportBackground
        case exportFitMode
        case fillCropOffsetX
        case fillCropOffsetY
        case watermarkEnabled
        case watermarkText
    }

    init(
        filter: PhotoFilter = .original,
        quarterTurns: Int = 0,
        brightness: Double = 0,
        contrast: Double = 1,
        saturation: Double = 1,
        cropRect: CGRect? = nil,
        exportPreset: ListingExportPreset = .etsySquare,
        exportBackground: ListingExportBackground = .white,
        exportFitMode: ListingExportFitMode = .containPad,
        fillCropOffsetX: Double = 0,
        fillCropOffsetY: Double = 0,
        watermarkEnabled: Bool = false,
        watermarkText: String = ""
    ) {
        self.filter = filter
        self.quarterTurns = quarterTurns
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.cropRect = cropRect
        self.exportPreset = exportPreset
        self.exportBackground = exportBackground
        self.exportFitMode = exportFitMode
        let clamped = ListingExportFillCropPosition.clampPair(x: fillCropOffsetX, y: fillCropOffsetY)
        self.fillCropOffsetX = clamped.x
        self.fillCropOffsetY = clamped.y
        self.watermarkEnabled = watermarkEnabled
        self.watermarkText = watermarkText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filter = try container.decodeIfPresent(PhotoFilter.self, forKey: .filter) ?? .original
        quarterTurns = try container.decodeIfPresent(Int.self, forKey: .quarterTurns) ?? 0
        brightness = try container.decodeIfPresent(Double.self, forKey: .brightness) ?? 0
        contrast = try container.decodeIfPresent(Double.self, forKey: .contrast) ?? 1
        saturation = try container.decodeIfPresent(Double.self, forKey: .saturation) ?? 1
        cropRect = try container.decodeIfPresent(CGRect.self, forKey: .cropRect)
        exportPreset = try container.decodeIfPresent(ListingExportPreset.self, forKey: .exportPreset) ?? .etsySquare
        exportBackground = try container.decodeIfPresent(ListingExportBackground.self, forKey: .exportBackground) ?? .white
        exportFitMode = try container.decodeIfPresent(ListingExportFitMode.self, forKey: .exportFitMode) ?? .containPad
        let ox = try container.decodeIfPresent(Double.self, forKey: .fillCropOffsetX) ?? 0
        let oy = try container.decodeIfPresent(Double.self, forKey: .fillCropOffsetY) ?? 0
        let clamped = ListingExportFillCropPosition.clampPair(x: ox, y: oy)
        fillCropOffsetX = clamped.x
        fillCropOffsetY = clamped.y
        watermarkEnabled = try container.decodeIfPresent(Bool.self, forKey: .watermarkEnabled) ?? false
        watermarkText = try container.decodeIfPresent(String.self, forKey: .watermarkText) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        try container.encode(quarterTurns, forKey: .quarterTurns)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(contrast, forKey: .contrast)
        try container.encode(saturation, forKey: .saturation)
        try container.encodeIfPresent(cropRect, forKey: .cropRect)
        try container.encode(exportPreset, forKey: .exportPreset)
        try container.encode(exportBackground, forKey: .exportBackground)
        try container.encode(exportFitMode, forKey: .exportFitMode)
        try container.encode(fillCropOffsetX, forKey: .fillCropOffsetX)
        try container.encode(fillCropOffsetY, forKey: .fillCropOffsetY)
        try container.encode(watermarkEnabled, forKey: .watermarkEnabled)
        try container.encode(watermarkText, forKey: .watermarkText)
    }

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

    var hasFillCropReposition: Bool {
        abs(fillCropOffsetX) > 0.0001 || abs(fillCropOffsetY) > 0.0001
    }

    var isFillCropCentered: Bool {
        !hasFillCropReposition
    }

    mutating func resetFillCropPosition() {
        fillCropOffsetX = 0
        fillCropOffsetY = 0
    }

    mutating func setFillCropOffsets(x: Double, y: Double) {
        let clamped = ListingExportFillCropPosition.clampPair(x: x, y: y)
        fillCropOffsetX = clamped.x
        fillCropOffsetY = clamped.y
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
            || exportFitMode != .containPad
            || hasFillCropReposition
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
        "\(exportPreset.pickerLabel) · \(exportFitMode.displayTitle) · \(exportBackground.rawValue)"
    }

    /// Applies project-level listing frame / watermark on top of photo edits (or defaults).
    /// Preserves per-photo Fill + Crop offsets (Phase 38).
    func applyingProjectExportSettings(from project: ItemProject) -> PhotoEditState {
        var copy = self
        copy.exportPreset = project.listingExportPreset
        copy.exportBackground = project.listingExportBackground
        copy.exportFitMode = project.listingExportFitMode
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
