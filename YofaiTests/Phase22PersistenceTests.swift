import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase22PersistenceTests: XCTestCase {
    func testCreateReorderRemoveAndDeleteCleansProjectFilesOnly() throws {
        let schema = YofaiModelSchema.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let imageA = makeTestImage(color: .red)
        let imageB = makeTestImage(color: .blue)
        let imageC = makeTestImage(color: .green)

        let fileA = try LocalEditStore.saveProjectImage(imageA)
        let fileB = try LocalEditStore.saveProjectImage(imageB)
        let fileC = try LocalEditStore.saveProjectImage(imageC)

        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: fileA))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: fileB))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: fileC))

        let photoA = ItemProjectPhoto(localFileName: fileA, sortOrder: 0)
        let photoB = ItemProjectPhoto(localFileName: fileB, sortOrder: 1)
        let photoC = ItemProjectPhoto(localFileName: fileC, sortOrder: 2)
        let project = ItemProject(name: "Phase22 Lamp", photos: [photoA, photoB, photoC])
        context.insert(project)
        try context.save()

        // Reorder: move last to front
        var ordered = project.sortedPhotos
        ordered.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        for (index, photo) in ordered.enumerated() {
            photo.sortOrder = index
        }
        project.touchModified()
        try context.save()
        XCTAssertEqual(project.sortedPhotos.map(\.localFileName), [fileC, fileA, fileB])

        // Remove middle photo and its file only
        let toRemove = project.sortedPhotos[1]
        let removedFile = toRemove.localFileName
        LocalEditStore.deleteProjectFile(fileName: removedFile)
        context.delete(toRemove)
        for (index, photo) in project.sortedPhotos.enumerated() {
            photo.sortOrder = index
        }
        try context.save()
        XCTAssertEqual(project.photoCount, 2)
        XCTAssertFalse(LocalEditStore.projectFileExists(fileName: removedFile))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: fileC))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: fileB))

        // Delete project cleans remaining project files
        LocalEditStore.deleteAllFiles(for: project)
        context.delete(project)
        try context.save()
        XCTAssertFalse(LocalEditStore.projectFileExists(fileName: fileC))
        XCTAssertFalse(LocalEditStore.projectFileExists(fileName: fileB))
    }

    private func makeTestImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
