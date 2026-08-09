import Foundation

/// Suggestion types a seller can request. Local only — no live AI.
enum AISuggestionType: String, CaseIterable, Codable, Identifiable, Equatable {
    case listingTitle = "Listing title"
    case description = "Description"
    case tags = "Tags"
    case categoryText = "Category text"
    case materials = "Materials"
    case photoAltText = "Photo alt text"
    case photoOrderRecommendation = "Photo order recommendation"

    var id: String { rawValue }

    var isPhotoOrder: Bool { self == .photoOrderRecommendation }
    var isAltText: Bool { self == .photoAltText }
    var isTags: Bool { self == .tags }
}

/// Local listing fields that may be included or excluded from AI request context.
enum AIContextField: String, CaseIterable, Codable, Identifiable, Equatable {
    case title
    case description
    case price
    case quantity
    case category
    case tags
    case materials
    case shippingProfile
    case processingTime
    case itemType
    case condition
    case whoMadeIt
    case whenMade
    case sku
    case personalization
    case variations
    case attributes
    case returnPolicy
    case photoAltTexts

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .description: return "Description"
        case .price: return "Price"
        case .quantity: return "Quantity"
        case .category: return "Category"
        case .tags: return "Tags"
        case .materials: return "Materials"
        case .shippingProfile: return "Shipping profile"
        case .processingTime: return "Processing time"
        case .itemType: return "Item type"
        case .condition: return "Condition"
        case .whoMadeIt: return "Who made it"
        case .whenMade: return "When it was made"
        case .sku: return "SKU"
        case .personalization: return "Personalization"
        case .variations: return "Variations"
        case .attributes: return "Category attributes"
        case .returnPolicy: return "Return policy"
        case .photoAltTexts: return "Photo alt text"
        }
    }
}

enum AIPreparationStatus: String, CaseIterable, Codable, Equatable {
    case draft = "Draft"
    case readyForAI = "Ready for AI"
    case awaitingReview = "Awaiting Review"
    case applied = "Applied"
    case failed = "Failed"

    var displayName: String { rawValue }
}

enum AISuggestionSource: String, Codable, Equatable, CaseIterable {
    case placeholderManual = "Placeholder / manually entered"
    case futureAI = "Future AI suggestion"
    case sellerEdited = "Seller edited"
    case applied = "Applied"

    var displayName: String { rawValue }
}

struct AISuggestionDraft: Codable, Identifiable, Equatable {
    var id: UUID
    var type: AISuggestionType
    var source: AISuggestionSource
    var textValue: String
    var tagsValue: [String]
    var altTextByPhotoID: [String: String]
    var proposedPhotoOrderIDs: [String]
    var isDiscarded: Bool
    var isApproved: Bool

    init(
        id: UUID = UUID(),
        type: AISuggestionType,
        source: AISuggestionSource = .placeholderManual,
        textValue: String = "",
        tagsValue: [String] = [],
        altTextByPhotoID: [String: String] = [:],
        proposedPhotoOrderIDs: [String] = [],
        isDiscarded: Bool = false,
        isApproved: Bool = false
    ) {
        self.id = id
        self.type = type
        self.source = source
        self.textValue = textValue
        self.tagsValue = tagsValue
        self.altTextByPhotoID = altTextByPhotoID
        self.proposedPhotoOrderIDs = proposedPhotoOrderIDs
        self.isDiscarded = isDiscarded
        self.isApproved = isApproved
    }
}

enum AIListingProviderError: Error, Equatable, LocalizedError {
    case notConnected
    case unsupported

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "AI is not connected yet. No photos or listing data left this device."
        case .unsupported:
            return "This AI provider cannot generate suggestions."
        }
    }
}

/// Snapshot of a preparation used by providers. Contains no secrets or network payload objects.
struct AIPreparationRequestSnapshot: Equatable {
    var selectedPhotoIDs: [UUID]
    var suggestionTypes: [AISuggestionType]
    var includedContextFields: [AIContextField]
    var excludedContextFields: [AIContextField]
    var contextValues: [AIContextField: String]
}

/// Boundary for a future live-AI phase. Production remains disconnected.
@MainActor
protocol AIListingProviding: AnyObject {
    var isConnected: Bool { get }
    var statusMessage: String { get }
    /// Must not perform network I/O in Phase 31 production/stub implementations.
    func generateSuggestions(for request: AIPreparationRequestSnapshot) async throws -> [AISuggestionDraft]
}

/// Shipping app provider — unavailable / disconnected. Never contacts a network.
@MainActor
final class DisconnectedAIListingProvider: AIListingProviding {
    static let shared = DisconnectedAIListingProvider()

    let isConnected = false
    let statusMessage = "AI is not connected yet"

    func generateSuggestions(for request: AIPreparationRequestSnapshot) async throws -> [AISuggestionDraft] {
        _ = request
        throw AIListingProviderError.notConnected
    }
}

/// Deterministic mock for unit tests and SwiftUI previews only. No network.
@MainActor
final class MockAIListingProvider: AIListingProviding {
    var isConnected: Bool
    var statusMessage: String
    var shouldFail: Bool

    init(isConnected: Bool = true, statusMessage: String = "Mock AI (tests/previews only)", shouldFail: Bool = false) {
        self.isConnected = isConnected
        self.statusMessage = statusMessage
        self.shouldFail = shouldFail
    }

    func generateSuggestions(for request: AIPreparationRequestSnapshot) async throws -> [AISuggestionDraft] {
        if shouldFail || !isConnected {
            throw AIListingProviderError.notConnected
        }
        return request.suggestionTypes.map { type in
            switch type {
            case .listingTitle:
                return AISuggestionDraft(type: type, source: .futureAI, textValue: "Mock Title")
            case .description:
                return AISuggestionDraft(type: type, source: .futureAI, textValue: "Mock description for local review.")
            case .tags:
                return AISuggestionDraft(type: type, source: .futureAI, tagsValue: ["mock", "local", "test"])
            case .categoryText:
                return AISuggestionDraft(type: type, source: .futureAI, textValue: "Mock Category")
            case .materials:
                return AISuggestionDraft(type: type, source: .futureAI, textValue: "Mock materials")
            case .photoAltText:
                var map: [String: String] = [:]
                for (index, id) in request.selectedPhotoIDs.enumerated() {
                    map[id.uuidString] = "Mock alt \(index + 1)"
                }
                return AISuggestionDraft(type: type, source: .futureAI, altTextByPhotoID: map)
            case .photoOrderRecommendation:
                return AISuggestionDraft(
                    type: type,
                    source: .futureAI,
                    proposedPhotoOrderIDs: request.selectedPhotoIDs.reversed().map(\.uuidString)
                )
            }
        }
    }
}
