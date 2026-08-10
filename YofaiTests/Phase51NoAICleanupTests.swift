import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase51NoAICleanupTests: XCTestCase {
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
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
    }

    func testNoActiveAIProductClaimsInLaunchCopy() {
        let samples = [
            AppStoreLaunchSupport.oneLinePositioning,
            AppStoreLaunchSupport.privacySummary,
            AppStoreLaunchSupport.freemiumLaunchNote,
            AppStoreLaunchSupport.etsyConnectionUnavailableDetail
        ] + AppStoreLaunchSupport.whatItDoesNotDo
        for text in samples {
            XCTAssertFalse(AppStoreLaunchSupport.containsActiveAIProductClaim(text), text)
            XCTAssertFalse(AppStoreLaunchSupport.containsRiskyAppStoreClaim(text), text)
        }
        XCTAssertTrue(AppStoreLaunchSupport.whatItDoesNotDo.contains("Does not use AI"))
        XCTAssertTrue(AppStoreLaunchSupport.privacySummary.lowercased().contains("no ai service"))
    }

    func testDeterministicLocalToolsRemainAvailable() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "No AI",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .etsy
        project.listingExportPreset = .etsySquare
        context.insert(project)

        let facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertNotNil(facts)

        let readiness = ExportReadiness.summary(for: project)
        XCTAssertFalse(readiness.items.isEmpty)

        let tips = ExportPrepTipSupport.tips(for: project)
        XCTAssertFalse(tips.isEmpty)

        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
        XCTAssertTrue(EntitlementPolicy.freeKeepsCoreLocalExport())
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
    }

    func testFreeLocalExportAndRegressionGuards() throws {
        XCTAssertEqual(FreemiumLimits.launch.freeActiveProductLimit, 12)
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)

        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Export",
            photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)]
        )
        project.listingMarketplaceTarget = .ebay
        project.listingExportPreset = .ebay
        context.insert(project)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project)!
        batch.setSellerNote("seller note")
        context.insert(batch)

        XCTAssertTrue(batch.hasSellerNote)
        XCTAssertTrue(ExportBatchFileAccessSupport.canShare(batch))
        XCTAssertEqual(project.aiPreparations.count, 0)
        XCTAssertTrue(YofaiModelSchema.models.contains { $0 == AIPreparationRecord.self })
    }

    func testLegacyShellLoadsWithoutProviderUI() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Legacy shell")
        context.insert(project)
        let record = AIPreparationRecord(project: project, statusRaw: LegacyListingPrepStatus.draft.rawValue)
        context.insert(record)
        try context.save()
        XCTAssertEqual(project.aiPreparations.count, 1)
        XCTAssertEqual(project.aiPreparations.first?.statusRaw, "Draft")
        XCTAssertEqual(LegacyListingPrepStatus.readyForAI.rawValue, "Ready for AI")
    }
}
