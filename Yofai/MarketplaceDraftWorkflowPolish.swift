import Foundation
import SwiftData

/// Phase 64 — lightweight local-only draft overview / completion helpers.
/// Deterministic checks only. No AI, compliance, or publish claims.
enum MarketplaceDraftWorkflowCopy {
    static let readyToCopy = "Ready to copy"
    static let missingTitle = "Missing title"
    static let missingDescription = "Missing description"
    static let noPrice = "No price"
    static let addTitle = "Add title"
    static let addDescription = "Add description"
    static let addPrice = "Add price"
    static let draftBasicsComplete = "Draft basics complete"
    static let reviewBeforeManualUpload = "Review before manual upload"
    static let templateAvailable = "Template available"
    static let noSavedTemplate = "No saved template"
    static let copyShareHelper =
        "Use this text while manually creating your listing."
    static let polishLockedDetail =
        "Advanced multi-market tools are part of Yofai Pro. Your primary listing workflow and local export tools stay available."
    static let preparedForPrefix = "Prepared for"

    static var allUserFacingStrings: [String] {
        [
            readyToCopy, missingTitle, missingDescription, noPrice,
            addTitle, addDescription, addPrice, draftBasicsComplete,
            reviewBeforeManualUpload, templateAvailable, noSavedTemplate,
            copyShareHelper, polishLockedDetail, preparedForPrefix
        ]
    }
}

struct MarketplaceDraftCompletionSnapshot: Equatable {
    var hasTitle: Bool
    var hasDescription: Bool
    var hasPrice: Bool
    var hasCategoryOrCondition: Bool
    var hasMarketplaceTarget: Bool
    var hasUsablePhoto: Bool

    var isBasicsComplete: Bool {
        hasTitle && hasDescription && hasPrice && hasMarketplaceTarget
    }

    /// Single overview status line for draft list rows.
    var quickStatusLine: String {
        if !hasTitle { return MarketplaceDraftWorkflowCopy.missingTitle }
        if !hasDescription { return MarketplaceDraftWorkflowCopy.missingDescription }
        if !hasPrice { return MarketplaceDraftWorkflowCopy.noPrice }
        if isBasicsComplete { return MarketplaceDraftWorkflowCopy.readyToCopy }
        return MarketplaceDraftWorkflowCopy.reviewBeforeManualUpload
    }

    /// Editor / detail hint when basics are incomplete.
    var primaryActionHint: String {
        if !hasTitle { return MarketplaceDraftWorkflowCopy.addTitle }
        if !hasDescription { return MarketplaceDraftWorkflowCopy.addDescription }
        if !hasPrice { return MarketplaceDraftWorkflowCopy.addPrice }
        if isBasicsComplete { return MarketplaceDraftWorkflowCopy.draftBasicsComplete }
        return MarketplaceDraftWorkflowCopy.reviewBeforeManualUpload
    }

    var missingHints: [String] {
        var hints: [String] = []
        if !hasTitle { hints.append(MarketplaceDraftWorkflowCopy.addTitle) }
        if !hasDescription { hints.append(MarketplaceDraftWorkflowCopy.addDescription) }
        if !hasPrice { hints.append(MarketplaceDraftWorkflowCopy.addPrice) }
        return hints
    }
}

enum MarketplaceDraftCompletionSupport {
    static func isBlank(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func snapshot(
        for draft: MarketplaceListingDraft,
        project: ItemProject? = nil
    ) -> MarketplaceDraftCompletionSnapshot {
        let projectRef = project ?? draft.project
        let hasPhoto: Bool = {
            if let projectRef, !projectRef.sortedPhotos.isEmpty {
                return true
            }
            return !draft.orderedSelectedPhotoIDs.isEmpty
        }()

        return MarketplaceDraftCompletionSnapshot(
            hasTitle: !isBlank(draft.title),
            hasDescription: !isBlank(draft.draftDescription),
            hasPrice: !isBlank(draft.priceText),
            hasCategoryOrCondition: !isBlank(draft.category) || !isBlank(draft.condition),
            hasMarketplaceTarget: true,
            hasUsablePhoto: hasPhoto
        )
    }

    static func templateAvailabilityText(hasTemplate: Bool) -> String {
        hasTemplate
            ? MarketplaceDraftWorkflowCopy.templateAvailable
            : MarketplaceDraftWorkflowCopy.noSavedTemplate
    }

    static func preparedForLine(for draft: MarketplaceListingDraft) -> String {
        "\(MarketplaceDraftWorkflowCopy.preparedForPrefix) \(draft.marketplaceTarget.displayTitle)"
    }

    /// Pro polish entry points use the same advanced multi-market gate.
    static func canUseWorkflowPolish(state: EntitlementState) -> Bool {
        EntitlementPolicy.access(for: .advancedMultiMarketTools, state: state).allowsUse
    }
}
