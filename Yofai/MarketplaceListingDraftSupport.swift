import Foundation
import SwiftData

/// Phase 61–62 — marketplace draft helpers, freemium gates, and safe copy.
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
    /// Phase 62 — draft-aware copy / share (text package; JPEG package files remain primary-workflow).
    static let copyToolsSectionTitle = "Draft listing package"
    static let copyListingText = "Copy listing text"
    static let copyDraftDetails = "Copy draft details"
    static let shareListingText = "Share listing text"
    static let copyFieldMenuTitle = "Copy field"
    static let copiedFeedback = "Copied"
    static let packageToolsLockedDetail =
        "Draft-specific copy and share tools are advanced multi-market tools in Yofai Pro. Free keeps your primary listing package and local JPEG export."
    static let manualUploadFooter =
        "Manual listing package text for copy/share. Seller uploads outside the app."

    static var allUserFacingStrings: [String] {
        [
            sectionTitle, preparePackagesLine, primaryDraftTitle, primaryDraftDetail,
            additionalDraftsHeader, proLockedTitle, proLockedDetail, createDraftTitle,
            duplicateTargetMessage, manualPackageReminder, openPrimaryWorkspace,
            editDraft, draftSaved, copyToolsSectionTitle, copyListingText, copyDraftDetails,
            shareListingText, copyFieldMenuTitle, copiedFeedback, packageToolsLockedDetail,
            manualUploadFooter
        ] + MarketplaceDraftCopyField.allCases.map(\.buttonTitle)
    }
}

enum MarketplaceListingDraftSupport {
    /// Pro-only: create/edit additional marketplace drafts beyond the Free primary workflow.
    static func canManageAdditionalDrafts(state: EntitlementState) -> Bool {
        EntitlementPolicy.access(for: .advancedMultiMarketTools, state: state).allowsUse
    }

    /// Phase 62 — draft-specific package/copy tools use the same advanced multi-market gate.
    static func canUseDraftPackageTools(state: EntitlementState) -> Bool {
        canManageAdditionalDrafts(state: state)
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

/// Phase 62 — individual draft field copy targets (clipboard).
enum MarketplaceDraftCopyField: String, CaseIterable, Identifiable {
    case title
    case description
    case price
    case quantity
    case category
    case condition
    case tags
    case materials
    case shippingNotes
    case processingTime
    case returnsPolicy
    case personalization
    case marketplaceSellerNotes
    case allListingText

    var id: String { rawValue }

    var buttonTitle: String {
        switch self {
        case .title: return "Copy title"
        case .description: return "Copy description"
        case .price: return "Copy price"
        case .quantity: return "Copy quantity"
        case .category: return "Copy category"
        case .condition: return "Copy condition"
        case .tags: return "Copy tags"
        case .materials: return "Copy materials"
        case .shippingNotes: return "Copy shipping notes"
        case .processingTime: return "Copy processing time"
        case .returnsPolicy: return "Copy returns policy"
        case .personalization: return "Copy personalization"
        case .marketplaceSellerNotes: return "Copy marketplace seller notes"
        case .allListingText: return MarketplaceListingDraftCopy.copyDraftDetails
        }
    }
}

/// Phase 62 — draft-aware manual listing package text and field copy.
/// Does not create JPEG package folders; primary `ListingPackage` workflow stays on ItemProject.
enum MarketplaceDraftPackageSupport {
    static let manualUploadNote =
        "Manual listing package — Local JPEGs for manual upload outside the app."

    /// Listing-details text from draft fields only (never ItemProject listing*).
    static func listingDetailsText(for draft: MarketplaceListingDraft) -> String {
        let tags = draft.tags.joined(separator: ", ")
        return """
        Prepared for: \(draft.marketplaceTarget.displayTitle)
        Draft: \(draft.displayTitle)
        Title: \(draft.title)
        Description: \(draft.draftDescription)
        Price: \(draft.priceText)
        Quantity: \(draft.quantity)
        Category: \(draft.category)
        Condition: \(draft.condition)
        Tags: \(tags)
        Materials: \(draft.materials)
        Shipping notes: \(draft.shippingNotes)
        Processing time: \(draft.processingTime)
        Returns policy: \(draft.returnsPolicy)
        Personalization: \(draft.personalizationNotes)
        Marketplace seller notes: \(draft.marketplaceSellerNotes)
        \(manualUploadNote)
        """
    }

    static func copyableText(for field: MarketplaceDraftCopyField, draft: MarketplaceListingDraft) -> String {
        switch field {
        case .title:
            return draft.title
        case .description:
            return draft.draftDescription
        case .price:
            return draft.priceText
        case .quantity:
            return String(draft.quantity)
        case .category:
            return draft.category
        case .condition:
            return draft.condition
        case .tags:
            return draft.tags.joined(separator: ", ")
        case .materials:
            return draft.materials
        case .shippingNotes:
            return draft.shippingNotes
        case .processingTime:
            return draft.processingTime
        case .returnsPolicy:
            return draft.returnsPolicy
        case .personalization:
            return draft.personalizationNotes
        case .marketplaceSellerNotes:
            return draft.marketplaceSellerNotes
        case .allListingText:
            return listingDetailsText(for: draft)
        }
    }

    /// Pro gate for draft package/copy entry points.
    static func canUse(state: EntitlementState) -> Bool {
        MarketplaceListingDraftSupport.canUseDraftPackageTools(state: state)
    }
}
