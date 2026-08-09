import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase29BulkEditAndPackageTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor = .systemBlue) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeProject(photoCount: Int, in context: ModelContext) throws -> ItemProject {
        var photos: [ItemProjectPhoto] = []
        for index in 0..<photoCount {
            let file = try LocalEditStore.saveProjectImage(makeImage(color: index % 2 == 0 ? .red : .green))
            photos.append(ItemProjectPhoto(localFileName: file, sortOrder: index))
        }
        let project = ItemProject(name: "Bulk Package", photos: photos)
        project.listingTitle = "Bulk Title"
        project.listingDescription = "Bulk Desc"
        project.listingPriceText = "15.00"
        project.listingQuantity = 2
        project.listingCategory = "Home"
        project.listingTags = ["tag1", "tag2"]
        project.listingMaterials = "wood"
        project.listingShippingProfile = "US"
        project.listingProcessingTime = "1-2 days"
        context.insert(project)
        return project
    }

    func testFullBulkEditAppliesToSelectedPhotos() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 3, in: context)
        let photos = project.sortedPhotos

        var recipe = PhotoEditState()
        recipe.quarterTurns = 2
        recipe.filter = .mono
        recipe.brightness = 0.2
        recipe.contrast = 1.2
        recipe.saturation = 0.8
        recipe.cropRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        recipe.exportPreset = .instagramSquare
        recipe.exportBackground = .black
        recipe.watermarkEnabled = true
        recipe.watermarkText = "Bulk"
        photos[0].savedEditState = recipe

        let applied = BulkEditSupport.apply(
            sourcePhoto: photos[0],
            targetPhotos: [photos[1], photos[2]],
            including: BulkEditSetting.allSelectable,
            on: project
        )
        XCTAssertEqual(applied, 2)
        XCTAssertEqual(photos[1].savedEditState?.quarterTurns, 2)
        XCTAssertEqual(photos[1].savedEditState?.filter, .mono)
        XCTAssertEqual(photos[2].savedEditState?.exportPreset, .instagramSquare)
        XCTAssertEqual(photos[2].savedEditState?.watermarkText, "Bulk")
        XCTAssertTrue(BulkEditSupport.canUndo(project: project))
    }

    func testExcludedSettingsRemainUnchanged() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 2, in: context)
        let photos = project.sortedPhotos

        var source = PhotoEditState()
        source.filter = .sepia
        source.brightness = 0.3
        source.exportPreset = .facebookPost
        photos[0].savedEditState = source

        var target = PhotoEditState()
        target.filter = .vivid
        target.brightness = -0.1
        target.exportPreset = .etsySquare
        photos[1].savedEditState = target

        _ = BulkEditSupport.apply(
            sourcePhoto: photos[0],
            targetPhotos: [photos[1]],
            including: [.filter],
            on: project
        )

        XCTAssertEqual(photos[1].savedEditState?.filter, .sepia)
        XCTAssertEqual(photos[1].savedEditState?.brightness, -0.1)
        XCTAssertEqual(photos[1].savedEditState?.exportPreset, .etsySquare)
    }

    func testSourceImageFilesUnchangedAndNoHistory() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 2, in: context)
        let photos = project.sortedPhotos
        let beforeA = LocalEditStore.projectFileData(fileName: photos[0].localFileName)
        let beforeB = LocalEditStore.projectFileData(fileName: photos[1].localFileName)
        photos[0].savedEditState = PhotoEditState(filter: .mono, quarterTurns: 1)

        let historyBefore = try context.fetch(FetchDescriptor<SavedEdit>()).count
        _ = BulkEditSupport.apply(
            sourcePhoto: photos[0],
            targetPhotos: [photos[1]],
            including: BulkEditSetting.allSelectable,
            on: project
        )
        let historyAfter = try context.fetch(FetchDescriptor<SavedEdit>()).count

        XCTAssertEqual(beforeA, LocalEditStore.projectFileData(fileName: photos[0].localFileName))
        XCTAssertEqual(beforeB, LocalEditStore.projectFileData(fileName: photos[1].localFileName))
        XCTAssertEqual(historyBefore, historyAfter)
        XCTAssertEqual(historyAfter, 0)
    }

    func testUndoRestoresPreviousSettingsOnlyForLastBulkOp() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 3, in: context)
        let photos = project.sortedPhotos

        photos[0].savedEditState = PhotoEditState(filter: .mono)
        photos[1].savedEditState = PhotoEditState(filter: .vivid)
        photos[2].savedEditState = PhotoEditState(filter: .sepia)

        _ = BulkEditSupport.apply(
            sourcePhoto: photos[0],
            targetPhotos: [photos[1]],
            including: [.filter],
            on: project
        )
        XCTAssertEqual(photos[1].savedEditState?.filter, .mono)

        photos[0].savedEditState = PhotoEditState(filter: .original)
        _ = BulkEditSupport.apply(
            sourcePhoto: photos[0],
            targetPhotos: [photos[2]],
            including: [.filter],
            on: project
        )
        XCTAssertEqual(photos[2].savedEditState?.filter, .original)

        let restored = BulkEditSupport.undoLastBulkEdit(on: project)
        XCTAssertEqual(restored, 1)
        XCTAssertEqual(photos[2].savedEditState?.filter, .sepia)
        // First bulk op not restored by second undo slot
        XCTAssertEqual(photos[1].savedEditState?.filter, .mono)
        XCTAssertFalse(BulkEditSupport.canUndo(project: project))
    }

    func testBulkEditStatePersistsAfterRelaunch() throws {
        let container = try makeContainer()
        let projectID: PersistentIdentifier

        do {
            let context = ModelContext(container)
            let project = try makeProject(photoCount: 2, in: context)
            let photos = project.sortedPhotos
            photos[0].savedEditState = PhotoEditState(filter: .sepia, quarterTurns: 3)
            _ = BulkEditSupport.apply(
                sourcePhoto: photos[0],
                targetPhotos: [photos[1]],
                including: [.rotation, .filter],
                on: project
            )
            try context.save()
            projectID = project.persistentModelID
        }

        let reload = ModelContext(container)
        let project = reload.model(for: projectID) as? ItemProject
        XCTAssertNotNil(project)
        XCTAssertEqual(project?.sortedPhotos[1].savedEditState?.quarterTurns, 3)
        XCTAssertEqual(project?.sortedPhotos[1].savedEditState?.filter, .sepia)
        XCTAssertTrue(BulkEditSupport.canUndo(project: project!))
    }

    func testCreateListingPackageFromNewestSuccessfulBatch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 2, in: context)
        let result = try ProjectBatchExporter.export(project: project)
        context.insert(ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            project: project
        ))

        let package = try ListingPackageSupport.createPackage(for: project)
        context.insert(package)

        XCTAssertEqual(package.jpegFileNames, ["01.jpg", "02.jpg"])
        XCTAssertEqual(package.photoCount, 2)
        XCTAssertEqual(package.sourceBatchFolderName, result.batchFolderName)
        let detailsURL = LocalEditStore.listingPackageFileURL(
            folderName: package.packageFolderName,
            fileName: "listing-details.txt"
        )
        XCTAssertNotNil(detailsURL)
        let text = try String(contentsOf: detailsURL!, encoding: .utf8)
        XCTAssertTrue(text.contains("Title: Bulk Title"))
        XCTAssertTrue(text.contains("Price: 15.00"))
        XCTAssertTrue(text.contains("Tags: tag1, tag2"))
        XCTAssertTrue(text.contains("Materials: wood"))
        XCTAssertNotNil(LocalEditStore.listingPackageFileURL(folderName: package.packageFolderName, fileName: "01.jpg"))
    }

    func testPackageCreationFailsWithoutSuccessfulBatch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        XCTAssertThrowsError(try ListingPackageSupport.createPackage(for: project)) { error in
            XCTAssertEqual(error as? ListingPackageError, .noSuccessfulExportBatch)
        }
    }

    func testSharingPackageAttachesUsableFiles() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        let result = try ProjectBatchExporter.export(project: project)
        context.insert(ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            project: project
        ))
        let package = try ListingPackageSupport.createPackage(for: project)
        let urls = package.fileURLs
        XCTAssertTrue(urls.count >= 2)
        let share = ShareBatchItem(urls: urls)
        XCTAssertEqual(share.urls.count, urls.count)
        let jpeg = share.urls.first { $0.pathExtension.lowercased() == "jpg" }!
        let data = try Data(contentsOf: jpeg)
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }

    func testDeletingPackageRemovesOnlyPackageFiles() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        let projectFile = project.sortedPhotos[0].localFileName
        let result = try ProjectBatchExporter.export(project: project)
        context.insert(ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            project: project
        ))
        let package = try ListingPackageSupport.createPackage(for: project)
        context.insert(package)
        let packageFolder = package.packageFolderName
        let batchFolder = result.batchFolderName

        LocalEditStore.deleteListingPackageFolder(folderName: packageFolder)
        context.delete(package)

        XCTAssertNil(LocalEditStore.listingPackageFileURL(folderName: packageFolder, fileName: "01.jpg"))
        XCTAssertNil(LocalEditStore.listingPackageFileURL(folderName: packageFolder, fileName: "listing-details.txt"))
        XCTAssertNotNil(LocalEditStore.exportBatchFileURL(folderName: batchFolder, fileName: "01.jpg"))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: projectFile))
    }

    func testPackagePersistsAfterRelaunch() throws {
        let container = try makeContainer()
        let packageID: PersistentIdentifier

        do {
            let context = ModelContext(container)
            let project = try makeProject(photoCount: 1, in: context)
            let result = try ProjectBatchExporter.export(project: project)
            context.insert(ProjectExportBatch(
                batchFolderName: result.batchFolderName,
                orderedFileNames: result.orderedFileNames,
                successCount: result.successCount,
                project: project
            ))
            let package = try ListingPackageSupport.createPackage(for: project)
            context.insert(package)
            try context.save()
            packageID = package.persistentModelID
        }

        let reload = ModelContext(container)
        let package = reload.model(for: packageID) as? ListingPackage
        XCTAssertNotNil(package)
        XCTAssertEqual(package?.jpegFileNames, ["01.jpg"])
        XCTAssertNotNil(LocalEditStore.listingPackageFileURL(folderName: package!.packageFolderName, fileName: "listing-details.txt"))
    }
}
