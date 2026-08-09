import XCTest
import SwiftData
import UIKit
@testable import Yofai

@MainActor
final class Phase32ProductIntakeTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor = .systemOrange, size: CGSize = CGSize(width: 32, height: 48)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeProject(photoCount: Int, in context: ModelContext) throws -> ItemProject {
        var photos: [ItemProjectPhoto] = []
        for index in 0..<photoCount {
            let file = try LocalEditStore.saveProjectImage(makeImage(color: index % 2 == 0 ? .red : .blue))
            let photo = ItemProjectPhoto(localFileName: file, sortOrder: index)
            photo.altText = "Alt \(index + 1)"
            photos.append(photo)
        }
        let project = ItemProject(name: "Intake", photos: photos)
        context.insert(project)
        return project
    }

    func testPhotoPlanGoalCreateEditReorderCompleteDelete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = ItemProject(name: "Plan")
        context.insert(project)

        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        XCTAssertEqual(project.sortedPhotoPlanGoals.map(\.name), PhotoPlanSupport.starterGoalNames)

        let first = project.sortedPhotoPlanGoals[0]
        first.name = "Hero shot"
        first.isComplete = true
        XCTAssertTrue(first.isComplete)

        PhotoPlanSupport.moveGoals(project.sortedPhotoPlanGoals, from: IndexSet(integer: 0), to: 2)
        XCTAssertEqual(project.sortedPhotoPlanGoals[1].name, "Hero shot")

        let extra = PhotoPlanSupport.addGoal(named: "Lifestyle", to: project, in: context)
        XCTAssertEqual(extra.name, "Lifestyle")
        XCTAssertEqual(project.photoPlanGoals.count, PhotoPlanSupport.starterGoalNames.count + 1)

        context.delete(extra)
        try context.save()
        XCTAssertEqual(project.photoPlanGoals.count, PhotoPlanSupport.starterGoalNames.count)
    }

    func testOnePhotoCannotAttachToMultipleGoals() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 2, in: context)
        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        let goals = project.sortedPhotoPlanGoals
        let photo = project.sortedPhotos[0]

        try PhotoPlanSupport.attach(photo: photo, to: goals[0], project: project)
        XCTAssertEqual(goals[0].attachedPhotoStableID, photo.stableID)

        XCTAssertThrowsError(try PhotoPlanSupport.attach(photo: photo, to: goals[1], project: project)) { error in
            XCTAssertEqual(error as? PhotoPlanError, .photoAlreadyAttached)
        }
        XCTAssertNil(goals[1].attachedPhotoStableID)

        PhotoPlanSupport.clearAttachment(on: goals[0])
        try PhotoPlanSupport.attach(photo: photo, to: goals[1], project: project)
        XCTAssertEqual(goals[1].attachedPhotoStableID, photo.stableID)
    }

    func testReorderPhotosKeepsGoalAttachmentAndAltText() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 3, in: context)
        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        let photoA = project.sortedPhotos[0]
        let photoB = project.sortedPhotos[1]
        try PhotoPlanSupport.attach(photo: photoA, to: project.sortedPhotoPlanGoals[0], project: project)
        try PhotoPlanSupport.attach(photo: photoB, to: project.sortedPhotoPlanGoals[1], project: project)

        var ordered = project.sortedPhotos
        ordered.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        for (index, photo) in ordered.enumerated() {
            photo.sortOrder = index
        }

        XCTAssertEqual(project.sortedPhotoPlanGoals[0].attachedPhotoStableID, photoA.stableID)
        XCTAssertEqual(project.sortedPhotoPlanGoals[1].attachedPhotoStableID, photoB.stableID)
        XCTAssertEqual(photoA.altText, "Alt 1")
        XCTAssertEqual(photoB.altText, "Alt 2")
        XCTAssertEqual(project.sortedPhotos.last?.stableID, photoA.stableID)
    }

    func testDeletingAttachedPhotoClearsOnlyThatGoal() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 2, in: context)
        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        let photoA = project.sortedPhotos[0]
        let photoB = project.sortedPhotos[1]
        try PhotoPlanSupport.attach(photo: photoA, to: project.sortedPhotoPlanGoals[0], project: project)
        try PhotoPlanSupport.attach(photo: photoB, to: project.sortedPhotoPlanGoals[1], project: project)

        PhotoPlanSupport.clearAttachments(referencing: photoA.stableID, in: project)
        LocalEditStore.deleteProjectFile(fileName: photoA.localFileName)
        context.delete(photoA)
        let remaining = project.sortedPhotos
        for (index, photo) in remaining.enumerated() {
            photo.sortOrder = index
        }
        try context.save()

        XCTAssertNil(project.sortedPhotoPlanGoals[0].attachedPhotoStableID)
        XCTAssertEqual(project.sortedPhotoPlanGoals[1].attachedPhotoStableID, photoB.stableID)
        XCTAssertEqual(project.photoCount, 1)
    }

    func testPhotoTechnicalFactsAndMissingFileSafe() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        let photo = project.sortedPhotos[0]
        photo.savedEditState = PhotoEditState(quarterTurns: 1)
        photo.altText = "Mug"
        try PhotoPlanSupport.attach(photo: photo, to: project.sortedPhotoPlanGoals[0], project: project)

        let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
        XCTAssertTrue(facts.filePresent)
        XCTAssertTrue(facts.fileReadable)
        let loaded = photo.fullLocalImage
        let expectedWidth = loaded?.cgImage?.width
        let expectedHeight = loaded?.cgImage?.height
        XCTAssertEqual(facts.pixelWidth, expectedWidth)
        XCTAssertEqual(facts.pixelHeight, expectedHeight)
        XCTAssertNotNil(facts.pixelWidth)
        XCTAssertNotNil(facts.pixelHeight)
        XCTAssertTrue(facts.hasSavedEdit)
        XCTAssertEqual(facts.altTextStatus, .present)
        XCTAssertEqual(facts.attachedGoalName, project.sortedPhotoPlanGoals[0].name)
        XCTAssertFalse(facts.orientationDescription.isEmpty)

        photo.localFileName = "missing-project-file.jpg"
        let missing = PhotoTechnicalCheck.facts(for: photo, project: project)
        XCTAssertFalse(missing.filePresent)
        XCTAssertFalse(missing.fileReadable)
        XCTAssertNil(missing.pixelWidth)
        XCTAssertNil(missing.pixelHeight)
    }

    func testSellerReviewCheckboxesPersistAndDoNotAffectReadiness() throws {
        let container = try makeContainer()
        let projectID: PersistentIdentifier
        do {
            let context = ModelContext(container)
            let project = try makeProject(photoCount: 1, in: context)
            project.listingTitle = "Ready"
            project.listingPriceText = "8"
            project.listingQuantity = 1
            let photo = project.sortedPhotos[0]
            photo.reviewProductClearlyVisible = true
            photo.reviewBackgroundAcceptable = true
            photo.reviewColorAccurate = false
            photo.reviewNoPrivateInfoVisible = true
            try context.save()
            XCTAssertTrue(ListingQueueSupport.isReady(project))
            projectID = project.persistentModelID
        }

        let reload = ModelContext(container)
        let project = reload.model(for: projectID) as? ItemProject
        let photo = project?.sortedPhotos.first
        XCTAssertTrue(photo?.reviewProductClearlyVisible == true)
        XCTAssertTrue(photo?.reviewBackgroundAcceptable == true)
        XCTAssertFalse(photo?.reviewColorAccurate == true)
        XCTAssertTrue(photo?.reviewNoPrivateInfoVisible == true)
        XCTAssertTrue(ListingQueueSupport.isReady(project!))

        photo?.reviewProductClearlyVisible = false
        photo?.reviewBackgroundAcceptable = false
        photo?.reviewNoPrivateInfoVisible = false
        XCTAssertTrue(ListingQueueSupport.isReady(project!))
    }

    func testCameraUnavailableIsSafeAndClear() {
        let source = SystemCameraCaptureSource()
        // Simulator and unsupported environments report unavailable.
        if !source.isCameraAvailable {
            XCTAssertFalse(source.unavailableMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertThrowsError(try source.requireAvailable()) { error in
                XCTAssertEqual(error as? CameraCaptureError, .unavailable)
            }
        } else {
            XCTAssertNoThrow(try source.requireAvailable())
        }
    }

    func testInjectedCaptureAppendsWithoutOverwrite() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        let existingFile = project.sortedPhotos[0].localFileName
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: existingFile))

        let injected = InjectedTestCaptureSource(image: makeImage(color: .green, size: CGSize(width: 40, height: 40)))
        let goal = project.sortedPhotoPlanGoals[0]
        let newPhoto = try ProjectPhotoCaptureSupport.insertCapturedPhoto(
            from: injected,
            into: project,
            attachTo: goal,
            in: context
        )
        try context.save()

        XCTAssertEqual(project.photoCount, 2)
        XCTAssertEqual(project.sortedPhotos[1].stableID, newPhoto.stableID)
        XCTAssertEqual(goal.attachedPhotoStableID, newPhoto.stableID)
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: existingFile))
        XCTAssertTrue(LocalEditStore.projectFileExists(fileName: newPhoto.localFileName))
        XCTAssertNotEqual(existingFile, newPhoto.localFileName)
    }

    func testDuplicateCopiesPhotoPlanTemplateOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        let goal = project.sortedPhotoPlanGoals[0]
        goal.name = "Custom Hero"
        goal.isComplete = true
        try PhotoPlanSupport.attach(photo: project.sortedPhotos[0], to: goal, project: project)
        try context.save()

        let copy = project.duplicateListingDraft(newName: "Dup Intake")
        context.insert(copy)
        try context.save()

        XCTAssertEqual(copy.sortedPhotoPlanGoals.map(\.name), project.sortedPhotoPlanGoals.map(\.name))
        XCTAssertEqual(copy.sortedPhotoPlanGoals.map(\.sortOrder), project.sortedPhotoPlanGoals.map(\.sortOrder))
        XCTAssertTrue(copy.sortedPhotoPlanGoals.allSatisfy { !$0.isComplete })
        XCTAssertTrue(copy.sortedPhotoPlanGoals.allSatisfy { $0.attachedPhotoStableID == nil })
        XCTAssertEqual(copy.photoCount, 0)
        XCTAssertEqual(copy.aiPreparations.count, 0)
    }

    func testDeletingProjectRemovesPhotoPlanGoals() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let project = try makeProject(photoCount: 1, in: context)
        PhotoPlanSupport.ensureStarterGoals(on: project, in: context)
        XCTAssertFalse(project.photoPlanGoals.isEmpty)
        try context.save()

        for photo in project.photos {
            LocalEditStore.deleteProjectFile(fileName: photo.localFileName)
        }
        context.delete(project)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<PhotoPlanGoal>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<ItemProject>()).isEmpty)
    }

    func testSellerDefaultsDoNotStorePhotoPlanOrCameraData() {
        var defaults = SellerDefaults()
        defaults.category = "Cat"
        let encoded = try! JSONEncoder().encode(defaults)
        let json = String(data: encoded, encoding: .utf8) ?? ""
        XCTAssertFalse(json.lowercased().contains("photoplan"))
        XCTAssertFalse(json.lowercased().contains("camera"))
        XCTAssertFalse(json.lowercased().contains("reviewproduct"))
        XCTAssertFalse(json.lowercased().contains("flash"))
    }
}
