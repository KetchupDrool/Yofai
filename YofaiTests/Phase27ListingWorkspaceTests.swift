import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase27ListingWorkspaceTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeReadyProject(name: String, in context: ModelContext) throws -> ItemProject {
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: name, photos: [photo])
        project.listingTitle = "\(name) Title"
        project.listingPriceText = "18.00"
        project.listingQuantity = 2
        project.listingTags = ["handmade"]
        context.insert(project)
        return project
    }

    func testWorkspaceReflectsSavedDetailsAndPhotoOrder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let fileA = try LocalEditStore.saveProjectImage(makeImage())
        let fileB = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(
            name: "Workspace Lamp",
            photos: [
                ItemProjectPhoto(localFileName: fileA, sortOrder: 0),
                ItemProjectPhoto(localFileName: fileB, sortOrder: 1)
            ]
        )
        project.listingTitle = "Ceramic Lamp"
        project.listingPriceText = "40"
        project.listingQuantity = 1
        context.insert(project)

        XCTAssertEqual(project.trimmedListingTitle, "Ceramic Lamp")
        XCTAssertEqual(project.sortedPhotos.map(\.localFileName), [fileA, fileB])
        XCTAssertTrue(ListingQueueSupport.isReady(project))

        // Reorder
        project.sortedPhotos[0].sortOrder = 1
        project.sortedPhotos[1].sortOrder = 0
        XCTAssertEqual(project.sortedPhotos.map(\.localFileName), [fileB, fileA])
    }

    func testMissingReadinessFieldsAreAccurate() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Empty")
        context.insert(project)

        let issues = ListingQueueSupport.readinessIssues(for: project)
        XCTAssertTrue(issues.contains("At least one photo file is required"))
        XCTAssertTrue(issues.contains("Title is required"))
        XCTAssertTrue(issues.contains("Price is required"))
        XCTAssertEqual(ListingQueueSupport.missingRequiredSummary(for: project), issues.joined(separator: " · "))
    }

    func testAddAndRemoveFromQueueThroughWorkspaceHelpers() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(name: "Queue Me", in: context)

        XCTAssertFalse(ListingQueueSupport.isQueued(project, in: context))
        let entry = ListingQueueSupport.add(project: project, in: context)
        XCTAssertNotNil(entry)
        XCTAssertTrue(ListingQueueSupport.isQueued(project, in: context))
        XCTAssertEqual(ListingQueueSupport.queueEntry(for: project, in: context)?.status, .ready)

        ListingQueueSupport.remove(entry!, in: context)
        XCTAssertFalse(ListingQueueSupport.isQueued(project, in: context))
    }

    func testExportBatchAppearsAndIsShareable() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(name: "Export WS", in: context)

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            project: project
        )
        context.insert(batch)

        XCTAssertEqual(project.sortedExportBatches.first?.successCount, 1)
        XCTAssertTrue(project.sortedExportBatches.first?.hasShareableFiles == true)
        let share = ShareBatchItem(urls: batch.fileURLs)
        XCTAssertEqual(share.urls.count, 1)
        XCTAssertNotNil(UIImage(data: try Data(contentsOf: share.urls[0])))
    }

    func testPrepareReadyListingsValidatesWithoutCompletion() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let ready = try makeReadyProject(name: "Ready WS", in: context)
        let incomplete = ItemProject(name: "Needs Work")
        context.insert(incomplete)

        let readyEntry = ListingQueueSupport.add(project: ready, in: context)!
        let needsEntry = ListingQueueSupport.add(project: incomplete, in: context)!

        let summary = ListingQueueSupport.prepareReadyListings([readyEntry, needsEntry])

        XCTAssertEqual(summary.readyCount, 1)
        XCTAssertEqual(summary.needsDetailsCount, 1)
        XCTAssertEqual(summary.failedValidationCount, 0)
        XCTAssertEqual(readyEntry.status, .ready)
        XCTAssertEqual(needsEntry.status, .needsDetails)
        XCTAssertNotEqual(readyEntry.status, .completed)
        XCTAssertNotEqual(needsEntry.status, .completed)
        XCTAssertTrue(summary.displayMessage.contains("Nothing was uploaded"))
    }

    func testPrepareReadyListingsSkipsNeedsDetails() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let incomplete = ItemProject(name: "Skip Me")
        context.insert(incomplete)
        let entry = ListingQueueSupport.add(project: incomplete, in: context)!
        XCTAssertEqual(entry.status, .needsDetails)

        _ = ListingQueueSupport.prepareReadyListings([entry])
        XCTAssertEqual(entry.status, .needsDetails)
        XCTAssertNotEqual(entry.status, .processing)
        XCTAssertNotEqual(entry.status, .ready)
    }

    func testWorkspaceDataPersistsAfterRelaunch() throws {
        let container = try makeContainer()
        let projectID: PersistentIdentifier

        do {
            let context = ModelContext(container)
            let project = try makeReadyProject(name: "Persist WS", in: context)
            _ = ListingQueueSupport.add(project: project, in: context)
            let result = try ProjectBatchExporter.export(project: project)
            context.insert(ProjectExportBatch(
                batchFolderName: result.batchFolderName,
                orderedFileNames: result.orderedFileNames,
                successCount: result.successCount,
                project: project
            ))
            try context.save()
            projectID = project.persistentModelID
        }

        let reload = ModelContext(container)
        let project = reload.model(for: projectID) as? ItemProject
        XCTAssertNotNil(project)
        XCTAssertEqual(project?.listingTitle, "Persist WS Title")
        XCTAssertTrue(ListingQueueSupport.isQueued(project!, in: reload))
        XCTAssertEqual(project?.exportBatches.count, 1)
        XCTAssertTrue(ListingQueueSupport.isReady(project!))
    }

    func testEntryPointsUseSameProjectModel() throws {
        // Workspace and Project Detail share ItemProject as Free primary listing.
        // Phase 61 adds MarketplaceListingDraft only as additive Pro multi-market drafts.
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(name: "Shared", in: context)
        project.listingTitle = "Updated Title"
        XCTAssertEqual(project.listingTitle, "Updated Title")
        XCTAssertTrue(YofaiModelSchema.models.contains { $0 == ItemProject.self })
        XCTAssertTrue(YofaiModelSchema.models.contains { $0 == MarketplaceListingDraft.self })
        XCTAssertTrue(project.marketplaceDrafts.isEmpty)
    }
}
