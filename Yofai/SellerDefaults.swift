import Foundation

/// Local seller preferences for new Item Projects only. Never stores Etsy credentials.
struct SellerDefaults: Equatable {
    var category: String = ""
    var materials: String = ""
    var shippingProfile: String = ""
    var processingTime: String = ""
    var exportPresetRaw: String = ListingExportPreset.etsySquare.rawValue
    var exportBackgroundRaw: String = ListingExportBackground.white.rawValue
    var exportFitModeRaw: String = ListingExportFitMode.containPad.rawValue
    var marketplaceTargetRaw: String = MarketplaceTarget.other.rawValue
    var watermarkText: String = ""

    // Phase 30 — safe reusable listing-information defaults only.
    var itemTypeRaw: String = ""
    var condition: String = ""
    var whoMadeIt: String = ""
    var whenMade: String = ""
    var returnPolicy: String = ""

    var exportPreset: ListingExportPreset {
        get { ListingExportPreset(rawValue: exportPresetRaw) ?? .etsySquare }
        set { exportPresetRaw = newValue.rawValue }
    }

    var exportBackground: ListingExportBackground {
        get { ListingExportBackground(rawValue: exportBackgroundRaw) ?? .white }
        set { exportBackgroundRaw = newValue.rawValue }
    }

    var exportFitMode: ListingExportFitMode {
        get { ListingExportFitMode.resolved(rawValue: exportFitModeRaw) }
        set { exportFitModeRaw = newValue.rawValue }
    }

    var marketplaceTarget: MarketplaceTarget {
        get { MarketplaceTarget.resolved(rawValue: marketplaceTargetRaw) }
        set { marketplaceTargetRaw = newValue.rawValue }
    }

    var itemType: ListingItemType? {
        get { ListingItemType(rawValue: itemTypeRaw) }
        set { itemTypeRaw = newValue?.rawValue ?? "" }
    }

    var trimmedWatermarkText: String {
        watermarkText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmpty: Bool {
        category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && materials.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && shippingProfile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && processingTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && exportPreset == .etsySquare
            && exportBackground == .white
            && exportFitMode == .containPad
            && marketplaceTarget == .other
            && trimmedWatermarkText.isEmpty
            && itemTypeRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && whoMadeIt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && whenMade.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && returnPolicy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Prefills only the allowed new-project listing/export fields. Never touches photos or queue.
    func apply(to project: ItemProject) {
        project.listingCategory = category
        project.listingMaterials = materials
        project.listingShippingProfile = shippingProfile
        project.listingProcessingTime = processingTime
        project.listingExportPreset = exportPreset
        project.listingExportBackground = exportBackground
        project.listingExportFitMode = exportFitMode
        project.listingMarketplaceTarget = marketplaceTarget
        project.listingWatermarkText = String(trimmedWatermarkText.prefix(PhotoEditState.watermarkMaxLength))
        project.listingWatermarkEnabled = !project.listingWatermarkText.isEmpty

        if let itemType {
            project.listingItemType = itemType
            project.listingItemTypeNotApplicable = false
        }
        let trimmedCondition = condition.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCondition.isEmpty {
            project.listingCondition = trimmedCondition
            project.listingConditionNotApplicable = false
        }
        let trimmedWho = whoMadeIt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedWho.isEmpty {
            project.listingWhoMadeIt = trimmedWho
            project.listingWhoMadeItNotApplicable = false
        }
        let trimmedWhen = whenMade.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedWhen.isEmpty {
            project.listingWhenMade = trimmedWhen
            project.listingWhenMadeNotApplicable = false
        }
        let trimmedReturn = returnPolicy.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedReturn.isEmpty {
            project.listingReturnPolicy = trimmedReturn
            project.listingReturnPolicyNotApplicable = false
        }
    }
}

extension SellerDefaults: Codable {
    enum CodingKeys: String, CodingKey {
        case category, materials, shippingProfile, processingTime
        case exportPresetRaw, exportBackgroundRaw, exportFitModeRaw, marketplaceTargetRaw, watermarkText
        case itemTypeRaw, condition, whoMadeIt, whenMade, returnPolicy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        materials = try container.decodeIfPresent(String.self, forKey: .materials) ?? ""
        shippingProfile = try container.decodeIfPresent(String.self, forKey: .shippingProfile) ?? ""
        processingTime = try container.decodeIfPresent(String.self, forKey: .processingTime) ?? ""
        exportPresetRaw = try container.decodeIfPresent(String.self, forKey: .exportPresetRaw)
            ?? ListingExportPreset.etsySquare.rawValue
        exportBackgroundRaw = try container.decodeIfPresent(String.self, forKey: .exportBackgroundRaw)
            ?? ListingExportBackground.white.rawValue
        exportFitModeRaw = try container.decodeIfPresent(String.self, forKey: .exportFitModeRaw)
            ?? ListingExportFitMode.containPad.rawValue
        marketplaceTargetRaw = try container.decodeIfPresent(String.self, forKey: .marketplaceTargetRaw)
            ?? MarketplaceTarget.other.rawValue
        watermarkText = try container.decodeIfPresent(String.self, forKey: .watermarkText) ?? ""
        itemTypeRaw = try container.decodeIfPresent(String.self, forKey: .itemTypeRaw) ?? ""
        condition = try container.decodeIfPresent(String.self, forKey: .condition) ?? ""
        whoMadeIt = try container.decodeIfPresent(String.self, forKey: .whoMadeIt) ?? ""
        whenMade = try container.decodeIfPresent(String.self, forKey: .whenMade) ?? ""
        returnPolicy = try container.decodeIfPresent(String.self, forKey: .returnPolicy) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(materials, forKey: .materials)
        try container.encode(shippingProfile, forKey: .shippingProfile)
        try container.encode(processingTime, forKey: .processingTime)
        try container.encode(exportPresetRaw, forKey: .exportPresetRaw)
        try container.encode(exportBackgroundRaw, forKey: .exportBackgroundRaw)
        try container.encode(exportFitModeRaw, forKey: .exportFitModeRaw)
        try container.encode(marketplaceTargetRaw, forKey: .marketplaceTargetRaw)
        try container.encode(watermarkText, forKey: .watermarkText)
        try container.encode(itemTypeRaw, forKey: .itemTypeRaw)
        try container.encode(condition, forKey: .condition)
        try container.encode(whoMadeIt, forKey: .whoMadeIt)
        try container.encode(whenMade, forKey: .whenMade)
        try container.encode(returnPolicy, forKey: .returnPolicy)
    }
}

/// Persistence for seller defaults. Uses UserDefaults only (not Keychain / not SwiftData projects).
final class SellerDefaultsStore {
    static let storageKey = "com.shawnwright.yofai.sellerDefaults"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> SellerDefaults {
        guard let data = defaults.data(forKey: Self.storageKey) else {
            return SellerDefaults()
        }
        return (try? JSONDecoder().decode(SellerDefaults.self, from: data)) ?? SellerDefaults()
    }

    func save(_ value: SellerDefaults) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }

    var hasSavedDefaults: Bool {
        defaults.data(forKey: Self.storageKey) != nil
    }
}

extension ItemProject {
    /// Copies listing details + export settings + listing information + photo-plan goal names/order only.
    /// Does not copy photos, files, edits, batches, packages, queue entries,
    /// legacy dormant listing-prep records, goal completion/attachments, History, or Originals.
    func duplicateListingDraft(newName: String) -> ItemProject {
        let copy = ItemProject(name: newName.trimmingCharacters(in: .whitespacesAndNewlines))
        copy.listingTitle = listingTitle
        copy.listingDescription = listingDescription
        copy.listingPriceText = listingPriceText
        copy.listingQuantity = listingQuantity
        copy.listingCategory = listingCategory
        copy.listingTags = listingTags
        copy.listingMaterials = listingMaterials
        copy.listingShippingProfile = listingShippingProfile
        copy.listingProcessingTime = listingProcessingTime
        copy.listingExportPresetRaw = listingExportPresetRaw
        copy.listingExportBackgroundRaw = listingExportBackgroundRaw
        copy.listingExportFitModeRaw = listingExportFitModeRaw
        copy.listingMarketplaceTargetRaw = listingMarketplaceTargetRaw
        copy.listingWatermarkEnabled = listingWatermarkEnabled
        copy.listingWatermarkText = listingWatermarkText

        copy.listingItemTypeRaw = listingItemTypeRaw
        copy.listingItemTypeNotApplicable = listingItemTypeNotApplicable
        copy.listingCondition = listingCondition
        copy.listingConditionNotApplicable = listingConditionNotApplicable
        copy.listingWhoMadeIt = listingWhoMadeIt
        copy.listingWhoMadeItNotApplicable = listingWhoMadeItNotApplicable
        copy.listingWhenMade = listingWhenMade
        copy.listingWhenMadeNotApplicable = listingWhenMadeNotApplicable
        copy.listingSKU = listingSKU
        copy.listingSKUNotApplicable = listingSKUNotApplicable

        copy.listingPersonalizationEnabled = listingPersonalizationEnabled
        copy.listingPersonalizationNotApplicable = listingPersonalizationNotApplicable
        copy.listingPersonalizationInstructions = listingPersonalizationInstructions
        copy.listingPersonalizationInstructionsNotApplicable = listingPersonalizationInstructionsNotApplicable
        copy.listingPersonalizationCharacterLimitText = listingPersonalizationCharacterLimitText
        copy.listingPersonalizationRequired = listingPersonalizationRequired

        copy.listingVariationsNotApplicable = listingVariationsNotApplicable
        copy.listingVariationsData = listingVariationsData
        copy.listingAttributesNotApplicable = listingAttributesNotApplicable
        copy.listingAttributesData = listingAttributesData
        copy.listingReturnPolicy = listingReturnPolicy
        copy.listingReturnPolicyNotApplicable = listingReturnPolicyNotApplicable

        for goal in sortedPhotoPlanGoals {
            copy.photoPlanGoals.append(
                PhotoPlanGoal(
                    name: goal.name,
                    sortOrder: goal.sortOrder,
                    isComplete: false,
                    attachedPhotoStableID: nil,
                    project: copy
                )
            )
        }
        return copy
    }
}
