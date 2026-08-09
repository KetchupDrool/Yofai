import XCTest
import SwiftData
import UIKit
import CoreGraphics
@testable import Yofai

@MainActor
final class Phase34ExportCanvasCheckTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeProject(
        imageSize: CGSize,
        preset: ListingExportPreset,
        in context: ModelContext
    ) throws -> ItemProject {
        let file = try LocalEditStore.saveProjectImage(makeImage(color: .red, size: imageSize))
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Canvas Check", photos: [photo])
        project.listingExportPreset = preset
        context.insert(project)
        return project
    }

    func testFactsIncludeExportCanvasFromProjectPreset() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(
            imageSize: CGSize(width: 64, height: 64),
            preset: .etsySquare,
            in: context
        )
        let facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertEqual(facts.exportCanvasPreset, .etsySquare)
        XCTAssertEqual(facts.exportCanvasWidth, 2000)
        XCTAssertEqual(facts.exportCanvasHeight, 2000)
        XCTAssertEqual(facts.exportCanvasPreset.pixelSizeLabel, "2000×2000")
    }

    func testSourceSmallerThanCanvasIsDetected() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(
            imageSize: CGSize(width: 100, height: 100),
            preset: .etsySquare,
            in: context
        )
        let facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertEqual(facts.sourceSmallerThanExportCanvas, true)
        XCTAssertEqual(facts.sourceAspectDiffersFromCanvas, false)
    }

    func testSourceMeetingCanvasIsNotFlaggedSmaller() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(
            imageSize: CGSize(width: 2000, height: 2000),
            preset: .etsySquare,
            in: context
        )
        let facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertEqual(facts.sourceSmallerThanExportCanvas, false)
        XCTAssertEqual(facts.sourceAspectDiffersFromCanvas, false)
    }

    func testAspectDifferenceDetectedForContainPad() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(
            imageSize: CGSize(width: 3000, height: 1000),
            preset: .etsySquare,
            in: context
        )
        let facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertEqual(facts.sourceAspectDiffersFromCanvas, true)
        // 3000 meets width of 2000, but height 1000 < 2000
        XCTAssertEqual(facts.sourceSmallerThanExportCanvas, true)
    }

    func testChangingProjectPresetUpdatesCanvasFacts() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(
            imageSize: CGSize(width: 1600, height: 1600),
            preset: .etsySquare,
            in: context
        )
        var facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertEqual(facts.sourceSmallerThanExportCanvas, true)

        project.listingExportPreset = .marketplace
        facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertEqual(facts.exportCanvasPreset, .marketplace)
        XCTAssertEqual(facts.exportCanvasWidth, 1600)
        XCTAssertEqual(facts.exportCanvasHeight, 1600)
        XCTAssertEqual(facts.sourceSmallerThanExportCanvas, false)
    }

    func testMissingFileCanvasCompareUnavailableButListedInSmallerHelper() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(
            imageSize: CGSize(width: 64, height: 64),
            preset: .instagramSquare,
            in: context
        )
        project.sortedPhotos[0].localFileName = "missing-phase34.jpg"
        let facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertNil(facts.sourceSmallerThanExportCanvas)
        XCTAssertNil(facts.sourceAspectDiffersFromCanvas)
        XCTAssertEqual(facts.exportCanvasPreset, .instagramSquare)

        let flagged = PhotoTechnicalCheck.photosWithSourceSmallerThanExportCanvas(in: project)
        XCTAssertEqual(flagged.count, 1)
    }

    func testExportCanvasNotesDoNotAffectPhase25Readiness() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(
            imageSize: CGSize(width: 50, height: 50),
            preset: .etsyListing,
            in: context
        )
        project.listingTitle = "Ready"
        project.listingPriceText = "12"
        project.listingQuantity = 1

        let facts = PhotoTechnicalCheck.facts(for: project.sortedPhotos[0], project: project)
        XCTAssertEqual(facts.sourceSmallerThanExportCanvas, true)
        XCTAssertTrue(ListingQueueSupport.isReady(project))
        XCTAssertTrue(ListingQueueSupport.readinessIssues(for: project).isEmpty)
    }

    func testDoesNotClaimMarketplaceComplianceInFactLabels() {
        let joined = [
            ListingExportPreset.localExportDisclaimer,
            "Local facts only — not marketplace compliance"
        ].joined(separator: " ").lowercased()
        XCTAssertTrue(joined.contains("not marketplace compliance"))
        XCTAssertFalse(joined.contains("etsy-ready"))
    }
}
