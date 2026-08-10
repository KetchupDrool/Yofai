import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase49FreemiumFoundationTests: XCTestCase {
    override func tearDown() {
        EntitlementStore.shared.resetToLaunchFree()
        super.tearDown()
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24), format: format)
        return renderer.image { context in
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
    }

    // MARK: - Entitlements

    func testDefaultEntitlementIsFree() {
        EntitlementStore.shared.resetToLaunchFree()
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
        XCTAssertFalse(EntitlementStore.shared.state.isPro)
        XCTAssertEqual(EntitlementStore.shared.state.limits.freeActiveProductLimit, 12)
        XCTAssertEqual(FreemiumLimits.launch.freeExportHistoryHighlightLimit, 25)
    }

    func testProEntitlementRepresentableInTests() {
        EntitlementStore.shared.setPlanForTesting(.pro)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .pro)
        XCTAssertTrue(EntitlementStore.shared.state.isPro)
        XCTAssertTrue(
            EntitlementPolicy.access(for: .unlimitedProducts, state: EntitlementStore.shared.state).allowsUse
        )
    }

    func testFeaturePolicyFreeVsPro() {
        let free = EntitlementState.launchFree
        let pro = EntitlementState(plan: .pro, limits: .launch)

        XCTAssertTrue(EntitlementPolicy.access(for: .coreLocalExport, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .photoCheck, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .basicEditAndFit, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .exportNotes, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .viewAndReshareExportedFiles, state: free).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .exportHistory, state: free).allowsUse)

        XCTAssertFalse(EntitlementPolicy.access(for: .unlimitedProducts, state: free).allowsUse)
        XCTAssertFalse(EntitlementPolicy.access(for: .advancedHistoryTools, state: free).allowsUse)
        XCTAssertFalse(EntitlementPolicy.access(for: .cloudBackupSync, state: free).allowsUse)
        XCTAssertFalse(EntitlementPolicy.access(for: .directUploadMode, state: free).allowsUse)

        XCTAssertTrue(EntitlementPolicy.access(for: .unlimitedProducts, state: pro).allowsUse)
        XCTAssertTrue(EntitlementPolicy.access(for: .advancedHistoryTools, state: pro).allowsUse)
        // Future features stay locked until implemented even for Pro.
        XCTAssertFalse(EntitlementPolicy.access(for: .cloudBackupSync, state: pro).allowsUse)
        XCTAssertFalse(EntitlementPolicy.access(for: .directUploadMode, state: pro).allowsUse)
    }

    func testLimitsAreCentralized() {
        var custom = FreemiumLimits.launch
        custom.freeActiveProductLimit = 3
        let state = EntitlementState(plan: .free, limits: custom)
        XCTAssertTrue(EntitlementPolicy.canCreateProduct(activeProductCount: 2, state: state))
        XCTAssertFalse(EntitlementPolicy.canCreateProduct(activeProductCount: 3, state: state))
    }

    // MARK: - Free limits / data safety

    func testFreeProductLimitAndOverLimitDataRemainsAccessible() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        var custom = FreemiumLimits.launch
        custom.freeActiveProductLimit = 2
        let free = EntitlementState(plan: .free, limits: custom)

        let a = ItemProject(name: "A", photos: [])
        let b = ItemProject(name: "B", photos: [])
        let c = ItemProject(name: "C", photos: [])
        context.insert(a)
        context.insert(b)
        context.insert(c)
        try context.save()

        XCTAssertFalse(EntitlementPolicy.canCreateProduct(activeProductCount: 3, state: free))
        let access = EntitlementPolicy.access(for: .createProduct, state: free, activeProductCount: 3)
        XCTAssertFalse(access.allowsUse)

        // Existing products remain in the store — entitlement never deletes.
        let remaining = try context.fetch(FetchDescriptor<ItemProject>())
        XCTAssertEqual(remaining.count, 3)
        XCTAssertEqual(Set(remaining.map(\.name)), Set(["A", "B", "C"]))
    }

    func testCoreLocalExportPhotoCheckEditRemainFree() throws {
        let free = EntitlementState.launchFree
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport(state: free))
        XCTAssertTrue(FreemiumFeature.coreLocalExport.isCoreFreeWorkflow)
        XCTAssertTrue(FreemiumFeature.photoCheck.isCoreFreeWorkflow)
        XCTAssertTrue(FreemiumFeature.basicEditAndFit.isCoreFreeWorkflow)

        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "FreeExport",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        context.insert(batch)
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
    }

    // MARK: - Pro placeholders

    func testProLockedStateDoesNotMutateData() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Keep", photos: [])
        context.insert(project)
        let batch = ProjectExportBatch(
            batchFolderName: "p49",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            sellerNote: "note"
        )
        context.insert(batch)
        try context.save()

        let before = batch.sellerNote
        let locked = EntitlementPolicy.access(
            for: .advancedHistoryTools,
            state: .launchFree
        )
        XCTAssertFalse(locked.allowsUse)
        if case .lockedPro(let message) = locked {
            XCTAssertTrue(message.contains("Pro") || message.contains("Planned"))
        } else {
            XCTFail("Expected lockedPro")
        }

        XCTAssertEqual(batch.sellerNote, before)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ItemProject>()).count, 1)
        XCTAssertFalse(FreemiumCopy.proNotAvailableYet.lowercased().contains("purchased"))
        XCTAssertFalse(FreemiumCopy.proNotAvailableYet.lowercased().contains("$"))
    }

    // MARK: - Regression

    func testPresetsNotesFileAccessAndNoUpload() throws {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))

        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Reg", photos: [])
        project.listingMarketplaceTarget = .facebookMarketplace
        project.listingExportPreset = .marketplace
        context.insert(project)
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)

        let batch = ProjectExportBatch(
            batchFolderName: "missing",
            orderedFileNames: ["01.jpg"],
            successCount: 1,
            project: project,
            sellerNote: "eBay draft"
        )
        context.insert(batch)
        XCTAssertTrue(batch.hasSellerNote)
        XCTAssertEqual(
            ExportBatchFileAccessSupport.availabilityMessage(for: batch),
            ExportBatchFileAccessSupport.filesUnavailableMessage
        )
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertFalse(batch.resultSummaryText.lowercased().contains("upload status"))
    }
}
