import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase25ListingQueueTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage() -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeReadyProject(name: String, in context: ModelContext) throws -> ItemProject {
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: name, photos: [photo])
        project.listingTitle = "\(name) Title"
        project.listingPriceText = "12.00"
        project.listingQuantity = 1
        project.listingTags = ["tag1", "tag2"]
        context.insert(project)
        return project
    }

    func testAddMultipleProjectsAndPreventDuplicates() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let a = try makeReadyProject(name: "A", in: context)
        let b = try makeReadyProject(name: "B", in: context)

        XCTAssertNotNil(ListingQueueSupport.add(project: a, in: context))
        XCTAssertNotNil(ListingQueueSupport.add(project: b, in: context))
        XCTAssertNil(ListingQueueSupport.add(project: a, in: context))

        let entries = try context.fetch(FetchDescriptor<ListingQueueEntry>())
        XCTAssertEqual(entries.count, 2)
    }

    func testReorderPersistsAcrossContextReload() throws {
        let container = try makeContainer()
        let firstID: PersistentIdentifier
        let secondID: PersistentIdentifier

        do {
            let context = ModelContext(container)
            let a = try makeReadyProject(name: "First", in: context)
            let b = try makeReadyProject(name: "Second", in: context)
            let entryA = ListingQueueSupport.add(project: a, in: context)!
            let entryB = ListingQueueSupport.add(project: b, in: context)!
            XCTAssertEqual(entryA.sortOrder, 0)
            XCTAssertEqual(entryB.sortOrder, 1)

            ListingQueueSupport.reorder([entryA, entryB], from: IndexSet(integer: 1), to: 0)
            try context.save()
            firstID = entryB.persistentModelID
            secondID = entryA.persistentModelID
        }

        let reload = ModelContext(container)
        let entries = try reload.fetch(FetchDescriptor<ListingQueueEntry>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].persistentModelID, firstID)
        XCTAssertEqual(entries[1].persistentModelID, secondID)
        XCTAssertEqual(entries[0].sortOrder, 0)
        XCTAssertEqual(entries[1].sortOrder, 1)
    }

    func testIncompleteDraftShowsNeedsDetails() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let project = ItemProject(name: "Incomplete", photos: [ItemProjectPhoto(localFileName: file, sortOrder: 0)])
        context.insert(project)

        let entry = ListingQueueSupport.add(project: project, in: context)!
        XCTAssertEqual(entry.status, .needsDetails)
        XCTAssertFalse(ListingQueueSupport.isReady(project))
        XCTAssertTrue(ListingQueueSupport.readinessIssues(for: project).contains("Title is required"))
    }

    func testValidDraftShowsReady() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(name: "Ready One", in: context)
        let entry = ListingQueueSupport.add(project: project, in: context)!
        XCTAssertEqual(entry.status, .ready)
        XCTAssertTrue(ListingQueueSupport.isReady(project))
    }

    func testMissingPhotoFilePreventsReady() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(
            name: "Missing File",
            photos: [ItemProjectPhoto(localFileName: "does-not-exist.jpg", sortOrder: 0)]
        )
        project.listingTitle = "Has Title"
        project.listingPriceText = "5"
        project.listingQuantity = 1
        context.insert(project)

        let entry = ListingQueueSupport.add(project: project, in: context)!
        XCTAssertEqual(entry.status, .needsDetails)
        XCTAssertTrue(
            ListingQueueSupport.readinessIssues(for: project)
                .contains("At least one photo file is required")
        )
    }

    func testPrepareQueueValidatesOnlyAndDoesNotComplete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let ready = try makeReadyProject(name: "Prep Ready", in: context)
        let incomplete = ItemProject(name: "Prep Incomplete")
        context.insert(incomplete)

        let readyEntry = ListingQueueSupport.add(project: ready, in: context)!
        let incompleteEntry = ListingQueueSupport.add(project: incomplete, in: context)!

        ListingQueueSupport.prepareQueue([readyEntry, incompleteEntry])

        XCTAssertEqual(readyEntry.status, .ready)
        XCTAssertNotEqual(readyEntry.status, .completed)
        XCTAssertEqual(incompleteEntry.status, .needsDetails)
    }

    func testOnlyReadyCanEnterProcessingDuringPrepare() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let ready = try makeReadyProject(name: "Proc", in: context)
        let entry = ListingQueueSupport.add(project: ready, in: context)!
        XCTAssertEqual(entry.status, .ready)

        // Capture that prepare transitions through processing by using a project that fails mid-check:
        // After setting processing, if we delete photos, prepare would fail — instead verify helper rule:
        // incomplete never ends as processing.
        let incomplete = ItemProject(name: "No")
        context.insert(incomplete)
        let bad = ListingQueueSupport.add(project: incomplete, in: context)!
        ListingQueueSupport.prepareQueue([bad])
        XCTAssertNotEqual(bad.status, .processing)
        XCTAssertEqual(bad.status, .needsDetails)

        ListingQueueSupport.prepareQueue([entry])
        XCTAssertEqual(entry.status, .ready)
    }

    func testDeletingProjectRemovesQueueEntryOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let keep = try makeReadyProject(name: "Keep", in: context)
        let remove = try makeReadyProject(name: "Remove", in: context)
        _ = ListingQueueSupport.add(project: keep, in: context)
        _ = ListingQueueSupport.add(project: remove, in: context)
        try context.save()

        LocalEditStore.deleteAllFiles(for: remove)
        context.delete(remove)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<ListingQueueEntry>())
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.project?.name, "Keep")

        let projects = try context.fetch(FetchDescriptor<ItemProject>())
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects.first?.name, "Keep")
    }

    func testListingDetailChangesUpdateReadiness() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(name: "Sync", in: context)
        let entry = ListingQueueSupport.add(project: project, in: context)!
        XCTAssertEqual(entry.status, .ready)

        project.listingTitle = ""
        ListingQueueSupport.syncReadiness(for: entry)
        XCTAssertEqual(entry.status, .needsDetails)

        project.listingTitle = "Restored"
        ListingQueueSupport.syncReadiness(for: entry)
        XCTAssertEqual(entry.status, .ready)
    }

    func testCompletedOnlyWhenExplicitlySet() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeReadyProject(name: "Mock Complete", in: context)
        let entry = ListingQueueSupport.add(project: project, in: context)!
        entry.status = .completed

        ListingQueueSupport.prepareQueue([entry])
        XCTAssertEqual(entry.status, .completed)

        project.listingTitle = ""
        ListingQueueSupport.syncReadiness(for: entry)
        XCTAssertEqual(entry.status, .needsDetails)
    }
}
