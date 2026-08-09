import Foundation
import UIKit
import SwiftData

struct ProjectBatchExportResult: Equatable {
    var batchFolderName: String
    var orderedFileNames: [String]
    var successCount: Int
    var errorMessages: [String]
}

enum ProjectBatchExporter {
    /// Exports every project photo in sort order. Does not modify source project files.
    @MainActor
    static func export(
        project: ItemProject,
        progress: ((_ completed: Int, _ total: Int) -> Void)? = nil
    ) throws -> ProjectBatchExportResult {
        let photos = project.sortedPhotos
        let total = photos.count
        guard total > 0 else {
            throw PhotoSaveError.loadFailed
        }

        let folderName = try LocalEditStore.createExportBatchFolder()
        var orderedNames: [String] = []
        var errors: [String] = []
        var success = 0

        for (index, photo) in photos.enumerated() {
            let fileName = String(format: "%02d.jpg", index + 1)
            defer { progress?(index + 1, total) }

            guard LocalEditStore.projectFileExists(fileName: photo.localFileName),
                  let source = photo.fullLocalImage else {
                errors.append("Photo \(index + 1): image unavailable")
                continue
            }

            let state = photo.exportEditState(project: project)
            guard let rendered = ImageEditing.render(source: source, state: state) else {
                errors.append("Photo \(index + 1): render failed")
                continue
            }

            do {
                try LocalEditStore.saveExportBatchJPEG(rendered, folderName: folderName, fileName: fileName)
                orderedNames.append(fileName)
                success += 1
            } catch {
                errors.append("Photo \(index + 1): save failed")
            }
        }

        return ProjectBatchExportResult(
            batchFolderName: folderName,
            orderedFileNames: orderedNames,
            successCount: success,
            errorMessages: errors
        )
    }

    static func orderedFileName(forIndex index: Int) -> String {
        String(format: "%02d.jpg", index + 1)
    }
}
