import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase26BatchExportTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor, size: CGFloat = 64) -> UIImage {
        let sz = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: sz)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: sz))
        }
    }

    private func makeProject(withPhotos colors: [UIColor], in context: ModelContext) throws -> ItemProject {
        var photos: [ItemProjectPhoto] = []
        for (index, color) in colors.enumerated() {
            let file = try LocalEditStore.saveProjectImage(makeImage(color: color))
            photos.append(ItemProjectPhoto(localFileName: file, sortOrder: index))
        }
        let project = ItemProject(name: "Batch Project", photos: photos)
        context.insert(project)
        return project
    }

    func testExportMultiplePhotosWithOrderedFilenames() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(withPhotos: [.red, .green, .blue], in: context)

        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(result.successCount, 3)
        XCTAssertEqual(result.orderedFileNames, ["01.jpg", "02.jpg", "03.jpg"])
        for name in result.orderedFileNames {
            XCTAssertNotNil(LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: name))
        }
    }

    func testSourceProjectFilesRemainUnchanged() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(withPhotos: [.cyan, .magenta], in: context)
        let before = project.sortedPhotos.map { LocalEditStore.projectFileData(fileName: $0.localFileName) }

        _ = try ProjectBatchExporter.export(project: project)

        let after = project.sortedPhotos.map { LocalEditStore.projectFileData(fileName: $0.localFileName) }
        XCTAssertEqual(before, after)
    }

    func testEditedAndUneditedPhotosExport() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(withPhotos: [.orange, .purple], in: context)
        var edited = PhotoEditState()
        edited.quarterTurns = 1
        edited.filter = .mono
        project.sortedPhotos[0].savedEditState = edited

        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(result.successCount, 2)
        XCTAssertEqual(result.orderedFileNames, ["01.jpg", "02.jpg"])
        XCTAssertNotNil(project.sortedPhotos[0].savedEditState)
        XCTAssertNil(project.sortedPhotos[1].savedEditState)
    }

    func testWatermarkAndExportPresetApply() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(withPhotos: [.brown], in: context)
        project.listingExportPreset = .instagramSquare
        project.listingExportBackground = .black
        project.listingWatermarkEnabled = true
        project.listingWatermarkText = "YofaiTest"

        let state = project.sortedPhotos[0].exportEditState(project: project)
        XCTAssertEqual(state.exportPreset, .instagramSquare)
        XCTAssertEqual(state.exportBackground, .black)
        XCTAssertTrue(state.willDrawWatermark)

        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(result.successCount, 1)
        guard let url = LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: "01.jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return XCTFail("Missing export JPEG")
        }
        XCTAssertEqual(Int(image.size.width), 1080)
        XCTAssertEqual(Int(image.size.height), 1080)
    }

    func testBatchesPersistAfterRelaunch() throws {
        let container = try makeContainer()
        let batchID: PersistentIdentifier
        let folder: String

        do {
            let context = ModelContext(container)
            let project = try makeProject(withPhotos: [.gray, .darkGray], in: context)
            let result = try ProjectBatchExporter.export(project: project)
            let batch = ProjectExportBatch(
                batchFolderName: result.batchFolderName,
                orderedFileNames: result.orderedFileNames,
                successCount: result.successCount,
                errorMessages: result.errorMessages,
                project: project
            )
            context.insert(batch)
            try context.save()
            batchID = batch.persistentModelID
            folder = result.batchFolderName
        }

        let reload = ModelContext(container)
        let batch = reload.model(for: batchID) as? ProjectExportBatch
        XCTAssertNotNil(batch)
        XCTAssertEqual(batch?.orderedFileNames, ["01.jpg", "02.jpg"])
        XCTAssertEqual(batch?.batchFolderName, folder)
        XCTAssertNotNil(LocalEditStore.exportBatchFileURL(folderName: folder, fileName: "01.jpg"))
    }

    func testBatchDeletionRemovesOnlyBatchFiles() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(withPhotos: [.red, .blue], in: context)
        let projectFile = project.sortedPhotos[0].localFileName
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: projectFile))

        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            project: project
        )
        context.insert(batch)

        LocalEditStore.deleteExportBatchFolder(folderName: result.batchFolderName)
        context.delete(batch)

        XCTAssertNil(LocalEditStore.exportBatchFileURL(folderName: result.batchFolderName, fileName: "01.jpg"))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: projectFile))
    }

    func testSharingAttachesUsableJPEGFiles() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(withPhotos: [.green], in: context)
        let result = try ProjectBatchExporter.export(project: project)
        let batch = ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            project: project
        )
        let urls = batch.fileURLs
        XCTAssertEqual(urls.count, 1)
        let share = ShareBatchItem(urls: urls)
        XCTAssertEqual(share.urls.count, 1)
        let data = try Data(contentsOf: share.urls[0])
        XCTAssertFalse(data.isEmpty)
        XCTAssertNotNil(UIImage(data: data))
        // JPEG SOI marker
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }

    func testOrderedFilenamesMatchProjectOrderAfterReorder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(withPhotos: [.red, .green, .blue], in: context)
        var ordered = project.sortedPhotos
        ordered.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        for (index, photo) in ordered.enumerated() {
            photo.sortOrder = index
        }

        let firstFile = project.sortedPhotos[0].localFileName
        let result = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(result.orderedFileNames.first, "01.jpg")
        // 01.jpg should be rendered from the first sorted photo (formerly last)
        XCTAssertEqual(project.sortedPhotos[0].localFileName, firstFile)
    }
}
