import XCTest
import SwiftData
@testable import Yofai

@MainActor
final class Phase63MarketplaceTemplatesDefaultsTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        super.tearDown()
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeTemplateStore() -> MarketplaceTemplateDefaultsStore {
        let suiteName = "yofai.tests.marketplaceTemplates.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removeObject(forKey: MarketplaceTemplateDefaultsStore.storageKey)
        return MarketplaceTemplateDefaultsStore(defaults: suite)
    }

    private func makeSellerDefaultsStore() -> SellerDefaultsStore {
        let suiteName = "yofai.tests.sellerDefaults.phase63.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removeObject(forKey: SellerDefaultsStore.storageKey)
        return SellerDefaultsStore(defaults: suite)
    }

    func testExistingSellerDefaultsStillLoadsAndSaves() {
        let store = makeSellerDefaultsStore()
        var value = SellerDefaults()
        value.category = "Home"
        value.materials = "wood"
        value.marketplaceTarget = .etsy
        value.exportPreset = .etsySquare
        store.save(value)

        let reloaded = store.load()
        XCTAssertEqual(reloaded.category, "Home")
        XCTAssertEqual(reloaded.materials, "wood")
        XCTAssertEqual(reloaded.marketplaceTarget, .etsy)
        XCTAssertEqual(reloaded.exportPreset, .etsySquare)
        XCTAssertEqual(SellerDefaultsStore.storageKey, "com.shawnwright.yofai.sellerDefaults")
        XCTAssertNotEqual(
            SellerDefaultsStore.storageKey,
            MarketplaceTemplateDefaultsStore.storageKey
        )
    }

    func testFreePrimaryWorkflowRemainsAvailable() {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .exportNotes, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .viewAndReshareExportedFiles, state: free).allowsUse)
        XCTAssertFalse(MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: free))
    }

    func testFreeCannotUseMarketplaceSpecificTemplates() {
        let store = makeTemplateStore()
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .ebay
        template.defaultCategory = "Collectibles"
        XCTAssertThrowsError(try store.save(template, state: .launchFree)) { error in
            XCTAssertEqual(error as? MarketplaceListingDraftError, .proRequired)
        }
        XCTAssertNil(store.template(for: .ebay))
        XCTAssertThrowsError(try store.clear(for: .ebay, state: .launchFree)) { error in
            XCTAssertEqual(error as? MarketplaceListingDraftError, .proRequired)
        }
    }

    func testProCanSaveMarketplaceSpecificDefaults() throws {
        let store = makeTemplateStore()
        let pro = EntitlementState(plan: .pro, limits: .launch)
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .poshmark
        template.templateName = "Posh defaults"
        template.defaultCategory = "Dresses"
        template.defaultCondition = "Like new"
        template.defaultTags = ["posh"]
        template.defaultShippingNotes = "Ship fast"
        template.preferredExportPresetRaw = ListingExportPreset.poshmark.rawValue
        try store.save(template, state: pro)

        let loaded = store.template(for: .poshmark)
        XCTAssertEqual(loaded?.templateName, "Posh defaults")
        XCTAssertEqual(loaded?.defaultCategory, "Dresses")
        XCTAssertEqual(loaded?.defaultCondition, "Like new")
        XCTAssertEqual(loaded?.defaultTags, ["posh"])
        XCTAssertEqual(loaded?.defaultShippingNotes, "Ship fast")
        XCTAssertEqual(loaded?.preferredExportPreset, .poshmark)
    }

    func testProCanApplyMarketplaceDefaultsToDraftWithoutOverwritingNonblank() {
        let draft = MarketplaceListingDraft(marketplaceTarget: .etsy)
        draft.category = "Keep Me"
        draft.draftDescription = ""
        draft.condition = "Good"
        draft.materials = ""
        draft.shippingNotes = "Existing ship"
        draft.returnsPolicy = ""

        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .etsy
        template.defaultCategory = "Template Cat"
        template.defaultDescription = "Template Desc"
        template.defaultCondition = "Template Cond"
        template.defaultMaterials = "Template Mat"
        template.defaultShippingNotes = "Template Ship"
        template.defaultReturnsPolicy = "Template Returns"

        let filled = MarketplaceTemplateDefaultsSupport.applyToBlankFields(template, onto: draft)
        XCTAssertGreaterThan(filled, 0)
        XCTAssertEqual(draft.category, "Keep Me")
        XCTAssertEqual(draft.condition, "Good")
        XCTAssertEqual(draft.shippingNotes, "Existing ship")
        XCTAssertEqual(draft.draftDescription, "Template Desc")
        XCTAssertEqual(draft.materials, "Template Mat")
        XCTAssertEqual(draft.returnsPolicy, "Template Returns")
    }

    func testCreatingProDraftPrefillsFromMarketplaceDefault() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let project = ItemProject(name: "Prefill")
        project.listingTitle = "Primary Title"
        project.listingCategory = ""
        project.listingDescription = ""
        project.listingShippingProfile = ""
        context.insert(project)

        let store = makeTemplateStore()
        let pro = EntitlementState(plan: .pro, limits: .launch)
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .ebay
        template.defaultCategory = "Electronics"
        template.defaultDescription = "Ebay blurb"
        template.defaultShippingNotes = "USPS"
        template.defaultMarketplaceSellerNotes = "No returns note"
        template.preferredExportPresetRaw = ListingExportPreset.ebay.rawValue
        template.preferredFitModeRaw = ListingExportFitMode.fillCrop.rawValue
        try store.save(template, state: pro)

        let draft = try MarketplaceListingDraftSupport.createDraft(
            for: .ebay,
            on: project,
            in: context,
            state: pro,
            templateStore: store
        )

        XCTAssertEqual(draft.title, "Primary Title")
        XCTAssertEqual(draft.category, "Electronics")
        XCTAssertEqual(draft.draftDescription, "Ebay blurb")
        XCTAssertEqual(draft.shippingNotes, "USPS")
        XCTAssertEqual(draft.marketplaceSellerNotes, "No returns note")
        XCTAssertEqual(draft.exportPreset, .ebay)
        XCTAssertEqual(draft.exportFitMode, .fillCrop)
        XCTAssertEqual(project.listingTitle, "Primary Title")
        XCTAssertEqual(project.listingCategory, "")
    }

    func testClearingMarketplaceDefaultWorks() throws {
        let store = makeTemplateStore()
        let pro = EntitlementState(plan: .pro, limits: .launch)
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .mercari
        template.defaultCategory = "Stuff"
        try store.save(template, state: pro)
        XCTAssertTrue(store.hasTemplate(for: .mercari))
        try store.clear(for: .mercari, state: pro)
        XCTAssertFalse(store.hasTemplate(for: .mercari))
        XCTAssertNil(store.template(for: .mercari))
    }

    func testAdvancedMultiMarketToolsGatesTemplates() {
        let free = EntitlementState.launchFree
        let pro = EntitlementState(plan: .pro, limits: .launch)
        XCTAssertFalse(EntitlementPolicy.access(for: .advancedMultiMarketTools, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .advancedMultiMarketTools, state: pro).allowsUse)
        XCTAssertEqual(MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: free), false)
        XCTAssertEqual(MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: pro), true)
    }

    func testFacebookAndMercariRecommendedPresetsRemainNil() {
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        // Templates may store a general preferred canvas without inventing target recommendations.
        var template = MarketplaceTemplateDefault()
        template.marketplaceTarget = .facebookMarketplace
        template.preferredExportPresetRaw = ListingExportPreset.marketplace.rawValue
        XCTAssertEqual(template.preferredExportPreset, .marketplace)
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
    }

    func testExportPresetsUnchanged() {
        let expected: [(ListingExportPreset, String, CGFloat, CGFloat)] = [
            (.etsySquare, "Etsy square", 2000, 2000),
            (.etsyListing, "Etsy listing", 3000, 2400),
            (.instagramSquare, "Instagram square", 1080, 1080),
            (.facebookPost, "Facebook post", 1200, 630),
            (.marketplace, "Marketplace", 1600, 1600),
            (.ebay, "eBay", 1600, 1600),
            (.poshmark, "Poshmark", 1000, 1000)
        ]
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        for (preset, raw, w, h) in expected {
            XCTAssertEqual(preset.rawValue, raw)
            XCTAssertEqual(preset.pixelSize.width, w)
            XCTAssertEqual(preset.pixelSize.height, h)
        }
    }

    func testPhase63CopyAvoidsBannedWording() {
        for text in MarketplaceTemplateDefaultsCopy.allUserFacingStrings {
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("upload directly"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("publish to"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("post automatically"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("connect marketplace"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("marketplace automation"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("Direct Upload"), text)
            XCTAssertFalse(text.localizedCaseInsensitiveContains("OAuth"), text)
            XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(text), text)
        }
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
    }
}
