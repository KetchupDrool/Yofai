import Foundation

/// Local seller preferences for new Item Projects only. Never stores Etsy credentials.
struct SellerDefaults: Codable, Equatable {
    var category: String = ""
    var materials: String = ""
    var shippingProfile: String = ""
    var processingTime: String = ""
    var exportPresetRaw: String = ListingExportPreset.etsySquare.rawValue
    var exportBackgroundRaw: String = ListingExportBackground.white.rawValue
    var watermarkText: String = ""

    var exportPreset: ListingExportPreset {
        get { ListingExportPreset(rawValue: exportPresetRaw) ?? .etsySquare }
        set { exportPresetRaw = newValue.rawValue }
    }

    var exportBackground: ListingExportBackground {
        get { ListingExportBackground(rawValue: exportBackgroundRaw) ?? .white }
        set { exportBackgroundRaw = newValue.rawValue }
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
            && trimmedWatermarkText.isEmpty
    }

    /// Prefills only the allowed new-project listing/export fields. Never touches photos or queue.
    func apply(to project: ItemProject) {
        project.listingCategory = category
        project.listingMaterials = materials
        project.listingShippingProfile = shippingProfile
        project.listingProcessingTime = processingTime
        project.listingExportPreset = exportPreset
        project.listingExportBackground = exportBackground
        project.listingWatermarkText = String(trimmedWatermarkText.prefix(PhotoEditState.watermarkMaxLength))
        project.listingWatermarkEnabled = !project.listingWatermarkText.isEmpty
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
    /// Copies listing details + export settings only into a new project with the given name.
    /// Does not copy photos, files, edits, batches, queue entries, History, or Originals.
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
        copy.listingWatermarkEnabled = listingWatermarkEnabled
        copy.listingWatermarkText = listingWatermarkText
        return copy
    }
}
