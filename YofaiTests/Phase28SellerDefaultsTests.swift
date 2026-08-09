import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase28SellerDefaultsTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeDefaultsStore() -> SellerDefaultsStore {
        let suiteName = "yofai.tests.sellerDefaults.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removeObject(forKey: SellerDefaultsStore.storageKey)
        return SellerDefaultsStore(defaults: suite)
    }

    private func makeImage() -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemIndigo.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    func testSaveSellerDefaultsPersistAfterRelaunch() {
        let suiteName = "yofai.tests.persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removeObject(forKey: SellerDefaultsStore.storageKey)

        var value = SellerDefaults()
        value.category = "Home & Living"
        value.materials = "ceramic"
        value.shippingProfile = "US standard"
        value.processingTime = "1-3 days"
        value.exportPreset = .etsyListing
        value.exportBackground = .softGray
        value.watermarkText = "ShopMark"

        SellerDefaultsStore(defaults: defaults).save(value)

        let reloaded = SellerDefaultsStore(defaults: defaults).load()
        XCTAssertEqual(reloaded.category, "Home & Living")
        XCTAssertEqual(reloaded.materials, "ceramic")
        XCTAssertEqual(reloaded.shippingProfile, "US standard")
        XCTAssertEqual(reloaded.processingTime, "1-3 days")
        XCTAssertEqual(reloaded.exportPreset, .etsyListing)
        XCTAssertEqual(reloaded.exportBackground, .softGray)
        XCTAssertEqual(reloaded.watermarkText, "ShopMark")
    }

    func testCreateWithDefaultsPrefillsFields() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        var defaults = SellerDefaults()
        defaults.category = "Art"
        defaults.materials = "clay"
        defaults.shippingProfile = "Free"
        defaults.processingTime = "3-5 days"
        defaults.exportPreset = .instagramSquare
        defaults.exportBackground = .black
        defaults.watermarkText = "Yofai"

        let project = ItemProject(name: "With Defaults")
        defaults.apply(to: project)
        context.insert(project)

        XCTAssertEqual(project.listingCategory, "Art")
        XCTAssertEqual(project.listingMaterials, "clay")
        XCTAssertEqual(project.listingShippingProfile, "Free")
        XCTAssertEqual(project.listingProcessingTime, "3-5 days")
        XCTAssertEqual(project.listingExportPreset, .instagramSquare)
        XCTAssertEqual(project.listingExportBackground, .black)
        XCTAssertEqual(project.listingWatermarkText, "Yofai")
        XCTAssertTrue(project.listingWatermarkEnabled)
        // Defaults do not set title/price
        XCTAssertEqual(project.listingTitle, "")
    }

    func testBlankCreateDoesNotApplyDefaults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        var defaults = SellerDefaults()
        defaults.category = "ShouldNotAppear"
        // Blank create path: do not call apply
        let project = ItemProject(name: "Blank")
        context.insert(project)
        XCTAssertEqual(project.listingCategory, "")
        XCTAssertEqual(project.listingExportPreset, .etsySquare)
        XCTAssertFalse(project.listingWatermarkEnabled)
        _ = defaults // retained to show defaults exist but unused
    }

    func testChangingProjectDoesNotChangeSellerDefaults() {
        let store = makeDefaultsStore()
        var defaults = SellerDefaults()
        defaults.category = "Saved Cat"
        store.save(defaults)

        let project = ItemProject(name: "Edit Me")
        store.load().apply(to: project)
        project.listingCategory = "Changed On Project"
        project.listingMaterials = "changed materials"

        let still = store.load()
        XCTAssertEqual(still.category, "Saved Cat")
        XCTAssertEqual(still.materials, "")
    }

    func testDuplicateCopiesListingAndExportOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let file = try LocalEditStore.saveProjectImage(makeImage())
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        photo.savedEditState = PhotoEditState(quarterTurns: 1)
        let project = ItemProject(name: "Original", photos: [photo])
        project.listingTitle = "Title A"
        project.listingDescription = "Desc"
        project.listingPriceText = "12.50"
        project.listingQuantity = 3
        project.listingCategory = "Cat"
        project.listingTags = ["a", "b"]
        project.listingMaterials = "wood"
        project.listingShippingProfile = "Ship"
        project.listingProcessingTime = "2 days"
        project.listingExportPreset = .facebookPost
        project.listingExportBackground = .black
        project.listingWatermarkEnabled = true
        project.listingWatermarkText = "WM"
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

        let originalPhotoCount = project.photoCount
        let originalFile = project.sortedPhotos[0].localFileName
        let originalBatchFolder = project.exportBatches.first?.batchFolderName

        let copy = project.duplicateListingDraft(newName: "Duplicated Name")
        context.insert(copy)
        try context.save()

        XCTAssertEqual(copy.name, "Duplicated Name")
        XCTAssertEqual(copy.listingTitle, "Title A")
        XCTAssertEqual(copy.listingDescription, "Desc")
        XCTAssertEqual(copy.listingPriceText, "12.50")
        XCTAssertEqual(copy.listingQuantity, 3)
        XCTAssertEqual(copy.listingCategory, "Cat")
        XCTAssertEqual(copy.listingTags, ["a", "b"])
        XCTAssertEqual(copy.listingMaterials, "wood")
        XCTAssertEqual(copy.listingShippingProfile, "Ship")
        XCTAssertEqual(copy.listingProcessingTime, "2 days")
        XCTAssertEqual(copy.listingExportPreset, .facebookPost)
        XCTAssertEqual(copy.listingExportBackground, .black)
        XCTAssertTrue(copy.listingWatermarkEnabled)
        XCTAssertEqual(copy.listingWatermarkText, "WM")

        XCTAssertEqual(copy.photoCount, 0)
        XCTAssertTrue(copy.exportBatches.isEmpty)
        XCTAssertFalse(ListingQueueSupport.isQueued(copy, in: context))
        XCTAssertEqual(project.photoCount, originalPhotoCount)
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: originalFile))
        XCTAssertNotNil(originalBatchFolder)
        XCTAssertNotNil(LocalEditStore.exportBatchFileURL(folderName: originalBatchFolder!, fileName: "01.jpg"))
        XCTAssertTrue(ListingQueueSupport.isQueued(project, in: context))
    }

    func testDuplicatedProjectPersistsAfterRelaunch() throws {
        let container = try makeContainer()
        let copyID: PersistentIdentifier

        do {
            let context = ModelContext(container)
            let project = ItemProject(name: "Source")
            project.listingTitle = "Persist Dup"
            project.listingPriceText = "9"
            project.listingCategory = "Persist Cat"
            project.listingExportPreset = .marketplace
            context.insert(project)
            let copy = project.duplicateListingDraft(newName: "Copy Persist")
            context.insert(copy)
            try context.save()
            copyID = copy.persistentModelID
        }

        let reload = ModelContext(container)
        let copy = reload.model(for: copyID) as? ItemProject
        XCTAssertEqual(copy?.name, "Copy Persist")
        XCTAssertEqual(copy?.listingTitle, "Persist Dup")
        XCTAssertEqual(copy?.listingCategory, "Persist Cat")
        XCTAssertEqual(copy?.listingExportPreset, .marketplace)
        XCTAssertEqual(copy?.photoCount, 0)
    }

    func testClearDefaultsRemovesOnlyDefaults() {
        let suiteName = "yofai.tests.clear.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SellerDefaultsStore(defaults: defaults)
        var value = SellerDefaults()
        value.category = "Clear Me"
        store.save(value)
        XCTAssertTrue(store.hasSavedDefaults)

        store.clear()
        XCTAssertFalse(store.hasSavedDefaults)
        XCTAssertEqual(store.load().category, "")
    }

    func testDuplicateRequiresNewNameTrim() {
        let project = ItemProject(name: "A")
        project.listingTitle = "T"
        let copy = project.duplicateListingDraft(newName: "  New Name  ")
        XCTAssertEqual(copy.name, "New Name")
    }
}
