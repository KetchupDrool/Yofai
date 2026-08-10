import Foundation
import UIKit

/// Phase 47 — resolve local export JPEGs for view / re-share. Never invents files or exposes paths.
enum ExportBatchFileAccessSupport {
    static let viewExportedFilesTitle = "View Exported Files"
    static let exportedFilesTitle = "Exported Files"
    static let filesUnavailableMessage = "Export files no longer available"
    static let fileUnavailableShort = "Unavailable"
    static let cantPreviewMessage = "Can't preview this file"

    struct ResolvedFile: Equatable, Identifiable {
        var id: String { fileName }
        let fileName: String
        let url: URL?

        var isAvailable: Bool { url != nil }
    }

    enum Availability: Equatable {
        case available(count: Int)
        case partial(available: Int, expected: Int)
        case unavailable
        case noRecordedFiles
    }

    static func resolvedFiles(for batch: ProjectExportBatch) -> [ResolvedFile] {
        batch.orderedFileNames.map { name in
            ResolvedFile(
                fileName: name,
                url: LocalEditStore.exportBatchFileURL(folderName: batch.batchFolderName, fileName: name)
            )
        }
    }

    static func shareableURLs(for batch: ProjectExportBatch) -> [URL] {
        resolvedFiles(for: batch).compactMap(\.url)
    }

    static func canShare(_ batch: ProjectExportBatch) -> Bool {
        !shareableURLs(for: batch).isEmpty
    }

    /// Share with Note only when a note exists (share itself still needs files at call site).
    static func canOfferShareWithNote(_ batch: ProjectExportBatch) -> Bool {
        batch.hasSellerNote
    }

    static func canOfferCopyNote(_ batch: ProjectExportBatch) -> Bool {
        batch.hasSellerNote
    }

    static func availability(for batch: ProjectExportBatch) -> Availability {
        let names = batch.orderedFileNames
        if names.isEmpty {
            return .noRecordedFiles
        }
        let available = shareableURLs(for: batch).count
        if available == 0 {
            return .unavailable
        }
        if available < names.count {
            return .partial(available: available, expected: names.count)
        }
        return .available(count: available)
    }

    /// Seller-facing status when nothing can be shared. Nil when at least one file is shareable.
    static func availabilityMessage(for batch: ProjectExportBatch) -> String? {
        canShare(batch) ? nil : filesUnavailableMessage
    }

    static func folderExists(for batch: ProjectExportBatch) -> Bool {
        let url = LocalEditStore.exportBatchFolderURL(folderName: batch.batchFolderName)
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    /// Loads a local JPEG for preview only. Returns nil if missing or unreadable.
    static func loadPreviewImage(at url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func accessibilityLabel(for file: ResolvedFile, canvasLabel: String) -> String {
        if file.isAvailable {
            return "\(file.fileName), \(canvasLabel), Local JPEG"
        }
        return "\(file.fileName), \(fileUnavailableShort)"
    }
}
