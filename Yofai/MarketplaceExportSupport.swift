import Foundation
import CoreGraphics
import UIKit

/// Phase 39 — where the listing is headed. Separate from pixel export canvas.
enum MarketplaceTarget: String, CaseIterable, Identifiable, Equatable, Hashable, Codable {
    case etsy = "Etsy"
    case ebay = "eBay"
    case poshmark = "Poshmark"
    case facebookMarketplace = "Facebook Marketplace"
    case mercari = "Mercari"
    case other = "Other / General"

    var id: String { rawValue }

    var displayTitle: String { rawValue }

    /// Verified Yofai pixel preset when one exists. Never invents sizes for unverified targets.
    var recommendedExportPreset: ListingExportPreset? {
        switch self {
        case .etsy: return .etsySquare
        case .ebay: return .ebay
        case .poshmark: return .poshmark
        case .facebookMarketplace, .mercari, .other: return nil
        }
    }

    var hasVerifiedYofaiCanvas: Bool {
        recommendedExportPreset != nil
    }

    /// Seller-facing guidance. Local facts only — not marketplace compliance.
    var canvasGuidance: String {
        switch self {
        case .etsy:
            return "Yofai can recommend Etsy square (2000×2000). You can still choose another export size."
        case .ebay:
            return "Yofai can recommend eBay (1600×1600). Recommended local canvas only — not a compliance guarantee."
        case .poshmark:
            return "Yofai can recommend Poshmark (1000×1000). Recommended local canvas only — not a compliance guarantee."
        case .facebookMarketplace:
            return "No fixed verified Yofai canvas for Facebook Marketplace listings. Meta’s Ads Guide lists “at least 1080×1080” for Marketplace ads — that is a minimum for ads, not an exact organic listing export size. Choose a general square canvas such as Square 1600 or Instagram square."
        case .mercari:
            return "No fixed verified Yofai canvas for Mercari. Mercari US Help does not publish an exact listing pixel size. Choose a general square canvas such as Square 1600 or Instagram square."
        case .other:
            return "Pick any local export size that fits your listing. Sizes are app presets — not marketplace compliance claims."
        }
    }

    static var `default`: MarketplaceTarget { .etsy }

    static func resolved(rawValue: String?) -> MarketplaceTarget {
        guard let rawValue, let target = MarketplaceTarget(rawValue: rawValue) else {
            return .other
        }
        return target
    }
}

extension ListingExportPreset {
    var aspectRatioLabel: String {
        let w = pixelSize.width
        let h = pixelSize.height
        guard w > 0, h > 0 else { return "—" }
        if abs(w - h) < 0.5 { return "1:1" }
        let gcd = Self.greatestCommonDivisor(Int(w.rounded()), Int(h.rounded()))
        guard gcd > 0 else { return String(format: "%.2f", w / h) }
        return "\(Int(w.rounded()) / gcd):\(Int(h.rounded()) / gcd)"
    }

    /// True when this canvas is tied to a verified marketplace recommendation in Yofai.
    var isMarketplaceVerifiedCanvas: Bool {
        switch self {
        case .etsySquare, .etsyListing, .ebay, .poshmark:
            return true
        case .instagramSquare, .facebookPost, .marketplace:
            return false
        }
    }

    var verificationLabel: String {
        isMarketplaceVerifiedCanvas
            ? "Marketplace-verified local canvas"
            : "General canvas"
    }

    private static func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var x = abs(a)
        var y = abs(b)
        while y != 0 {
            let t = x % y
            x = y
            y = t
        }
        return max(x, 1)
    }
}

/// Phase 39/42 — deterministic local export readiness (not AI, not marketplace compliance).
enum ExportReadinessStatus: String, Equatable {
    case ready = "Ready"
    case review = "Review"
    case needsAttention = "Needs Attention"
}

/// Phase 42 checklist row severity. Watermark uses `.optional` and never drives overall status.
enum ExportReadinessRowLevel: String, Equatable {
    case ready = "Ready"
    case review = "Review"
    case needsAttention = "Needs Attention"
    case optional = "Optional"
}

enum ExportReadinessRowID: String, Equatable, CaseIterable {
    case photos
    case marketplace
    case exportSize
    case fit
    case photoCheck
    case watermark
}

struct ExportReadinessItem: Equatable, Identifiable {
    var id: ExportReadinessRowID
    var title: String
    var level: ExportReadinessRowLevel
    var fact: String
    var explanation: String? = nil

    var statusLine: String {
        "\(level.rawValue) — \(fact)"
    }
}

struct ExportReadinessSummary: Equatable {
    var status: ExportReadinessStatus
    var reasons: [String]
    var items: [ExportReadinessItem]

    var overallHeadline: String {
        switch status {
        case .ready: return "Ready to export"
        case .review: return "Review before export"
        case .needsAttention: return "Needs attention"
        }
    }

    var statusLine: String {
        if reasons.isEmpty {
            return status.rawValue
        }
        return "\(status.rawValue) — \(reasons.joined(separator: "; "))"
    }

    func item(id: ExportReadinessRowID) -> ExportReadinessItem? {
        items.first { $0.id == id }
    }
}

enum ExportReadiness {
    /// Local export-focused checklist + overall status. Computed only — never persisted.
    /// Does not block export. Never claims marketplace compliance.
    static func summary(for project: ItemProject) -> ExportReadinessSummary {
        let photoStats = collectPhotoStats(for: project)
        let items = buildItems(project: project, stats: photoStats)

        var attention: [String] = []
        var review: [String] = []

        if project.sortedPhotos.isEmpty {
            attention.append("No photos yet")
        } else if photoStats.missingFiles > 0 {
            attention.append(
                photoStats.missingFiles == 1
                    ? "1 photo file missing or unreadable"
                    : "\(photoStats.missingFiles) photo files missing or unreadable"
            )
        }

        if ListingExportPreset(rawValue: project.listingExportPresetRaw) == nil {
            attention.append("Export size needs attention")
        }

        if photoStats.lowRes > 0 {
            review.append(
                photoStats.lowRes == 1
                    ? "1 photo is smaller than the export size"
                    : "\(photoStats.lowRes) photos are smaller than the export size"
            )
        }
        if photoStats.aspectMismatch > 0 {
            switch project.listingExportFitMode {
            case .containPad:
                review.append(
                    photoStats.aspectMismatch == 1
                        ? "1 photo may show padding"
                        : "\(photoStats.aspectMismatch) photos may show padding"
                )
            case .fillCrop:
                review.append(
                    photoStats.aspectMismatch == 1
                        ? "1 photo may be cropped"
                        : "\(photoStats.aspectMismatch) photos may be cropped"
                )
            }
        }
        if photoStats.cropAdjusted > 0 {
            review.append(
                photoStats.cropAdjusted == 1
                    ? "1 photo has an adjusted crop position"
                    : "\(photoStats.cropAdjusted) photos have adjusted crop positions"
            )
        }

        if !ListingQueueSupport.isReady(project) {
            review.append("Listing details need a quick check (title, price, quantity, or tags)")
        }

        let status: ExportReadinessStatus
        let reasons: [String]
        if !attention.isEmpty {
            status = .needsAttention
            reasons = attention + review
        } else if !review.isEmpty {
            status = .review
            reasons = review
        } else {
            status = .ready
            reasons = ["Photos and export settings look set for a local export"]
        }

        return ExportReadinessSummary(status: status, reasons: reasons, items: items)
    }

    // MARK: - Private

    private struct PhotoStats {
        var missingFiles = 0
        var lowRes = 0
        var aspectMismatch = 0
        var cropAdjusted = 0
        var readyCount = 0
    }

    private static func collectPhotoStats(for project: ItemProject) -> PhotoStats {
        var stats = PhotoStats()
        for photo in project.sortedPhotos {
            let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
            if !facts.filePresent || !facts.fileReadable {
                stats.missingFiles += 1
                continue
            }
            var hasReview = false
            if facts.sourceSmallerThanExportCanvas == true {
                stats.lowRes += 1
                hasReview = true
            }
            if facts.sourceAspectDiffersFromCanvas == true {
                stats.aspectMismatch += 1
                hasReview = true
            }
            if facts.fillCropPositionAdjusted == true {
                stats.cropAdjusted += 1
                hasReview = true
            }
            if !hasReview {
                stats.readyCount += 1
            }
        }
        return stats
    }

    private static func buildItems(project: ItemProject, stats: PhotoStats) -> [ExportReadinessItem] {
        let photoCount = project.sortedPhotos.count
        let photosItem: ExportReadinessItem
        if photoCount == 0 {
            photosItem = ExportReadinessItem(
                id: .photos,
                title: "Photos",
                level: .needsAttention,
                fact: "No photos",
                explanation: "Add photos before exporting."
            )
        } else if stats.missingFiles > 0 {
            photosItem = ExportReadinessItem(
                id: .photos,
                title: "Photos",
                level: .needsAttention,
                fact: "\(stats.missingFiles) file\(stats.missingFiles == 1 ? "" : "s") missing",
                explanation: "\(photoCount) photo\(photoCount == 1 ? "" : "s") in project."
            )
        } else {
            photosItem = ExportReadinessItem(
                id: .photos,
                title: "Photos",
                level: .ready,
                fact: "\(photoCount) photo\(photoCount == 1 ? "" : "s")"
            )
        }

        let market = project.listingMarketplaceTarget
        let marketplaceItem = ExportReadinessItem(
            id: .marketplace,
            title: "Marketplace",
            level: .ready,
            fact: market.displayTitle,
            explanation: market.hasVerifiedYofaiCanvas ? nil : "Guidance only — choose any valid export size."
        )

        let exportSizeItem: ExportReadinessItem
        if ListingExportPreset(rawValue: project.listingExportPresetRaw) == nil {
            exportSizeItem = ExportReadinessItem(
                id: .exportSize,
                title: "Export size",
                level: .needsAttention,
                fact: "Invalid size",
                explanation: "Pick a local export canvas."
            )
        } else {
            exportSizeItem = ExportReadinessItem(
                id: .exportSize,
                title: "Export size",
                level: .ready,
                fact: project.listingExportPreset.pixelSizeLabel
            )
        }

        let fitItem = ExportReadinessItem(
            id: .fit,
            title: "Fit",
            level: .ready,
            fact: project.listingExportFitMode.displayTitle
        )

        let photoCheckItem = photoCheckItem(project: project, stats: stats)

        let watermarkOn = project.listingWatermarkEnabled
        let watermarkItem = ExportReadinessItem(
            id: .watermark,
            title: "Watermark",
            level: .optional,
            fact: watermarkOn ? "On" : "Off"
        )

        return [photosItem, marketplaceItem, exportSizeItem, fitItem, photoCheckItem, watermarkItem]
    }

    private static func photoCheckItem(project: ItemProject, stats: PhotoStats) -> ExportReadinessItem {
        let photoCount = project.sortedPhotos.count
        if photoCount == 0 {
            return ExportReadinessItem(
                id: .photoCheck,
                title: "Photo Check",
                level: .needsAttention,
                fact: "No photos to check"
            )
        }
        if stats.missingFiles > 0 {
            return ExportReadinessItem(
                id: .photoCheck,
                title: "Photo Check",
                level: .needsAttention,
                fact: "\(stats.missingFiles) with technical issues",
                explanation: "Missing or unreadable source files."
            )
        }

        var parts: [String] = []
        if stats.readyCount > 0 {
            parts.append(
                "\(stats.readyCount) photo\(stats.readyCount == 1 ? "" : "s") ready"
            )
        }
        if stats.aspectMismatch > 0 {
            switch project.listingExportFitMode {
            case .containPad:
                parts.append(
                    "\(stats.aspectMismatch) photo\(stats.aspectMismatch == 1 ? "" : "s") may pad"
                )
            case .fillCrop:
                parts.append(
                    "\(stats.aspectMismatch) photo\(stats.aspectMismatch == 1 ? "" : "s") may crop"
                )
            }
        }
        if stats.lowRes > 0 {
            parts.append(
                "\(stats.lowRes) photo\(stats.lowRes == 1 ? "" : "s") below selected output size"
            )
        }
        if stats.cropAdjusted > 0 {
            parts.append(
                "\(stats.cropAdjusted) photo\(stats.cropAdjusted == 1 ? "" : "s") with adjusted crop"
            )
        }

        let hasReview = stats.lowRes > 0 || stats.aspectMismatch > 0 || stats.cropAdjusted > 0
        if hasReview {
            return ExportReadinessItem(
                id: .photoCheck,
                title: "Photo Check",
                level: .review,
                fact: parts.joined(separator: "; "),
                explanation: "Local framing facts only — padding or cropping can be intentional."
            )
        }

        return ExportReadinessItem(
            id: .photoCheck,
            title: "Photo Check",
            level: .ready,
            fact: "\(photoCount) photo\(photoCount == 1 ? "" : "s") ready"
        )
    }
}

enum MarketplaceExportSupport {
    /// Changes marketplace target (and optional recommended canvas) without touching photo edits.
    static func switchTarget(
        on project: ItemProject,
        to target: MarketplaceTarget,
        applyRecommendedCanvas: Bool
    ) {
        project.listingMarketplaceTarget = target
        if applyRecommendedCanvas, let preset = target.recommendedExportPreset {
            project.listingExportPreset = preset
        }
        project.touchModified()
    }
}
