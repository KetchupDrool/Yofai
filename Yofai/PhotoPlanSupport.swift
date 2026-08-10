import Foundation
import SwiftData
import UIKit

@Model
final class PhotoPlanGoal {
    var name: String
    var sortOrder: Int
    var isComplete: Bool
    /// Attached project photo identity. Nil means unattached. Clearing does not delete the photo.
    var attachedPhotoStableID: UUID?
    var project: ItemProject?

    init(
        name: String,
        sortOrder: Int = 0,
        isComplete: Bool = false,
        attachedPhotoStableID: UUID? = nil,
        project: ItemProject? = nil
    ) {
        self.name = name
        self.sortOrder = sortOrder
        self.isComplete = isComplete
        self.attachedPhotoStableID = attachedPhotoStableID
        self.project = project
    }
}

enum PhotoPlanError: Error, Equatable, LocalizedError {
    case photoAlreadyAttached
    case goalNotInProject

    var errorDescription: String? {
        switch self {
        case .photoAlreadyAttached:
            return "That photo is already attached to another photo-plan goal."
        case .goalNotInProject:
            return "That photo-plan goal does not belong to this project."
        }
    }
}

enum PhotoPlanSupport {
    /// Optional starter goals. Local guidance only — not marketplace requirements.
    static let starterGoalNames: [String] = [
        "Main product view",
        "Front",
        "Back",
        "Detail",
        "Size or scale",
        "Packaging",
        "Variant or color"
    ]

    static func ensureStarterGoals(on project: ItemProject, in context: ModelContext) {
        guard project.photoPlanGoals.isEmpty else { return }
        for (index, name) in starterGoalNames.enumerated() {
            let goal = PhotoPlanGoal(name: name, sortOrder: index, project: project)
            context.insert(goal)
        }
    }

    @discardableResult
    static func addGoal(named name: String, to project: ItemProject, in context: ModelContext) -> PhotoPlanGoal {
        let next = (project.photoPlanGoals.map(\.sortOrder).max() ?? -1) + 1
        let goal = PhotoPlanGoal(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sortOrder: next,
            project: project
        )
        context.insert(goal)
        project.touchModified()
        return goal
    }

    static func moveGoals(_ goals: [PhotoPlanGoal], from source: IndexSet, to destination: Int) {
        var ordered = goals.sorted { $0.sortOrder < $1.sortOrder }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, goal) in ordered.enumerated() {
            goal.sortOrder = index
        }
        ordered.first?.project?.touchModified()
    }

    static func attach(photo: ItemProjectPhoto, to goal: PhotoPlanGoal, project: ItemProject) throws {
        if project.photoPlanGoals.contains(where: {
            $0.attachedPhotoStableID == photo.stableID
                && $0.persistentModelID != goal.persistentModelID
        }) {
            throw PhotoPlanError.photoAlreadyAttached
        }
        goal.attachedPhotoStableID = photo.stableID
        goal.project = project
        project.touchModified()
    }

    static func clearAttachment(on goal: PhotoPlanGoal) {
        goal.attachedPhotoStableID = nil
        goal.project?.touchModified()
    }

    static func clearAttachments(referencing photoStableID: UUID, in project: ItemProject) {
        for goal in project.photoPlanGoals where goal.attachedPhotoStableID == photoStableID {
            goal.attachedPhotoStableID = nil
        }
        project.touchModified()
    }

    static func goal(attachedTo photo: ItemProjectPhoto, in project: ItemProject) -> PhotoPlanGoal? {
        project.photoPlanGoals.first { $0.attachedPhotoStableID == photo.stableID }
    }

    static func unattachedGoals(in project: ItemProject) -> [PhotoPlanGoal] {
        project.sortedPhotoPlanGoals.filter { $0.attachedPhotoStableID == nil }
    }

    static func photosNeedingSellerReview(in project: ItemProject) -> [ItemProjectPhoto] {
        project.sortedPhotos.filter { photo in
            !(photo.reviewProductClearlyVisible
                && photo.reviewBackgroundAcceptable
                && photo.reviewColorAccurate
                && photo.reviewNoPrivateInfoVisible)
        }
    }
}

enum PhotoAltTextStatus: String, Equatable {
    case present
    case notApplicable
    case missing
}

struct PhotoTechnicalFacts: Equatable {
    var pixelWidth: Int?
    var pixelHeight: Int?
    var orientationDescription: String
    var filePresent: Bool
    var fileReadable: Bool
    var hasSavedEdit: Bool
    var altTextStatus: PhotoAltTextStatus
    var attachedGoalName: String?
    /// Project listing export canvas used for batch export (Phase 34).
    var exportCanvasPreset: ListingExportPreset
    var exportCanvasWidth: Int
    var exportCanvasHeight: Int
    /// Project export fit mode (Phase 37).
    var exportFitMode: ListingExportFitMode
    /// True when source file width or height is below the export canvas (local fact only).
    var sourceSmallerThanExportCanvas: Bool?
    /// True when source aspect differs from canvas enough that framing will pad or crop.
    var sourceAspectDiffersFromCanvas: Bool?
    /// Local framing expectation when aspect differs (nil if unavailable or aspect matches).
    var framingExpectation: String?
}

enum PhotoTechnicalCheck {
    /// Aspect ratios within this relative difference are treated as matching.
    static let aspectMatchTolerance: Double = 0.02

    /// Measurable local facts only. Never claims quality, compliance, or publish readiness.
    static func facts(for photo: ItemProjectPhoto, project: ItemProject) -> PhotoTechnicalFacts {
        let present = LocalEditStore.projectFileExists(fileName: photo.localFileName)
        let image = present ? photo.fullLocalImage : nil
        let readable = image != nil
        let width = image?.cgImage?.width
        let height = image?.cgImage?.height

        let altStatus: PhotoAltTextStatus
        if photo.altTextNotApplicable {
            altStatus = .notApplicable
        } else if photo.altText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            altStatus = .missing
        } else {
            altStatus = .present
        }

        let canvas = project.listingExportPreset
        let fitMode = project.listingExportFitMode
        let canvasW = Int(canvas.pixelSize.width)
        let canvasH = Int(canvas.pixelSize.height)
        let canvasCompare = compareSourceToCanvas(width: width, height: height, canvas: canvas)
        let framingExpectation: String?
        if canvasCompare?.aspectDiffers == true {
            switch fitMode {
            case .containPad:
                framingExpectation = "Padding expected (Contain + Pad)"
            case .fillCrop:
                framingExpectation = "Cropping expected (Fill + Crop, center)"
            }
        } else if canvasCompare?.aspectDiffers == false {
            framingExpectation = "No meaningful pad/crop from aspect mismatch"
        } else {
            framingExpectation = nil
        }

        return PhotoTechnicalFacts(
            pixelWidth: width,
            pixelHeight: height,
            orientationDescription: orientationLabel(for: image),
            filePresent: present,
            fileReadable: readable,
            hasSavedEdit: photo.savedEditState != nil,
            altTextStatus: altStatus,
            attachedGoalName: PhotoPlanSupport.goal(attachedTo: photo, in: project)?.name,
            exportCanvasPreset: canvas,
            exportCanvasWidth: canvasW,
            exportCanvasHeight: canvasH,
            exportFitMode: fitMode,
            sourceSmallerThanExportCanvas: canvasCompare?.sourceSmaller,
            sourceAspectDiffersFromCanvas: canvasCompare?.aspectDiffers,
            framingExpectation: framingExpectation
        )
    }

    /// Photos whose source file is smaller than the project export canvas on either axis.
    /// Missing/unreadable files are included so sellers can open Photo Check.
    static func photosWithSourceSmallerThanExportCanvas(in project: ItemProject) -> [ItemProjectPhoto] {
        project.sortedPhotos.filter { photo in
            let facts = facts(for: photo, project: project)
            if facts.sourceSmallerThanExportCanvas == true { return true }
            if !facts.filePresent || !facts.fileReadable { return true }
            return false
        }
    }

    /// Photos where source aspect differs from the export canvas (padding expected under contain+pad).
    static func photosWithAspectDifferingFromExportCanvas(in project: ItemProject) -> [ItemProjectPhoto] {
        project.sortedPhotos.filter { photo in
            facts(for: photo, project: project).sourceAspectDiffersFromCanvas == true
        }
    }

    private static func compareSourceToCanvas(
        width: Int?,
        height: Int?,
        canvas: ListingExportPreset
    ) -> (sourceSmaller: Bool, aspectDiffers: Bool)? {
        guard let width, let height, width > 0, height > 0 else { return nil }
        let canvasW = canvas.pixelSize.width
        let canvasH = canvas.pixelSize.height
        guard canvasW > 0, canvasH > 0 else { return nil }

        let sourceSmaller = Double(width) < canvasW || Double(height) < canvasH
        let sourceAspect = Double(width) / Double(height)
        let canvasAspect = canvasW / canvasH
        let relativeDiff = abs(sourceAspect - canvasAspect) / canvasAspect
        let aspectDiffers = relativeDiff > aspectMatchTolerance
        return (sourceSmaller, aspectDiffers)
    }

    private static func orientationLabel(for image: UIImage?) -> String {
        guard let image else { return "Unknown" }
        switch image.imageOrientation {
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        case .upMirrored: return "Up mirrored"
        case .downMirrored: return "Down mirrored"
        case .leftMirrored: return "Left mirrored"
        case .rightMirrored: return "Right mirrored"
        @unknown default: return "Unknown"
        }
    }
}

enum CameraCaptureError: Error, Equatable, LocalizedError {
    case unavailable
    case permissionDenied
    case cancelled
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Camera is unavailable on this device. Use Import Existing Photo or test on a device with a camera."
        case .permissionDenied:
            return "Camera access is denied. Enable Camera for Yofai in Settings to capture product photos."
        case .cancelled:
            return "Capture cancelled."
        case .invalidImage:
            return "Could not read the captured photo."
        }
    }
}

/// Abstraction so unit tests can inject a capture without faking the system camera in production.
protocol ProjectPhotoCapturing {
    var isCameraAvailable: Bool { get }
    var unavailableMessage: String { get }
    func requireAvailable() throws
    func captureImage() throws -> UIImage
}

/// Production capture source — reports system camera availability. Actual UI uses UIImagePickerController.
final class SystemCameraCaptureSource: ProjectPhotoCapturing {
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var unavailableMessage: String {
        CameraCaptureError.unavailable.errorDescription
            ?? "Camera is unavailable on this device."
    }

    func requireAvailable() throws {
        guard isCameraAvailable else { throw CameraCaptureError.unavailable }
    }

    /// Production capture is interactive via `SystemCameraPicker`. This method never invents an image.
    func captureImage() throws -> UIImage {
        try requireAvailable()
        throw CameraCaptureError.unavailable
    }
}

/// Deterministic capture for unit tests only.
final class InjectedTestCaptureSource: ProjectPhotoCapturing {
    private let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    var isCameraAvailable: Bool { true }
    var unavailableMessage: String { "" }

    func requireAvailable() throws {}

    func captureImage() throws -> UIImage {
        image
    }
}

enum ProjectPhotoCaptureSupport {
    /// Inserts a new project photo via the existing storage path. Never overwrites existing files.
    @discardableResult
    static func insertCapturedPhoto(
        from source: ProjectPhotoCapturing,
        into project: ItemProject,
        attachTo goal: PhotoPlanGoal?,
        in context: ModelContext
    ) throws -> ItemProjectPhoto {
        try source.requireAvailable()
        let image = try source.captureImage()
        let fileName = try LocalEditStore.saveProjectImage(image)
        let nextOrder = (project.photos.map(\.sortOrder).max() ?? -1) + 1
        let photo = ItemProjectPhoto(
            localFileName: fileName,
            thumbnailData: SavedEdit.makeThumbnailData(from: ImageEditing.normalizedOrientation(image)),
            sortOrder: nextOrder,
            project: project
        )
        context.insert(photo)
        if let goal {
            try PhotoPlanSupport.attach(photo: photo, to: goal, project: project)
        }
        project.touchModified()
        return photo
    }
}
