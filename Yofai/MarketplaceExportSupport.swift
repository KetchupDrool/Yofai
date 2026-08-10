import Foundation
import CoreGraphics
import UIKit

/// Phase 39 — where the listing is headed. Separate from pixel export canvas.
enum MarketplaceTarget: String, CaseIterable, Identifiable, Equatable, Codable {
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

/// Phase 39 — deterministic local export readiness (not AI, not marketplace compliance).
enum ExportReadinessStatus: String, Equatable {
    case ready = "Ready"
    case review = "Review"
    case needsAttention = "Needs Attention"
}

struct ExportReadinessSummary: Equatable {
    var status: ExportReadinessStatus
    var reasons: [String]

    var statusLine: String {
        if reasons.isEmpty {
            return status.rawValue
        }
        return "\(status.rawValue) — \(reasons.joined(separator: "; "))"
    }
}

enum ExportReadiness {
    /// Local export-focused summary. Does not block export. Never claims compliance.
    static func summary(for project: ItemProject) -> ExportReadinessSummary {
        var attention: [String] = []
        var review: [String] = []

        let photos = project.sortedPhotos
        if photos.isEmpty {
            attention.append("No photos yet")
        } else {
            var missingFiles = 0
            var lowRes = 0
            var aspectMismatch = 0
            var cropAdjusted = 0

            for photo in photos {
                let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
                if !facts.filePresent || !facts.fileReadable {
                    missingFiles += 1
                    continue
                }
                if facts.sourceSmallerThanExportCanvas == true {
                    lowRes += 1
                }
                if facts.sourceAspectDiffersFromCanvas == true {
                    aspectMismatch += 1
                }
                if facts.fillCropPositionAdjusted == true {
                    cropAdjusted += 1
                }
            }

            if missingFiles > 0 {
                attention.append(
                    missingFiles == 1
                        ? "1 photo file missing or unreadable"
                        : "\(missingFiles) photo files missing or unreadable"
                )
            }
            if lowRes > 0 {
                review.append(
                    lowRes == 1
                        ? "1 photo is smaller than the export size"
                        : "\(lowRes) photos are smaller than the export size"
                )
            }
            if aspectMismatch > 0 {
                switch project.listingExportFitMode {
                case .containPad:
                    review.append(
                        aspectMismatch == 1
                            ? "1 photo may show padding"
                            : "\(aspectMismatch) photos may show padding"
                    )
                case .fillCrop:
                    review.append(
                        aspectMismatch == 1
                            ? "1 photo may be cropped"
                            : "\(aspectMismatch) photos may be cropped"
                    )
                }
            }
            if cropAdjusted > 0 {
                review.append(
                    cropAdjusted == 1
                        ? "1 photo has an adjusted crop position"
                        : "\(cropAdjusted) photos have adjusted crop positions"
                )
            }
        }

        if !ListingQueueSupport.isReady(project) {
            review.append("Listing details need a quick check (title, price, quantity, or tags)")
        }

        if !attention.isEmpty {
            return ExportReadinessSummary(status: .needsAttention, reasons: attention + review)
        }
        if !review.isEmpty {
            return ExportReadinessSummary(status: .review, reasons: review)
        }
        return ExportReadinessSummary(status: .ready, reasons: ["Photos and export settings look set for a local export"])
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
