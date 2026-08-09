import Foundation
import SwiftData

@Model
final class AIPreparationRecord {
    var createdAt: Date
    var statusRaw: String
    /// Selected project photo `stableID` values in project-relative request order.
    var selectedPhotoIDsData: Data?
    var suggestionTypesData: Data?
    var includedContextFieldsData: Data?
    var excludedContextFieldsData: Data?
    /// Editable local suggestions. Never stores API keys, secrets, OAuth tokens, or network payloads.
    var suggestionsData: Data?
    var errorMessage: String = ""
    var project: ItemProject?

    init(
        project: ItemProject,
        createdAt: Date = .now,
        status: AIPreparationStatus = .draft,
        selectedPhotoIDs: [UUID] = [],
        suggestionTypes: [AISuggestionType] = [],
        includedContextFields: [AIContextField] = AIContextField.allCases,
        excludedContextFields: [AIContextField] = [],
        suggestions: [AISuggestionDraft] = [],
        errorMessage: String = ""
    ) {
        self.project = project
        self.createdAt = createdAt
        self.statusRaw = status.rawValue
        self.errorMessage = errorMessage
        self.selectedPhotoIDs = selectedPhotoIDs
        self.suggestionTypes = suggestionTypes
        self.includedContextFields = includedContextFields
        self.excludedContextFields = excludedContextFields
        self.suggestions = suggestions
    }

    var status: AIPreparationStatus {
        get { AIPreparationStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var selectedPhotoIDs: [UUID] {
        get { Self.decode([UUID].self, from: selectedPhotoIDsData) ?? [] }
        set { selectedPhotoIDsData = Self.encode(newValue) }
    }

    var suggestionTypes: [AISuggestionType] {
        get { Self.decode([AISuggestionType].self, from: suggestionTypesData) ?? [] }
        set { suggestionTypesData = Self.encode(newValue) }
    }

    var includedContextFields: [AIContextField] {
        get { Self.decode([AIContextField].self, from: includedContextFieldsData) ?? [] }
        set { includedContextFieldsData = Self.encode(newValue) }
    }

    var excludedContextFields: [AIContextField] {
        get { Self.decode([AIContextField].self, from: excludedContextFieldsData) ?? [] }
        set { excludedContextFieldsData = Self.encode(newValue) }
    }

    var suggestions: [AISuggestionDraft] {
        get { Self.decode([AISuggestionDraft].self, from: suggestionsData) ?? [] }
        set { suggestionsData = Self.encode(newValue) }
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum AIListingAssistantSupport {
    static let disconnectedStatusMessage = "AI is not connected yet"

    static func contextValue(for field: AIContextField, project: ItemProject) -> String {
        switch field {
        case .title: return project.listingTitle
        case .description: return project.listingDescription
        case .price: return project.listingPriceText
        case .quantity: return String(project.listingQuantity)
        case .category: return project.listingCategory
        case .tags: return project.listingTagsRawText
        case .materials: return project.listingMaterials
        case .shippingProfile: return project.listingShippingProfile
        case .processingTime: return project.listingProcessingTime
        case .itemType: return project.listingItemType?.rawValue ?? ""
        case .condition: return project.listingCondition
        case .whoMadeIt: return project.listingWhoMadeIt
        case .whenMade: return project.listingWhenMade
        case .sku: return project.listingSKU
        case .personalization:
            if project.listingPersonalizationNotApplicable { return "N/A" }
            return project.listingPersonalizationEnabled
                ? "Enabled; limit \(project.listingPersonalizationCharacterLimitText); \(project.listingPersonalizationRequired ? "required" : "optional")"
                : "Disabled"
        case .variations:
            if project.listingVariationsNotApplicable { return "N/A" }
            return "\(project.listingVariations.count) variation(s)"
        case .attributes:
            if project.listingAttributesNotApplicable { return "N/A" }
            return "\(project.listingAttributes.count) attribute(s)"
        case .returnPolicy: return project.listingReturnPolicy
        case .photoAltTexts:
            return project.sortedPhotos.map { photo in
                let alt = photo.altTextNotApplicable ? "N/A" : photo.altText
                return "\(photo.stableID.uuidString.prefix(8)): \(alt)"
            }.joined(separator: " | ")
        }
    }

    static func makeRequestSnapshot(for record: AIPreparationRecord, project: ItemProject) -> AIPreparationRequestSnapshot {
        var values: [AIContextField: String] = [:]
        for field in record.includedContextFields where !record.excludedContextFields.contains(field) {
            values[field] = contextValue(for: field, project: project)
        }
        return AIPreparationRequestSnapshot(
            selectedPhotoIDs: record.selectedPhotoIDs,
            suggestionTypes: record.suggestionTypes,
            includedContextFields: record.includedContextFields,
            excludedContextFields: record.excludedContextFields,
            contextValues: values
        )
    }

    /// Empty editable shells — never invents AI copy. Labels as placeholder / manually entered.
    static func makePlaceholderSuggestions(
        types: [AISuggestionType],
        selectedPhotoIDs: [UUID]
    ) -> [AISuggestionDraft] {
        types.map { type in
            switch type {
            case .photoAltText:
                var map: [String: String] = [:]
                for id in selectedPhotoIDs {
                    map[id.uuidString] = ""
                }
                return AISuggestionDraft(type: type, source: .placeholderManual, altTextByPhotoID: map)
            case .photoOrderRecommendation:
                return AISuggestionDraft(
                    type: type,
                    source: .placeholderManual,
                    proposedPhotoOrderIDs: selectedPhotoIDs.map(\.uuidString)
                )
            case .tags:
                return AISuggestionDraft(type: type, source: .placeholderManual, tagsValue: [])
            default:
                return AISuggestionDraft(type: type, source: .placeholderManual, textValue: "")
            }
        }
    }

    static func photos(for ids: [UUID], in project: ItemProject) -> [ItemProjectPhoto] {
        let byID = Dictionary(uniqueKeysWithValues: project.photos.map { ($0.stableID, $0) })
        return ids.compactMap { byID[$0] }
    }

    /// Applies only approved, non-discarded suggestions for allowed fields.
    /// Photo reorder requires `confirmPhotoReorder == true`.
    /// Returns human-readable change summary. Does not touch protected fields.
    @discardableResult
    static func applyApprovedSuggestions(
        from record: AIPreparationRecord,
        to project: ItemProject,
        confirmPhotoReorder: Bool
    ) throws -> [String] {
        var changes: [String] = []
        var suggestions = record.suggestions
        let protectedSnapshot = ProtectedListingSnapshot(project: project)

        for index in suggestions.indices {
            var suggestion = suggestions[index]
            guard suggestion.isApproved, !suggestion.isDiscarded else { continue }

            switch suggestion.type {
            case .listingTitle:
                let value = suggestion.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                changes.append("Title: “\(project.listingTitle)” → “\(value)”")
                project.listingTitle = value
                suggestion.source = .applied

            case .description:
                let value = suggestion.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                changes.append("Description updated")
                project.listingDescription = value
                suggestion.source = .applied

            case .tags:
                let tags = suggestion.tagsValue
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                guard !tags.isEmpty else { continue }
                if tags.count > ItemProject.maxTagCount {
                    throw AIApplyError.tooManyTags
                }
                changes.append("Tags: \(project.listingTagsRawText) → \(tags.joined(separator: ", "))")
                project.listingTags = tags
                suggestion.source = .applied

            case .categoryText:
                let value = suggestion.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                changes.append("Category: “\(project.listingCategory)” → “\(value)”")
                project.listingCategory = value
                suggestion.source = .applied

            case .materials:
                let value = suggestion.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                changes.append("Materials: “\(project.listingMaterials)” → “\(value)”")
                project.listingMaterials = value
                suggestion.source = .applied

            case .photoAltText:
                for (idString, alt) in suggestion.altTextByPhotoID {
                    guard let uuid = UUID(uuidString: idString),
                          let photo = project.photos.first(where: { $0.stableID == uuid }) else { continue }
                    let trimmed = alt.trimmingCharacters(in: .whitespacesAndNewlines)
                    changes.append("Alt text for photo \(photo.sortOrder + 1) updated")
                    photo.altText = trimmed
                    photo.altTextNotApplicable = false
                }
                suggestion.source = .applied

            case .photoOrderRecommendation:
                guard confirmPhotoReorder else {
                    throw AIApplyError.photoReorderNeedsConfirmation
                }
                let proposed = suggestion.proposedPhotoOrderIDs.compactMap(UUID.init(uuidString:))
                guard !proposed.isEmpty else { continue }
                applyPhotoOrder(proposedIDs: proposed, to: project)
                changes.append("Photo order updated")
                suggestion.source = .applied
            }

            suggestions[index] = suggestion
        }

        try protectedSnapshot.ensureUnchanged(project)
        record.suggestions = suggestions
        if suggestions.contains(where: { $0.source == .applied }) {
            record.status = .applied
            record.errorMessage = ""
        }
        project.touchModified()
        return changes
    }

    /// Reorders project photos to match proposed IDs first, then any remaining photos in prior relative order.
    /// Keeps each photo’s alt text / edit state because identity is the photo model itself.
    static func applyPhotoOrder(proposedIDs: [UUID], to project: ItemProject) {
        let byID = Dictionary(uniqueKeysWithValues: project.photos.map { ($0.stableID, $0) })
        var ordered: [ItemProjectPhoto] = []
        var seen = Set<UUID>()
        for id in proposedIDs {
            guard let photo = byID[id], !seen.contains(id) else { continue }
            ordered.append(photo)
            seen.insert(id)
        }
        for photo in project.sortedPhotos where !seen.contains(photo.stableID) {
            ordered.append(photo)
        }
        for (index, photo) in ordered.enumerated() {
            photo.sortOrder = index
        }
    }

    @MainActor
    static func requestSuggestions(
        for record: AIPreparationRecord,
        project: ItemProject,
        provider: AIListingProviding
    ) async {
        do {
            let snapshot = makeRequestSnapshot(for: record, project: project)
            let generated = try await provider.generateSuggestions(for: snapshot)
            record.suggestions = generated
            record.status = .awaitingReview
            record.errorMessage = ""
        } catch let error as AIListingProviderError {
            record.status = .failed
            record.errorMessage = error.errorDescription ?? disconnectedStatusMessage
        } catch {
            record.status = .failed
            record.errorMessage = disconnectedStatusMessage
        }
    }
}

enum AIApplyError: Error, Equatable, LocalizedError {
    case photoReorderNeedsConfirmation
    case tooManyTags
    case protectedFieldWouldChange

    var errorDescription: String? {
        switch self {
        case .photoReorderNeedsConfirmation:
            return "Confirm the proposed photo order before applying it."
        case .tooManyTags:
            return "Tags suggestion exceeds the maximum of \(ItemProject.maxTagCount)."
        case .protectedFieldWouldChange:
            return "Apply blocked: a protected listing field would change."
        }
    }
}

/// Captures fields that must never change when applying AI suggestions.
private struct ProtectedListingSnapshot {
    let priceText: String
    let quantity: Int
    let shipping: String
    let processing: String
    let returnPolicy: String
    let returnPolicyNA: Bool
    let variationsData: Data?
    let variationsNA: Bool
    let personalizationEnabled: Bool
    let personalizationNA: Bool
    let personalizationInstructions: String
    let personalizationLimit: String
    let personalizationRequired: Bool
    let sku: String
    let skuNA: Bool
    let condition: String
    let conditionNA: Bool
    let itemTypeRaw: String
    let itemTypeNA: Bool
    let whoMade: String
    let whoMadeNA: Bool
    let whenMade: String
    let whenMadeNA: Bool
    let exportPresetRaw: String
    let exportBackgroundRaw: String
    let watermarkEnabled: Bool
    let watermarkText: String
    let queueStatuses: [String]

    init(project: ItemProject) {
        priceText = project.listingPriceText
        quantity = project.listingQuantity
        shipping = project.listingShippingProfile
        processing = project.listingProcessingTime
        returnPolicy = project.listingReturnPolicy
        returnPolicyNA = project.listingReturnPolicyNotApplicable
        variationsData = project.listingVariationsData
        variationsNA = project.listingVariationsNotApplicable
        personalizationEnabled = project.listingPersonalizationEnabled
        personalizationNA = project.listingPersonalizationNotApplicable
        personalizationInstructions = project.listingPersonalizationInstructions
        personalizationLimit = project.listingPersonalizationCharacterLimitText
        personalizationRequired = project.listingPersonalizationRequired
        sku = project.listingSKU
        skuNA = project.listingSKUNotApplicable
        condition = project.listingCondition
        conditionNA = project.listingConditionNotApplicable
        itemTypeRaw = project.listingItemTypeRaw
        itemTypeNA = project.listingItemTypeNotApplicable
        whoMade = project.listingWhoMadeIt
        whoMadeNA = project.listingWhoMadeItNotApplicable
        whenMade = project.listingWhenMade
        whenMadeNA = project.listingWhenMadeNotApplicable
        exportPresetRaw = project.listingExportPresetRaw
        exportBackgroundRaw = project.listingExportBackgroundRaw
        watermarkEnabled = project.listingWatermarkEnabled
        watermarkText = project.listingWatermarkText
        queueStatuses = project.queueEntries.map(\.statusRaw).sorted()
    }

    func ensureUnchanged(_ project: ItemProject) throws {
        let unchanged =
            project.listingPriceText == priceText
            && project.listingQuantity == quantity
            && project.listingShippingProfile == shipping
            && project.listingProcessingTime == processing
            && project.listingReturnPolicy == returnPolicy
            && project.listingReturnPolicyNotApplicable == returnPolicyNA
            && project.listingVariationsData == variationsData
            && project.listingVariationsNotApplicable == variationsNA
            && project.listingPersonalizationEnabled == personalizationEnabled
            && project.listingPersonalizationNotApplicable == personalizationNA
            && project.listingPersonalizationInstructions == personalizationInstructions
            && project.listingPersonalizationCharacterLimitText == personalizationLimit
            && project.listingPersonalizationRequired == personalizationRequired
            && project.listingSKU == sku
            && project.listingSKUNotApplicable == skuNA
            && project.listingCondition == condition
            && project.listingConditionNotApplicable == conditionNA
            && project.listingItemTypeRaw == itemTypeRaw
            && project.listingItemTypeNotApplicable == itemTypeNA
            && project.listingWhoMadeIt == whoMade
            && project.listingWhoMadeItNotApplicable == whoMadeNA
            && project.listingWhenMade == whenMade
            && project.listingWhenMadeNotApplicable == whenMadeNA
            && project.listingExportPresetRaw == exportPresetRaw
            && project.listingExportBackgroundRaw == exportBackgroundRaw
            && project.listingWatermarkEnabled == watermarkEnabled
            && project.listingWatermarkText == watermarkText
            && project.queueEntries.map(\.statusRaw).sorted() == queueStatuses
        guard unchanged else {
            throw AIApplyError.protectedFieldWouldChange
        }
    }
}
