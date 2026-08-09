import Foundation
import SwiftData

@Model
final class ProjectExportBatch {
    var createdAt: Date
    /// Folder name under Application Support/ExportBatches (not under ItemProjects).
    var batchFolderName: String
    var orderedFileNames: [String]
    var successCount: Int
    /// Safe per-photo error messages (no paths with secrets).
    var errorMessages: [String]
    var project: ItemProject?

    init(
        createdAt: Date = .now,
        batchFolderName: String,
        orderedFileNames: [String] = [],
        successCount: Int = 0,
        errorMessages: [String] = [],
        project: ItemProject? = nil
    ) {
        self.createdAt = createdAt
        self.batchFolderName = batchFolderName
        self.orderedFileNames = orderedFileNames
        self.successCount = successCount
        self.errorMessages = errorMessages
        self.project = project
    }

    var fileURLs: [URL] {
        orderedFileNames.compactMap { LocalEditStore.exportBatchFileURL(folderName: batchFolderName, fileName: $0) }
    }

    var hasShareableFiles: Bool {
        !fileURLs.isEmpty
    }
}
