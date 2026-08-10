import Foundation
import SwiftData

// MARK: - Legacy SwiftData shell (Phase 51)
//
// Retained only so existing on-device stores that already contain these entities
// continue to load. There is no UI, no provider, and no AI product roadmap.
// Do not add OpenAI/API networking or listing-generation features.

@Model
final class AIPreparationRecord {
    var createdAt: Date
    var statusRaw: String
    var selectedPhotoIDsData: Data?
    var suggestionTypesData: Data?
    var includedContextFieldsData: Data?
    var excludedContextFieldsData: Data?
    var suggestionsData: Data?
    var errorMessage: String = ""
    var project: ItemProject?

    init(
        project: ItemProject,
        createdAt: Date = .now,
        statusRaw: String = LegacyListingPrepStatus.draft.rawValue,
        errorMessage: String = ""
    ) {
        self.project = project
        self.createdAt = createdAt
        self.statusRaw = statusRaw
        self.errorMessage = errorMessage
    }

    var selectedPhotoIDs: [UUID] {
        get { Self.decode([UUID].self, from: selectedPhotoIDsData) ?? [] }
        set { selectedPhotoIDsData = Self.encode(newValue) }
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

/// Stored status raw values from the retired listing-prep foundation. Not user-facing.
enum LegacyListingPrepStatus: String {
    case draft = "Draft"
    case readyForAI = "Ready for AI"
    case awaitingReview = "Awaiting Review"
    case applied = "Applied"
    case failed = "Failed"
}
