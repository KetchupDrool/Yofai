import Foundation
import SwiftData

/// Phase 61 — local-only marketplace listing draft (manual package prep).
/// Additive child of `ItemProject`. Does not replace Free primary listing fields on the project.
/// No upload, publish, login, or OAuth.
@Model
final class MarketplaceListingDraft {
    /// Stable identity for photo selection and tests.
    var stableID: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var marketplaceTargetRaw: String = MarketplaceTarget.other.rawValue
    /// Optional seller-facing label; empty falls back to marketplace display title + “Draft”.
    var draftLabel: String = ""
    var title: String = ""
    var draftDescription: String = ""
    var priceText: String = ""
    var quantity: Int = 1
    var category: String = ""
    var condition: String = ""
    var tags: [String] = []
    var materials: String = ""
    var shippingNotes: String = ""
    var processingTime: String = ""
    var returnsPolicy: String = ""
    var personalizationNotes: String = ""
    var marketplaceSellerNotes: String = ""
    var exportPresetRaw: String = ListingExportPreset.etsySquare.rawValue
    var exportFitModeRaw: String = ListingExportFitMode.containPad.rawValue
    var exportBackgroundRaw: String = ListingExportBackground.white.rawValue
    var watermarkEnabled: Bool = false
    var watermarkText: String = ""
    /// `ItemProjectPhoto.stableID` UUID strings in seller order. Empty = use all project photos later.
    var orderedSelectedPhotoIDStrings: [String] = []
    var project: ItemProject?

    init(
        marketplaceTarget: MarketplaceTarget,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        project: ItemProject? = nil
    ) {
        self.stableID = UUID()
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.marketplaceTargetRaw = marketplaceTarget.rawValue
        self.project = project
        if let recommended = marketplaceTarget.recommendedExportPreset {
            self.exportPresetRaw = recommended.rawValue
        }
    }

    var marketplaceTarget: MarketplaceTarget {
        get { MarketplaceTarget.resolved(rawValue: marketplaceTargetRaw) }
        set {
            marketplaceTargetRaw = newValue.rawValue
            touchUpdated()
        }
    }

    var exportPreset: ListingExportPreset {
        get { ListingExportPreset(rawValue: exportPresetRaw) ?? .etsySquare }
        set {
            exportPresetRaw = newValue.rawValue
            touchUpdated()
        }
    }

    var exportFitMode: ListingExportFitMode {
        get { ListingExportFitMode.resolved(rawValue: exportFitModeRaw) }
        set {
            exportFitModeRaw = newValue.rawValue
            touchUpdated()
        }
    }

    var exportBackground: ListingExportBackground {
        get { ListingExportBackground(rawValue: exportBackgroundRaw) ?? .white }
        set {
            exportBackgroundRaw = newValue.rawValue
            touchUpdated()
        }
    }

    var displayTitle: String {
        let custom = draftLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return "\(marketplaceTarget.displayTitle) Draft"
    }

    var listingTitleOrPlaceholder: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled draft" : trimmed
    }

    var orderedSelectedPhotoIDs: [UUID] {
        get {
            orderedSelectedPhotoIDStrings.compactMap { UUID(uuidString: $0) }
        }
        set {
            orderedSelectedPhotoIDStrings = newValue.map(\.uuidString)
            touchUpdated()
        }
    }

    func touchUpdated() {
        updatedAt = .now
    }
}
