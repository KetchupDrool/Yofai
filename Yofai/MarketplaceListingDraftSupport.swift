import Foundation
import SwiftData

/// Phase 61 — marketplace draft helpers, freemium gates, and safe copy.
/// Manual listing packages only. No Direct Upload / publish / login / OAuth.
enum MarketplaceListingDraftCopy {
    static let sectionTitle = "Marketplace Drafts"
    static let preparePackagesLine =
        "Prepare listing packages for Etsy, eBay, Facebook Marketplace, Mercari, Poshmark, and more."
    static let primaryDraftTitle = "Primary Draft"
    static let primaryDraftDetail =
        "Current listing workflow on this product. Free includes prepare, local JPEG export, and manual upload outside the app."
    static let additionalDraftsHeader = "Additional marketplace drafts"
    static let proLockedTitle = "Advanced multi-market tools"
    static let proLockedDetail =
        "Yofai Pro unlocks multiple marketplace drafts per product so you can reuse one product across Etsy, eBay, Facebook Marketplace, Mercari, Poshmark, and more. Free keeps your primary listing workflow."
    static let createDraftTitle = "New marketplace draft"
    static let duplicateTargetMessage =
        "This product already has a draft for that marketplace."
    static let manualPackageReminder =
        "Drafts are for manual listing packages — Local JPEGs you upload yourself."
    static let openPrimaryWorkspace = "Open Prepare Listing & Export"
    static let editDraft = "Edit draft"
    static let draftSaved = "Draft saved"

    static var allUserFacingStrings: [String] {
        [
            sectionTitle, preparePackagesLine, primaryDraftTitle, primaryDraftDetail,
            additionalDraftsHeader, proLockedTitle, proLockedDetail, createDraftTitle,
            duplicateTargetMessage, manualPackageReminder, openPrimaryWorkspace,
            editDraft, draftSaved
        ]
    }
}

enum MarketplaceListingDraftSupport {
    /// Pro-only: create/edit additional marketplace drafts beyond the Free primary workflow.
    static func canManageAdditionalDrafts(state: EntitlementState) -> Bool {
        EntitlementPolicy.access(for: .advancedMultiMarketTools, state: state).allowsUse
    }

    static func sortedDrafts(on project: ItemProject) -> [MarketplaceListingDraft] {
        project.marketplaceDrafts.sorted { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    static func existingDraft(for target: MarketplaceTarget, on project: ItemProject) -> MarketplaceListingDraft? {
        project.marketplaceDrafts.first { $0.marketplaceTarget == target }
    }

    /// One draft per marketplace per product for Phase 61.
    static func canCreateDraft(for target: MarketplaceTarget, on project: ItemProject) -> Bool {
        existingDraft(for: target, on: project) == nil
    }

    /// Creates an additive draft. Copies listing/export fields from the Free primary `ItemProject` fields — never clears them.
    @discardableResult
    static func createDraft(
        for target: MarketplaceTarget,
        on project: ItemProject,
        in context: ModelContext,
        state: EntitlementState
    ) throws -> MarketplaceListingDraft {
        guard canManageAdditionalDrafts(state: state) else {
            throw MarketplaceListingDraftError.proRequired
        }
        guard canCreateDraft(for: target, on: project) else {
            throw MarketplaceListingDraftError.duplicateMarketplace
        }

        let draft = MarketplaceListingDraft(marketplaceTarget: target, project: project)
        copyPrimaryListingFields(from: project, into: draft)
        draft.orderedSelectedPhotoIDs = project.sortedPhotos.map(\.stableID)
        context.insert(draft)
        project.marketplaceDrafts.append(draft)
        project.touchModified()
        return draft
    }

    /// Copy-only seed from Free primary fields. Does not move or clear `ItemProject` listing data.
    static func copyPrimaryListingFields(from project: ItemProject, into draft: MarketplaceListingDraft) {
        draft.title = project.listingTitle
        draft.draftDescription = project.listingDescription
        draft.priceText = project.listingPriceText
        draft.quantity = project.listingQuantity
        draft.category = project.listingCategory
        draft.condition = project.listingCondition
        draft.tags = project.listingTags
        draft.materials = project.listingMaterials
        draft.shippingNotes = project.listingShippingProfile
        draft.processingTime = project.listingProcessingTime
        draft.returnsPolicy = project.listingReturnPolicy
        draft.personalizationNotes = project.listingPersonalizationInstructions
        draft.exportPresetRaw = project.listingExportPresetRaw
        draft.exportFitModeRaw = project.listingExportFitModeRaw
        draft.exportBackgroundRaw = project.listingExportBackgroundRaw
        draft.watermarkEnabled = project.listingWatermarkEnabled
        draft.watermarkText = project.listingWatermarkText
        // Prefer recommended canvas when target has one and primary was a different market.
        if let recommended = draft.marketplaceTarget.recommendedExportPreset {
            draft.exportPresetRaw = recommended.rawValue
        }
        draft.touchUpdated()
    }

    static func availableTargetsForNewDraft(on project: ItemProject) -> [MarketplaceTarget] {
        MarketplaceTarget.allCases.filter { canCreateDraft(for: $0, on: project) }
    }
}

enum MarketplaceListingDraftError: Error, Equatable {
    case proRequired
    case duplicateMarketplace
}
