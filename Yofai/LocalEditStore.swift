import Foundation
import UIKit

enum LocalEditStore {
    private static let editsFolderName = "SavedEdits"
    private static let originalsFolderName = "Originals"
    private static let projectsFolderName = "ItemProjects"
    private static let exportBatchesFolderName = "ExportBatches"
    private static let listingPackagesFolderName = "ListingPackages"

    static var directoryURL: URL {
        directory(named: editsFolderName)
    }

    static var originalsDirectoryURL: URL {
        directory(named: originalsFolderName)
    }

    static var projectsDirectoryURL: URL {
        directory(named: projectsFolderName)
    }

    static var exportBatchesDirectoryURL: URL {
        directory(named: exportBatchesFolderName)
    }

    static var listingPackagesDirectoryURL: URL {
        directory(named: listingPackagesFolderName)
    }

    private static func directory(named name: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent(name, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func fileURL(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    static func originalFileURL(for fileName: String) -> URL {
        originalsDirectoryURL.appendingPathComponent(fileName)
    }

    static func projectFileURL(for fileName: String) -> URL {
        projectsDirectoryURL.appendingPathComponent(fileName)
    }

    static func exportBatchFolderURL(folderName: String) -> URL {
        exportBatchesDirectoryURL.appendingPathComponent(folderName, isDirectory: true)
    }

    static func exportBatchFileURL(folderName: String, fileName: String) -> URL? {
        let url = exportBatchFolderURL(folderName: folderName).appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    /// Saves JPEG to app storage and returns the file name only.
    static func saveFullImage(_ image: UIImage) throws -> String {
        try saveJPEG(image, fileName: "edit-\(UUID().uuidString).jpg", in: directoryURL)
    }

    /// Saves an imported original JPEG under Application Support/Originals.
    static func saveOriginalImage(_ image: UIImage) throws -> String {
        try saveJPEG(image, fileName: "original-\(UUID().uuidString).jpg", in: originalsDirectoryURL)
    }

    /// Saves a project photo JPEG under Application Support/ItemProjects.
    static func saveProjectImage(_ image: UIImage) throws -> String {
        let normalized = ImageEditing.normalizedOrientation(image)
        return try saveJPEG(normalized, fileName: "project-\(UUID().uuidString).jpg", in: projectsDirectoryURL)
    }

    /// Creates a new empty batch folder under ExportBatches. Returns folder name.
    static func createExportBatchFolder() throws -> String {
        let folderName = "batch-\(UUID().uuidString)"
        let url = exportBatchFolderURL(folderName: folderName)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw PhotoSaveError.localSaveFailed
        }
        return folderName
    }

    static func saveExportBatchJPEG(_ image: UIImage, folderName: String, fileName: String) throws {
        let folder = exportBatchFolderURL(folderName: folderName)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        _ = try saveJPEG(image, fileName: fileName, in: folder)
    }

    static func deleteExportBatchFolder(folderName: String) {
        let url = exportBatchFolderURL(folderName: folderName)
        try? FileManager.default.removeItem(at: url)
    }

    static func listingPackageFolderURL(folderName: String) -> URL {
        listingPackagesDirectoryURL.appendingPathComponent(folderName, isDirectory: true)
    }

    static func listingPackageFileURL(folderName: String, fileName: String) -> URL? {
        let url = listingPackageFolderURL(folderName: folderName).appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    static func createListingPackageFolder() throws -> String {
        let folderName = "package-\(UUID().uuidString)"
        let url = listingPackageFolderURL(folderName: folderName)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw PhotoSaveError.localSaveFailed
        }
        return folderName
    }

    static func copyExportBatchIntoListingPackage(
        batchFolderName: String,
        fileNames: [String],
        packageFolderName: String
    ) throws {
        let destFolder = listingPackageFolderURL(folderName: packageFolderName)
        for fileName in fileNames {
            guard let source = exportBatchFileURL(folderName: batchFolderName, fileName: fileName) else {
                throw PhotoSaveError.localSaveFailed
            }
            let dest = destFolder.appendingPathComponent(fileName)
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: source, to: dest)
            } catch {
                throw PhotoSaveError.localSaveFailed
            }
        }
    }

    static func writeListingPackageDetails(_ text: String, packageFolderName: String, fileName: String) throws {
        let url = listingPackageFolderURL(folderName: packageFolderName).appendingPathComponent(fileName)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw PhotoSaveError.localSaveFailed
        }
    }

    static func deleteListingPackageFolder(folderName: String) {
        let url = listingPackageFolderURL(folderName: folderName)
        try? FileManager.default.removeItem(at: url)
    }

    private static func saveJPEG(_ image: UIImage, fileName: String, in directory: URL) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw PhotoSaveError.localSaveFailed
        }
        let url = directory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PhotoSaveError.localSaveFailed
        }
        return fileName
    }

    static func loadImage(fileName: String?) -> UIImage? {
        loadImage(fileName: fileName, directory: directoryURL)
    }

    static func loadOriginalImage(fileName: String?) -> UIImage? {
        loadImage(fileName: fileName, directory: originalsDirectoryURL)
    }

    static func loadProjectImage(fileName: String?) -> UIImage? {
        loadImage(fileName: fileName, directory: projectsDirectoryURL)
    }

    private static func loadImage(fileName: String?, directory: URL) -> UIImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        let url = directory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    static func deleteFile(fileName: String?) {
        deleteFile(fileName: fileName, directory: directoryURL)
    }

    static func deleteOriginalFile(fileName: String?) {
        deleteFile(fileName: fileName, directory: originalsDirectoryURL)
    }

    static func deleteProjectFile(fileName: String?) {
        deleteFile(fileName: fileName, directory: projectsDirectoryURL)
    }

    static func projectFileExists(fileName: String?) -> Bool {
        guard let fileName, !fileName.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: projectFileURL(for: fileName).path)
    }

    static func projectFileModificationDate(fileName: String) -> Date? {
        let url = projectFileURL(for: fileName)
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }

    static func projectFileData(fileName: String?) -> Data? {
        guard let fileName, !fileName.isEmpty else { return nil }
        return try? Data(contentsOf: projectFileURL(for: fileName))
    }

    /// Deletes every local project photo file for a project (not Originals/History/export batches).
    static func deleteAllFiles(for project: ItemProject) {
        for photo in project.photos {
            deleteProjectFile(fileName: photo.localFileName)
        }
    }

    /// Deletes export batch folders for a project (call when deleting the project).
    static func deleteAllExportBatches(for project: ItemProject) {
        for batch in project.exportBatches {
            deleteExportBatchFolder(folderName: batch.batchFolderName)
        }
    }

    static func deleteAllListingPackages(for project: ItemProject) {
        for package in project.listingPackages {
            deleteListingPackageFolder(folderName: package.packageFolderName)
        }
    }

    private static func deleteFile(fileName: String?, directory: URL) {
        guard let fileName, !fileName.isEmpty else { return }
        let url = directory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
