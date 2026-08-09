import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase31AIListingAssistantTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor = .systemTeal) -> UIImage {
        let size = CGSize(width: 20, height: 20)
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeProjectWithPhotos(count: Int, in context: ModelContext) throws -> ItemProject {
        var photos: [ItemProjectPhoto] = []
        for index in 0..<count {
            let file = try LocalEditStore.saveProjectImage(makeImage(color: index % 2 == 0 ? .red : .blue))
            let photo = ItemProjectPhoto(localFileName: file, sortOrder: index)
            photo.altText = "Alt \(index + 1)"
            photos.append(photo)
        }
        let project = ItemProject(name: "AI Project", photos: photos)
        project.listingTitle = "Original Title"
        project.listingDescription = "Original Desc"
        project.listingPriceText = "12.00"
        project.listingQuantity = 4
        project.listingCategory = "Original Cat"
        project.listingTags = ["old"]
        project.listingMaterials = "Original materials"
        project.listingShippingProfile = "Ship"
        project.listingProcessingTime = "2 days"
        project.listingReturnPolicy = "Returns"
        project.listingSKU = "SKU-KEEP"
        project.listingCondition = "New"
        project.listingItemType = .physical
        project.listingWhoMadeIt = "Maker"
        project.listingWhenMade = "2020"
        project.listingPersonalizationEnabled = true
        project.listingPersonalizationCharacterLimitText = "10"
        project.listingVariations = [ListingVariation(name: "Size", options: ["M"], sku: "M1")]
        project.listingExportPreset = .etsyListing
        project.listingWatermarkEnabled = true
        project.listingWatermarkText = "WM"
        context.insert(project)
        return project
    }

    func testCreateAIPreparationWithPhotosAndTypes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 2, in: context)
        let ids = project.sortedPhotos.map(\.stableID)
        let record = AIPreparationRecord(
            project: project,
            selectedPhotoIDs: ids,
            suggestionTypes: [.listingTitle, .tags, .photoAltText],
            includedContextFields: [.title, .materials],
            excludedContextFields: [.price, .sku]
        )
        context.insert(record)
        try context.save()

        XCTAssertEqual(project.aiPreparations.count, 1)
        XCTAssertEqual(record.selectedPhotoIDs, ids)
        XCTAssertEqual(record.suggestionTypes, [.listingTitle, .tags, .photoAltText])
        XCTAssertEqual(Set(record.excludedContextFields), [.price, .sku])
        XCTAssertEqual(record.status, .draft)
    }

    func testSelectedPhotosPersistInProjectOrderAfterRelaunch() throws {
        let container = try makeContainer()
        let recordID: PersistentIdentifier
        let expectedIDs: [UUID]

        do {
            let context = ModelContext(container)
            let project = try makeProjectWithPhotos(count: 3, in: context)
            // Select photos 1 and 3 in project order (skip middle).
            let ordered = project.sortedPhotos
            expectedIDs = [ordered[0].stableID, ordered[2].stableID]
            let record = AIPreparationRecord(
                project: project,
                status: .readyForAI,
                selectedPhotoIDs: expectedIDs,
                suggestionTypes: [.description]
            )
            context.insert(record)
            try context.save()
            recordID = record.persistentModelID
        }

        let reload = ModelContext(container)
        let record = reload.model(for: recordID) as? AIPreparationRecord
        XCTAssertEqual(record?.selectedPhotoIDs, expectedIDs)
        XCTAssertEqual(record?.status, .readyForAI)
    }

    func testIncludedAndExcludedContextPersist() throws {
        let container = try makeContainer()
        let recordID: PersistentIdentifier
        do {
            let context = ModelContext(container)
            let project = try makeProjectWithPhotos(count: 1, in: context)
            let record = AIPreparationRecord(
                project: project,
                selectedPhotoIDs: [project.sortedPhotos[0].stableID],
                suggestionTypes: [.materials],
                includedContextFields: [.materials, .category],
                excludedContextFields: [.price, .quantity, .shippingProfile]
            )
            context.insert(record)
            try context.save()
            recordID = record.persistentModelID
        }
        let record = ModelContext(container).model(for: recordID) as? AIPreparationRecord
        XCTAssertEqual(Set(record?.includedContextFields ?? []), [.materials, .category])
        XCTAssertEqual(Set(record?.excludedContextFields ?? []), [.price, .quantity, .shippingProfile])
    }

    func testDisconnectedProviderReportsNoNetworkAndFailsRequest() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 1, in: context)
        let record = AIPreparationRecord(
            project: project,
            status: .readyForAI,
            selectedPhotoIDs: [project.sortedPhotos[0].stableID],
            suggestionTypes: [.listingTitle]
        )
        context.insert(record)

        let provider = DisconnectedAIListingProvider.shared
        XCTAssertFalse(provider.isConnected)
        XCTAssertEqual(provider.statusMessage, "AI is not connected yet")

        await AIListingAssistantSupport.requestSuggestions(for: record, project: project, provider: provider)
        XCTAssertEqual(record.status, .failed)
        XCTAssertTrue(record.errorMessage.contains("not connected"))
        XCTAssertTrue(record.suggestions.isEmpty)
    }

    func testMockSuggestionsOnlyViaMockProvider() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 2, in: context)
        let ids = project.sortedPhotos.map(\.stableID)
        let record = AIPreparationRecord(
            project: project,
            selectedPhotoIDs: ids,
            suggestionTypes: [.listingTitle, .tags, .photoOrderRecommendation]
        )
        context.insert(record)

        let mock = MockAIListingProvider()
        await AIListingAssistantSupport.requestSuggestions(for: record, project: project, provider: mock)
        XCTAssertEqual(record.status, .awaitingReview)
        XCTAssertEqual(record.suggestions.count, 3)
        XCTAssertEqual(record.suggestions.first?.source, .futureAI)
        XCTAssertEqual(record.suggestions.first?.textValue, "Mock Title")

        // Production disconnected path must not invent the same content.
        let placeholders = AIListingAssistantSupport.makePlaceholderSuggestions(
            types: [.listingTitle],
            selectedPhotoIDs: ids
        )
        XCTAssertEqual(placeholders.first?.source, .placeholderManual)
        XCTAssertEqual(placeholders.first?.textValue, "")
    }

    func testSellerEditDiscardBeforeApply() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 1, in: context)
        let record = AIPreparationRecord(
            project: project,
            selectedPhotoIDs: [project.sortedPhotos[0].stableID],
            suggestionTypes: [.listingTitle, .description]
        )
        var suggestions = [
            AISuggestionDraft(type: .listingTitle, source: .futureAI, textValue: "AI Title", isApproved: true),
            AISuggestionDraft(type: .description, source: .futureAI, textValue: "AI Desc", isApproved: true)
        ]
        suggestions[0].textValue = "Seller Title"
        suggestions[0].source = .sellerEdited
        suggestions[1].isDiscarded = true
        suggestions[1].isApproved = false
        record.suggestions = suggestions
        context.insert(record)

        let changes = try AIListingAssistantSupport.applyApprovedSuggestions(
            from: record,
            to: project,
            confirmPhotoReorder: false
        )
        XCTAssertEqual(project.listingTitle, "Seller Title")
        XCTAssertEqual(project.listingDescription, "Original Desc")
        XCTAssertTrue(changes.contains { $0.contains("Title") })
        XCTAssertEqual(record.suggestions.first?.source, .applied)
    }

    func testApplyChangesOnlyAllowedFieldsAndPreservesProtected() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 2, in: context)
        _ = ListingQueueSupport.add(project: project, in: context)
        let queueStatusBefore = project.queueEntries.first?.status

        let ids = project.sortedPhotos.map(\.stableID)
        let record = AIPreparationRecord(project: project, selectedPhotoIDs: ids, suggestionTypes: AISuggestionType.allCases)
        record.suggestions = [
            AISuggestionDraft(type: .listingTitle, textValue: "New Title", isApproved: true),
            AISuggestionDraft(type: .description, textValue: "New Desc", isApproved: true),
            AISuggestionDraft(type: .tags, tagsValue: ["a", "b"], isApproved: true),
            AISuggestionDraft(type: .categoryText, textValue: "New Cat", isApproved: true),
            AISuggestionDraft(type: .materials, textValue: "Clay", isApproved: true),
            AISuggestionDraft(
                type: .photoAltText,
                altTextByPhotoID: [
                    ids[0].uuidString: "Alt new 1",
                    ids[1].uuidString: "Alt new 2"
                ],
                isApproved: true
            )
        ]
        context.insert(record)

        _ = try AIListingAssistantSupport.applyApprovedSuggestions(
            from: record,
            to: project,
            confirmPhotoReorder: false
        )

        XCTAssertEqual(project.listingTitle, "New Title")
        XCTAssertEqual(project.listingDescription, "New Desc")
        XCTAssertEqual(project.listingTags, ["a", "b"])
        XCTAssertEqual(project.listingCategory, "New Cat")
        XCTAssertEqual(project.listingMaterials, "Clay")
        XCTAssertEqual(project.sortedPhotos[0].altText, "Alt new 1")
        XCTAssertEqual(project.sortedPhotos[1].altText, "Alt new 2")

        XCTAssertEqual(project.listingPriceText, "12.00")
        XCTAssertEqual(project.listingQuantity, 4)
        XCTAssertEqual(project.listingShippingProfile, "Ship")
        XCTAssertEqual(project.listingProcessingTime, "2 days")
        XCTAssertEqual(project.listingReturnPolicy, "Returns")
        XCTAssertEqual(project.listingSKU, "SKU-KEEP")
        XCTAssertEqual(project.listingCondition, "New")
        XCTAssertEqual(project.listingItemType, .physical)
        XCTAssertEqual(project.listingWhoMadeIt, "Maker")
        XCTAssertEqual(project.listingWhenMade, "2020")
        XCTAssertTrue(project.listingPersonalizationEnabled)
        XCTAssertEqual(project.listingVariations.first?.name, "Size")
        XCTAssertEqual(project.listingExportPreset, .etsyListing)
        XCTAssertTrue(project.listingWatermarkEnabled)
        XCTAssertEqual(project.listingWatermarkText, "WM")
        XCTAssertEqual(project.queueEntries.first?.status, queueStatusBefore)
        XCTAssertTrue(ListingQueueSupport.isQueued(project, in: context))
    }

    func testPhotoReorderRequiresConfirmationAndPreservesAltText() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 3, in: context)
        let ids = project.sortedPhotos.map(\.stableID)
        let altByID = Dictionary(uniqueKeysWithValues: project.sortedPhotos.map { ($0.stableID, $0.altText) })
        let reversed = Array(ids.reversed())

        let record = AIPreparationRecord(
            project: project,
            selectedPhotoIDs: ids,
            suggestionTypes: [.photoOrderRecommendation]
        )
        record.suggestions = [
            AISuggestionDraft(
                type: .photoOrderRecommendation,
                proposedPhotoOrderIDs: reversed.map(\.uuidString),
                isApproved: true
            )
        ]
        context.insert(record)

        XCTAssertThrowsError(
            try AIListingAssistantSupport.applyApprovedSuggestions(
                from: record,
                to: project,
                confirmPhotoReorder: false
            )
        ) { error in
            XCTAssertEqual(error as? AIApplyError, .photoReorderNeedsConfirmation)
        }
        XCTAssertEqual(project.sortedPhotos.map(\.stableID), ids)

        _ = try AIListingAssistantSupport.applyApprovedSuggestions(
            from: record,
            to: project,
            confirmPhotoReorder: true
        )
        XCTAssertEqual(project.sortedPhotos.map(\.stableID), reversed)
        for photo in project.photos {
            XCTAssertEqual(photo.altText, altByID[photo.stableID])
        }
    }

    func testDeletingProjectDeletesAIPreparations() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 1, in: context)
        let record = AIPreparationRecord(
            project: project,
            selectedPhotoIDs: [project.sortedPhotos[0].stableID],
            suggestionTypes: [.listingTitle]
        )
        context.insert(record)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<AIPreparationRecord>()).count, 1)

        for photo in project.photos {
            LocalEditStore.deleteProjectFile(fileName: photo.localFileName)
        }
        context.delete(project)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<AIPreparationRecord>())
        XCTAssertTrue(remaining.isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ItemProject>()).count, 0)
    }

    func testDuplicateDoesNotCopyAIPreparations() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 1, in: context)
        let record = AIPreparationRecord(
            project: project,
            selectedPhotoIDs: [project.sortedPhotos[0].stableID],
            suggestionTypes: [.listingTitle],
            suggestions: [AISuggestionDraft(type: .listingTitle, textValue: "Secret")]
        )
        context.insert(record)
        try context.save()

        let copy = project.duplicateListingDraft(newName: "Dup")
        context.insert(copy)
        try context.save()

        XCTAssertEqual(copy.aiPreparations.count, 0)
        XCTAssertEqual(project.aiPreparations.count, 1)
        XCTAssertEqual(copy.listingTitle, project.listingTitle)
        XCTAssertEqual(copy.photoCount, 0)
    }

    func testSchemaIncludesAIPreparationAndPhase25Unchanged() throws {
        XCTAssertTrue(YofaiModelSchema.models.contains { String(describing: $0).contains("AIPreparationRecord") })
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProjectWithPhotos(count: 1, in: context)
        project.listingTitle = "Ready"
        project.listingPriceText = "9"
        project.listingQuantity = 1
        XCTAssertTrue(ListingQueueSupport.isReady(project))
        // Incomplete AI prep does not affect readiness.
        let record = AIPreparationRecord(project: project, status: .draft)
        context.insert(record)
        XCTAssertTrue(ListingQueueSupport.isReady(project))
    }
}
