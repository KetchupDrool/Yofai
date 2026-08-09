import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase30ListingInformationTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor = .systemBlue) -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeDefaultsStore() -> SellerDefaultsStore {
        let suiteName = "yofai.tests.phase30.defaults.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removeObject(forKey: SellerDefaultsStore.storageKey)
        return SellerDefaultsStore(defaults: suite)
    }

    func testAllNewFieldsPersistAfterRelaunch() throws {
        let container = try makeContainer()
        let projectID: PersistentIdentifier

        do {
            let context = ModelContext(container)
            let project = ItemProject(name: "Persist Info")
            project.listingItemType = .physical
            project.listingCondition = "New"
            project.listingWhoMadeIt = "I did"
            project.listingWhenMade = "2024"
            project.listingSKU = "SKU-1"
            project.listingPersonalizationEnabled = true
            project.listingPersonalizationInstructions = "Add initials"
            project.listingPersonalizationCharacterLimitText = "20"
            project.listingPersonalizationRequired = true
            project.listingVariations = [
                ListingVariation(
                    name: "Size",
                    options: ["S", "M"],
                    priceDifferenceText: "2.00",
                    quantity: 3,
                    sku: "SIZE-S"
                )
            ]
            project.listingAttributes = [
                ListingCategoryAttribute(name: "Primary color", value: "Blue")
            ]
            project.listingReturnPolicy = "30-day returns"
            let photo = ItemProjectPhoto(localFileName: "x.jpg", sortOrder: 0, project: project)
            photo.altText = "Blue mug"
            context.insert(project)
            context.insert(photo)
            try context.save()
            projectID = project.persistentModelID
        }

        let reload = ModelContext(container)
        let fetched = reload.model(for: projectID) as? ItemProject
        XCTAssertEqual(fetched?.listingItemType, .physical)
        XCTAssertEqual(fetched?.listingCondition, "New")
        XCTAssertEqual(fetched?.listingWhoMadeIt, "I did")
        XCTAssertEqual(fetched?.listingWhenMade, "2024")
        XCTAssertEqual(fetched?.listingSKU, "SKU-1")
        XCTAssertTrue(fetched?.listingPersonalizationEnabled == true)
        XCTAssertEqual(fetched?.listingPersonalizationInstructions, "Add initials")
        XCTAssertEqual(fetched?.listingPersonalizationCharacterLimitText, "20")
        XCTAssertTrue(fetched?.listingPersonalizationRequired == true)
        XCTAssertEqual(fetched?.listingVariations.count, 1)
        XCTAssertEqual(fetched?.listingVariations.first?.name, "Size")
        XCTAssertEqual(fetched?.listingVariations.first?.options, ["S", "M"])
        XCTAssertEqual(fetched?.listingVariations.first?.sku, "SIZE-S")
        XCTAssertEqual(fetched?.listingAttributes.first?.name, "Primary color")
        XCTAssertEqual(fetched?.listingReturnPolicy, "30-day returns")
        XCTAssertEqual(fetched?.sortedPhotos.first?.altText, "Blue mug")
    }

    func testVariationAddEditRemoveAndValidation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Vars")
        context.insert(project)

        var variations = [
            ListingVariation(name: "Color", options: ["Red"], sku: "C-RED"),
            ListingVariation(name: "Size", options: ["M"], sku: "S-M")
        ]
        project.listingVariations = variations
        XCTAssertEqual(project.listingVariations.count, 2)

        variations[0].name = "Colour"
        variations[0].options = ["Red", "Blue"]
        project.listingVariations = variations
        XCTAssertEqual(project.listingVariations.first?.name, "Colour")
        XCTAssertEqual(project.listingVariations.first?.options, ["Red", "Blue"])

        variations.remove(at: 1)
        project.listingVariations = variations
        XCTAssertEqual(project.listingVariations.count, 1)

        project.listingVariations = [
            ListingVariation(isEnabled: true, name: "", options: ["A"], sku: "X")
        ]
        XCTAssertTrue(project.listingInformationValidationIssues.contains { $0.contains("name cannot be blank") })

        project.listingVariations = [
            ListingVariation(isEnabled: true, name: "Size", options: ["", "  "], sku: "X")
        ]
        ListingInformationSupport.sanitize(project: project)
        XCTAssertTrue(project.listingInformationValidationIssues.contains { $0.contains("at least one nonblank option") })

        project.listingVariations = [
            ListingVariation(isEnabled: true, name: "Size", options: ["M"], sku: "")
        ]
        XCTAssertTrue(project.listingInformationValidationIssues.contains { $0.contains("SKU cannot be blank") })

        project.listingVariations = [
            ListingVariation(isEnabled: false, name: "", options: [], sku: "")
        ]
        XCTAssertTrue(project.listingInformationValidationIssues.isEmpty)
    }

    func testInvalidPersonalizationShowsSafeError() {
        let project = ItemProject(name: "Pers")
        project.listingPersonalizationEnabled = true
        project.listingPersonalizationCharacterLimitText = "0"
        XCTAssertTrue(
            project.listingInformationValidationIssues.contains {
                $0.contains("character limit must be a positive whole number")
            }
        )

        project.listingPersonalizationCharacterLimitText = "abc"
        XCTAssertFalse(project.listingInformationValidationIssues.isEmpty)

        project.listingPersonalizationCharacterLimitText = "12"
        XCTAssertTrue(project.listingInformationValidationIssues.isEmpty)

        project.listingPersonalizationNotApplicable = true
        project.listingPersonalizationCharacterLimitText = "0"
        XCTAssertTrue(project.listingInformationValidationIssues.isEmpty)
    }

    func testAttributesAddAndBlankRemoval() {
        let project = ItemProject(name: "Attrs")
        project.listingAttributes = [
            ListingCategoryAttribute(name: "Color", value: "Blue"),
            ListingCategoryAttribute(name: "  ", value: "x"),
            ListingCategoryAttribute(name: "Size", value: "  "),
            ListingCategoryAttribute(name: "Material", value: "Clay")
        ]
        ListingInformationSupport.sanitize(project: project)
        XCTAssertEqual(project.listingAttributes.map(\.name), ["Color", "Material"])
        XCTAssertEqual(project.listingAttributes.map(\.value), ["Blue", "Clay"])
    }

    func testAltTextFollowsPhotoReorderAndDelete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let fileA = try LocalEditStore.saveProjectImage(makeImage(color: .red))
        let fileB = try LocalEditStore.saveProjectImage(makeImage(color: .green))
        let fileC = try LocalEditStore.saveProjectImage(makeImage(color: .blue))

        let photoA = ItemProjectPhoto(localFileName: fileA, sortOrder: 0)
        photoA.altText = "Alt A"
        let photoB = ItemProjectPhoto(localFileName: fileB, sortOrder: 1)
        photoB.altText = "Alt B"
        let photoC = ItemProjectPhoto(localFileName: fileC, sortOrder: 2)
        photoC.altText = "Alt C"

        let project = ItemProject(name: "Alt Photos", photos: [photoA, photoB, photoC])
        context.insert(project)
        try context.save()

        var ordered = project.sortedPhotos
        ordered.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        for (index, photo) in ordered.enumerated() {
            photo.sortOrder = index
        }
        XCTAssertEqual(project.sortedPhotos.map(\.altText), ["Alt B", "Alt C", "Alt A"])
        XCTAssertEqual(project.sortedPhotos.map(\.localFileName), [fileB, fileC, fileA])

        let toDelete = project.sortedPhotos[1]
        LocalEditStore.deleteProjectFile(fileName: toDelete.localFileName)
        context.delete(toDelete)
        let remaining = project.sortedPhotos
        for (index, photo) in remaining.enumerated() {
            photo.sortOrder = index
        }
        try context.save()

        XCTAssertEqual(project.sortedPhotos.map(\.altText), ["Alt B", "Alt A"])
        XCTAssertEqual(project.sortedPhotos.map(\.localFileName), [fileB, fileA])
    }

    func testDuplicateCopiesListingInformationWithoutMediaOrQueue() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        photo.altText = "Should not copy with media"
        photo.savedEditState = PhotoEditState(quarterTurns: 1)

        let project = ItemProject(name: "Source", photos: [photo])
        project.listingTitle = "Title"
        project.listingPriceText = "5"
        project.listingItemType = .digital
        project.listingCondition = "Vintage"
        project.listingWhoMadeIt = "Someone else"
        project.listingWhenMade = "1990s"
        project.listingSKU = "TOP"
        project.listingPersonalizationEnabled = true
        project.listingPersonalizationInstructions = "Name"
        project.listingPersonalizationCharacterLimitText = "10"
        project.listingPersonalizationRequired = false
        project.listingVariations = [
            ListingVariation(name: "Finish", options: ["Matte"], sku: "F-M")
        ]
        project.listingAttributes = [
            ListingCategoryAttribute(name: "Style", value: "Modern")
        ]
        project.listingReturnPolicy = "No returns"
        project.listingReturnPolicyNotApplicable = false
        context.insert(project)

        let batchResult = try ProjectBatchExporter.export(project: project)
        context.insert(ProjectExportBatch(
            batchFolderName: batchResult.batchFolderName,
            orderedFileNames: batchResult.orderedFileNames,
            successCount: batchResult.successCount,
            project: project
        ))
        _ = ListingQueueSupport.add(project: project, in: context)
        try context.save()

        let copy = project.duplicateListingDraft(newName: "Copy Info")
        context.insert(copy)
        try context.save()

        XCTAssertEqual(copy.listingItemType, .digital)
        XCTAssertEqual(copy.listingCondition, "Vintage")
        XCTAssertEqual(copy.listingWhoMadeIt, "Someone else")
        XCTAssertEqual(copy.listingWhenMade, "1990s")
        XCTAssertEqual(copy.listingSKU, "TOP")
        XCTAssertTrue(copy.listingPersonalizationEnabled)
        XCTAssertEqual(copy.listingPersonalizationInstructions, "Name")
        XCTAssertEqual(copy.listingPersonalizationCharacterLimitText, "10")
        XCTAssertEqual(copy.listingVariations.first?.name, "Finish")
        XCTAssertEqual(copy.listingAttributes.first?.value, "Modern")
        XCTAssertEqual(copy.listingReturnPolicy, "No returns")

        XCTAssertEqual(copy.photoCount, 0)
        XCTAssertTrue(copy.exportBatches.isEmpty)
        XCTAssertTrue(copy.listingPackages.isEmpty)
        XCTAssertFalse(ListingQueueSupport.isQueued(copy, in: context))
        XCTAssertTrue(ListingQueueSupport.isQueued(project, in: context))
        XCTAssertEqual(project.photoCount, 1)
    }

    func testSellerDefaultsApplyOnlyOnCreateAndDoNotOverwriteExisting() throws {
        let store = makeDefaultsStore()
        var defaults = SellerDefaults()
        defaults.itemType = .physical
        defaults.condition = "New"
        defaults.whoMadeIt = "I did"
        defaults.whenMade = "Made to order"
        defaults.returnPolicy = "Returns OK"
        store.save(defaults)

        let reloaded = store.load()
        XCTAssertEqual(reloaded.itemType, .physical)
        XCTAssertEqual(reloaded.condition, "New")
        XCTAssertEqual(reloaded.whoMadeIt, "I did")
        XCTAssertEqual(reloaded.whenMade, "Made to order")
        XCTAssertEqual(reloaded.returnPolicy, "Returns OK")

        let container = try makeContainer()
        let context = ModelContext(container)
        let existing = ItemProject(name: "Existing")
        existing.listingCondition = "Keep Me"
        existing.listingWhoMadeIt = "Original Maker"
        existing.listingItemType = .digital
        existing.listingReturnPolicy = "Original Policy"
        context.insert(existing)
        try context.save()

        // Changing/saving defaults must not mutate existing projects.
        var changed = store.load()
        changed.condition = "Should Not Apply To Existing"
        store.save(changed)
        XCTAssertEqual(existing.listingCondition, "Keep Me")
        XCTAssertEqual(existing.listingWhoMadeIt, "Original Maker")
        XCTAssertEqual(existing.listingItemType, .digital)
        XCTAssertEqual(existing.listingReturnPolicy, "Original Policy")

        let fresh = ItemProject(name: "Fresh")
        store.load().apply(to: fresh)
        XCTAssertEqual(fresh.listingItemType, .physical)
        XCTAssertEqual(fresh.listingCondition, "Should Not Apply To Existing")
        XCTAssertEqual(fresh.listingWhoMadeIt, "I did")
        XCTAssertEqual(fresh.listingWhenMade, "Made to order")
        XCTAssertEqual(fresh.listingReturnPolicy, "Returns OK")
        XCTAssertEqual(existing.listingCondition, "Keep Me")
    }

    func testListingInformationReviewReportsFilledMissingNAAndReview() {
        let project = ItemProject(name: "Review")
        project.listingItemType = .physical
        project.listingConditionNotApplicable = true
        project.listingWhoMadeItNotApplicable = true
        project.listingWhenMadeNotApplicable = true
        project.listingSKUNotApplicable = true
        project.listingPersonalizationNotApplicable = true
        project.listingVariationsNotApplicable = true
        project.listingAttributesNotApplicable = true
        project.listingReturnPolicy = ""
        project.listingReturnPolicyNotApplicable = false

        var review = ListingInformationSupport.review(for: project)
        XCTAssertTrue(review.filled.contains { $0.key == "itemType" })
        XCTAssertTrue(review.notApplicable.contains { $0.key == "condition" })
        XCTAssertTrue(review.missing.contains { $0.key == "returnPolicy" })

        project.listingPersonalizationNotApplicable = false
        project.listingPersonalizationEnabled = true
        project.listingPersonalizationCharacterLimitText = "bad"
        review = ListingInformationSupport.review(for: project)
        XCTAssertTrue(review.needingReview.contains { $0.key == "personalization" })

        // Review is separate from Phase 25 readiness.
        XCTAssertFalse(ListingQueueSupport.isReady(project))
        project.listingTitle = "Ready Title"
        project.listingPriceText = "10"
        project.listingQuantity = 1
        let fileName = "missing-file-for-readiness.jpg"
        let photo = ItemProjectPhoto(localFileName: fileName, sortOrder: 0, project: project)
        project.photos = [photo]
        // Without a real file, readiness stays false — review still reports local info independently.
        XCTAssertFalse(ListingQueueSupport.isReady(project))
        XCTAssertFalse(review.fields.isEmpty)
    }

    func testSanitizeRemovesBlankAltTextWhitespaceOnly() {
        let photo = ItemProjectPhoto(sortOrder: 0)
        photo.altText = "   "
        let project = ItemProject(name: "Alt", photos: [photo])
        ListingInformationSupport.sanitize(project: project)
        XCTAssertEqual(project.sortedPhotos.first?.altText, "")
    }

    func testPhase25ReadinessUnchangedByListingInformation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Ready", photos: [photo])
        project.listingTitle = "Title"
        project.listingPriceText = "9"
        project.listingQuantity = 1
        project.listingTags = ["a"]
        // Incomplete listing information should not block Phase 25 readiness.
        project.listingCondition = ""
        project.listingSKU = ""
        context.insert(project)
        XCTAssertTrue(ListingQueueSupport.isReady(project))
        XCTAssertTrue(project.listingInformationReview.missing.contains { $0.key == "condition" })
    }
}
