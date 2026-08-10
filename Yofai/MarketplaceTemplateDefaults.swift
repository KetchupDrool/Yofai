import Foundation
import SwiftData

/// Phase 63 — per-marketplace local template/defaults for Pro additional drafts.
/// Separate from Free `SellerDefaults` (new Item Projects). UserDefaults only — no credentials / no API.
struct MarketplaceTemplateDefault: Equatable, Codable {
    var marketplaceTargetRaw: String = MarketplaceTarget.other.rawValue
    var templateName: String = ""
    var defaultDescription: String = ""
    var defaultCategory: String = ""
    var defaultCondition: String = ""
    var defaultTags: [String] = []
    var defaultMaterials: String = ""
    var defaultShippingNotes: String = ""
    var defaultProcessingTime: String = ""
    var defaultReturnsPolicy: String = ""
    var defaultPersonalization: String = ""
    var defaultMarketplaceSellerNotes: String = ""
    /// Empty = no preferred canvas. Never invents FB/Mercari fixed recommendations.
    var preferredExportPresetRaw: String = ""
    var preferredFitModeRaw: String = ""
    var updatedAt: Date = Date()

    var marketplaceTarget: MarketplaceTarget {
        get { MarketplaceTarget.resolved(rawValue: marketplaceTargetRaw) }
        set { marketplaceTargetRaw = newValue.rawValue }
    }

    var displayName: String {
        let trimmed = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return "\(marketplaceTarget.displayTitle) defaults"
    }

    var preferredExportPreset: ListingExportPreset? {
        guard !preferredExportPresetRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return ListingExportPreset(rawValue: preferredExportPresetRaw)
    }

    var preferredFitMode: ListingExportFitMode? {
        let trimmed = preferredFitModeRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return ListingExportFitMode.resolved(rawValue: trimmed)
    }

    var isEmpty: Bool {
        templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Self.isBlank(defaultDescription)
            && Self.isBlank(defaultCategory)
            && Self.isBlank(defaultCondition)
            && defaultTags.isEmpty
            && Self.isBlank(defaultMaterials)
            && Self.isBlank(defaultShippingNotes)
            && Self.isBlank(defaultProcessingTime)
            && Self.isBlank(defaultReturnsPolicy)
            && Self.isBlank(defaultPersonalization)
            && Self.isBlank(defaultMarketplaceSellerNotes)
            && preferredExportPreset == nil
            && preferredFitMode == nil
    }

    static func isBlank(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum MarketplaceTemplateDefaultsCopy {
    static let sectionTitle = "Marketplace defaults"
    static let saveAsTemplate = "Save as template"
    static let applyToBlankFields = "Apply to blank fields"
    static let clearTemplate = "Clear marketplace default"
    static let templateSaved = "Marketplace default saved"
    static let templateApplied = "Applied to blank fields"
    static let templateCleared = "Marketplace default cleared"
    static let noTemplateSaved = "No marketplace default saved for this target yet."
    static let lockedDetail =
        "Marketplace templates are advanced multi-market tools in Yofai Pro. Free keeps Seller Defaults for new products and your primary listing workflow."
    static let footer =
        "Local marketplace defaults for additional drafts. Manual listing packages only — Local JPEGs for manual upload outside the app."
    static let settingsFooter =
        "Pro marketplace defaults are managed from each marketplace draft. Existing Seller Defaults for new products stay unchanged."

    static var allUserFacingStrings: [String] {
        [
            sectionTitle, saveAsTemplate, applyToBlankFields, clearTemplate,
            templateSaved, templateApplied, templateCleared, noTemplateSaved,
            lockedDetail, footer, settingsFooter
        ]
    }
}

enum MarketplaceTemplateDefaultsSupport {
    /// Same Pro gate as additional drafts / draft package tools.
    static func canUseMarketplaceTemplates(state: EntitlementState) -> Bool {
        EntitlementPolicy.access(for: .advancedMultiMarketTools, state: state).allowsUse
    }

    static func makeTemplate(from draft: MarketplaceListingDraft, name: String = "") -> MarketplaceTemplateDefault {
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = draft.marketplaceTarget
        template.templateName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? draft.displayTitle
            : name
        template.defaultDescription = draft.draftDescription
        template.defaultCategory = draft.category
        template.defaultCondition = draft.condition
        template.defaultTags = draft.tags
        template.defaultMaterials = draft.materials
        template.defaultShippingNotes = draft.shippingNotes
        template.defaultProcessingTime = draft.processingTime
        template.defaultReturnsPolicy = draft.returnsPolicy
        template.defaultPersonalization = draft.personalizationNotes
        template.defaultMarketplaceSellerNotes = draft.marketplaceSellerNotes
        template.preferredExportPresetRaw = draft.exportPresetRaw
        template.preferredFitModeRaw = draft.exportFitModeRaw
        template.updatedAt = .now
        return template
    }

    /// Fills only blank draft fields. Never overwrites nonblank text/tags.
    @discardableResult
    static func applyToBlankFields(_ template: MarketplaceTemplateDefault, onto draft: MarketplaceListingDraft) -> Int {
        var filled = 0
        if MarketplaceTemplateDefault.isBlank(draft.draftDescription),
           !MarketplaceTemplateDefault.isBlank(template.defaultDescription) {
            draft.draftDescription = template.defaultDescription
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.category),
           !MarketplaceTemplateDefault.isBlank(template.defaultCategory) {
            draft.category = template.defaultCategory
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.condition),
           !MarketplaceTemplateDefault.isBlank(template.defaultCondition) {
            draft.condition = template.defaultCondition
            filled += 1
        }
        if draft.tags.isEmpty, !template.defaultTags.isEmpty {
            draft.tags = template.defaultTags
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.materials),
           !MarketplaceTemplateDefault.isBlank(template.defaultMaterials) {
            draft.materials = template.defaultMaterials
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.shippingNotes),
           !MarketplaceTemplateDefault.isBlank(template.defaultShippingNotes) {
            draft.shippingNotes = template.defaultShippingNotes
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.processingTime),
           !MarketplaceTemplateDefault.isBlank(template.defaultProcessingTime) {
            draft.processingTime = template.defaultProcessingTime
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.returnsPolicy),
           !MarketplaceTemplateDefault.isBlank(template.defaultReturnsPolicy) {
            draft.returnsPolicy = template.defaultReturnsPolicy
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.personalizationNotes),
           !MarketplaceTemplateDefault.isBlank(template.defaultPersonalization) {
            draft.personalizationNotes = template.defaultPersonalization
            filled += 1
        }
        if MarketplaceTemplateDefault.isBlank(draft.marketplaceSellerNotes),
           !MarketplaceTemplateDefault.isBlank(template.defaultMarketplaceSellerNotes) {
            draft.marketplaceSellerNotes = template.defaultMarketplaceSellerNotes
            filled += 1
        }
        if filled > 0 {
            draft.touchUpdated()
        }
        return filled
    }

    /// Applies preferred export/fit when the template stores a valid preference.
    /// Does not invent Facebook Marketplace or Mercari recommended presets on `MarketplaceTarget`.
    @discardableResult
    static func applyPreferredExportSettingsIfPresent(
        _ template: MarketplaceTemplateDefault,
        onto draft: MarketplaceListingDraft
    ) -> Bool {
        var changed = false
        if let preset = template.preferredExportPreset {
            draft.exportPreset = preset
            changed = true
        }
        if let fit = template.preferredFitMode {
            draft.exportFitMode = fit
            changed = true
        }
        if changed {
            draft.touchUpdated()
        }
        return changed
    }
}

/// Persistence for per-marketplace templates. Additive UserDefaults key — does not touch SellerDefaults.
final class MarketplaceTemplateDefaultsStore {
    static let storageKey = "com.shawnwright.yofai.marketplaceTemplateDefaults.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func allTemplates() -> [MarketplaceTemplateDefault] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        return (try? JSONDecoder().decode([MarketplaceTemplateDefault].self, from: data)) ?? []
    }

    func template(for target: MarketplaceTarget) -> MarketplaceTemplateDefault? {
        allTemplates().first { $0.marketplaceTarget == target }
    }

    func hasTemplate(for target: MarketplaceTarget) -> Bool {
        template(for: target) != nil
    }

    func save(_ template: MarketplaceTemplateDefault, state: EntitlementState) throws {
        guard MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: state) else {
            throw MarketplaceListingDraftError.proRequired
        }
        var template = template
        template.updatedAt = .now
        var templates = allTemplates().filter { $0.marketplaceTarget != template.marketplaceTarget }
        templates.append(template)
        templates.sort { $0.marketplaceTargetRaw < $1.marketplaceTargetRaw }
        guard let data = try? JSONEncoder().encode(templates) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func clear(for target: MarketplaceTarget, state: EntitlementState) throws {
        guard MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: state) else {
            throw MarketplaceListingDraftError.proRequired
        }
        let templates = allTemplates().filter { $0.marketplaceTarget != target }
        if templates.isEmpty {
            defaults.removeObject(forKey: Self.storageKey)
            return
        }
        guard let data = try? JSONEncoder().encode(templates) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func clearAllForTesting() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
