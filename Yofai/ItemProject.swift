import Foundation
import SwiftData
import UIKit

@Model
final class ItemProject {
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ItemProjectPhoto.project)
    var photos: [ItemProjectPhoto]
    @Relationship(deleteRule: .cascade, inverse: \ListingQueueEntry.project)
    var queueEntries: [ListingQueueEntry] = []
    @Relationship(deleteRule: .cascade, inverse: \ProjectExportBatch.project)
    var exportBatches: [ProjectExportBatch] = []
    @Relationship(deleteRule: .cascade, inverse: \ListingPackage.project)
    var listingPackages: [ListingPackage] = []

    // Local Etsy listing draft fields (Phase 23). No API/upload.
    var listingTitle: String = ""
    var listingDescription: String = ""
    /// User-entered price text; validated as nonnegative amount on save.
    var listingPriceText: String = ""
    var listingQuantity: Int = 1
    var listingCategory: String = ""
    var listingTags: [String] = []
    var listingMaterials: String = ""
    var listingShippingProfile: String = ""
    var listingProcessingTime: String = ""

    // Local listing information (Phase 30). Not Etsy-ready certification.
    var listingItemTypeRaw: String = ""
    var listingItemTypeNotApplicable: Bool = false
    var listingCondition: String = ""
    var listingConditionNotApplicable: Bool = false
    var listingWhoMadeIt: String = ""
    var listingWhoMadeItNotApplicable: Bool = false
    var listingWhenMade: String = ""
    var listingWhenMadeNotApplicable: Bool = false
    var listingSKU: String = ""
    var listingSKUNotApplicable: Bool = false

    var listingPersonalizationEnabled: Bool = false
    var listingPersonalizationNotApplicable: Bool = false
    var listingPersonalizationInstructions: String = ""
    var listingPersonalizationInstructionsNotApplicable: Bool = false
    var listingPersonalizationCharacterLimitText: String = ""
    var listingPersonalizationRequired: Bool = false

    var listingVariationsNotApplicable: Bool = false
    var listingVariationsData: Data?

    var listingAttributesNotApplicable: Bool = false
    var listingAttributesData: Data?

    var listingReturnPolicy: String = ""
    var listingReturnPolicyNotApplicable: Bool = false

    // Project-level listing export settings (Phase 26 batch export).
    var listingExportPresetRaw: String = ListingExportPreset.etsySquare.rawValue
    var listingExportBackgroundRaw: String = ListingExportBackground.white.rawValue
    var listingWatermarkEnabled: Bool = false
    var listingWatermarkText: String = ""

    /// Encoded `BulkEditUndoPayload` for the most recent bulk edit on this project only.
    var lastBulkEditUndoData: Data?

    init(
        name: String,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        photos: [ItemProjectPhoto] = []
    ) {
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.photos = photos
    }

    var listingExportPreset: ListingExportPreset {
        get { ListingExportPreset(rawValue: listingExportPresetRaw) ?? .etsySquare }
        set { listingExportPresetRaw = newValue.rawValue }
    }

    var listingExportBackground: ListingExportBackground {
        get { ListingExportBackground(rawValue: listingExportBackgroundRaw) ?? .white }
        set { listingExportBackgroundRaw = newValue.rawValue }
    }

    var sortedExportBatches: [ProjectExportBatch] {
        exportBatches.sorted { $0.createdAt > $1.createdAt }
    }

    var sortedListingPackages: [ListingPackage] {
        listingPackages.sorted { $0.createdAt > $1.createdAt }
    }

    var sortedPhotos: [ItemProjectPhoto] {
        photos.sorted { $0.sortOrder < $1.sortOrder }
    }

    var photoCount: Int {
        photos.count
    }

    var coverThumbnail: UIImage? {
        sortedPhotos.first?.thumbnailImage
    }

    func touchModified() {
        modifiedAt = .now
    }

    static let maxTagCount = 13

    var trimmedListingTitle: String {
        listingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var parsedListingPrice: Decimal? {
        Self.parsePrice(listingPriceText)
    }

    static func parsePrice(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: "")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Missing/invalid draft fields for completeness UI (persisted values).
    var listingDraftIssues: [String] {
        var issues: [String] = []
        if trimmedListingTitle.isEmpty {
            issues.append("Title is required")
        }
        let priceTrimmed = listingPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if priceTrimmed.isEmpty {
            issues.append("Price is required")
        } else if let price = parsedListingPrice {
            if price < 0 {
                issues.append("Price must be nonnegative")
            }
        } else {
            issues.append("Price must be a valid amount")
        }
        if listingQuantity < 1 {
            issues.append("Quantity must be at least 1")
        }
        if listingTags.count > Self.maxTagCount {
            issues.append("Maximum \(Self.maxTagCount) tags")
        }
        return issues
    }

    var isListingDraftComplete: Bool {
        listingDraftIssues.isEmpty
    }

    var listingCompletenessSummary: String {
        if isListingDraftComplete {
            return "Listing draft complete"
        }
        return "Missing: " + listingDraftIssues.joined(separator: " · ")
    }

    /// Trims tags and drops blanks (does not cap count — validation rejects > max).
    static func normalizedTags(fromRaw raw: String) -> [String] {
        raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var listingTagsRawText: String {
        listingTags.joined(separator: ", ")
    }

    var listingItemType: ListingItemType? {
        get { ListingItemType(rawValue: listingItemTypeRaw) }
        set { listingItemTypeRaw = newValue?.rawValue ?? "" }
    }

    var listingVariations: [ListingVariation] {
        get {
            guard let listingVariationsData else { return [] }
            return (try? JSONDecoder().decode([ListingVariation].self, from: listingVariationsData)) ?? []
        }
        set {
            listingVariationsData = try? JSONEncoder().encode(newValue)
        }
    }

    var listingAttributes: [ListingCategoryAttribute] {
        get {
            guard let listingAttributesData else { return [] }
            return (try? JSONDecoder().decode([ListingCategoryAttribute].self, from: listingAttributesData)) ?? []
        }
        set {
            listingAttributesData = try? JSONEncoder().encode(newValue)
        }
    }

    var listingInformationReview: ListingInformationReview {
        ListingInformationSupport.review(for: self)
    }

    var listingInformationValidationIssues: [String] {
        ListingInformationSupport.validationIssues(for: self)
    }
}

@Model
final class ItemProjectPhoto {
    var localFileName: String?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var sortOrder: Int
    var addedAt: Date
    var project: ItemProject?
    /// Optional Codable `PhotoEditState` from Edit (when saved). Nil = unedited original.
    var savedEditStateData: Data?
    /// Local alt text for this photo. Stays on the photo through reorder/delete.
    var altText: String = ""
    var altTextNotApplicable: Bool = false

    init(
        localFileName: String? = nil,
        thumbnailData: Data? = nil,
        sortOrder: Int = 0,
        addedAt: Date = .now,
        project: ItemProject? = nil
    ) {
        self.localFileName = localFileName
        self.thumbnailData = thumbnailData
        self.sortOrder = sortOrder
        self.addedAt = addedAt
        self.project = project
    }

    var thumbnailImage: UIImage? {
        guard let thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }

    var fullLocalImage: UIImage? {
        LocalEditStore.loadProjectImage(fileName: localFileName)
    }

    var savedEditState: PhotoEditState? {
        get {
            guard let savedEditStateData else { return nil }
            return try? JSONDecoder().decode(PhotoEditState.self, from: savedEditStateData)
        }
        set {
            if let newValue {
                savedEditStateData = try? JSONEncoder().encode(newValue)
            } else {
                savedEditStateData = nil
            }
        }
    }

    /// Edit settings for batch export: saved photo edits when present, else defaults; project framing applied.
    func exportEditState(project: ItemProject) -> PhotoEditState {
        let base = savedEditState ?? PhotoEditState()
        return base.applyingProjectExportSettings(from: project)
    }
}
