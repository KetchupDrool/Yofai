import Foundation
import UIKit

enum LocalEditStore {
    private static let editsFolderName = "SavedEdits"
    private static let originalsFolderName = "Originals"

    static var directoryURL: URL {
        directory(named: editsFolderName)
    }

    static var originalsDirectoryURL: URL {
        directory(named: originalsFolderName)
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

    /// Saves JPEG to app storage and returns the file name only.
    static func saveFullImage(_ image: UIImage) throws -> String {
        try saveJPEG(image, fileName: "edit-\(UUID().uuidString).jpg", in: directoryURL)
    }

    /// Saves an imported original JPEG under Application Support/Originals.
    static func saveOriginalImage(_ image: UIImage) throws -> String {
        try saveJPEG(image, fileName: "original-\(UUID().uuidString).jpg", in: originalsDirectoryURL)
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

    private static func deleteFile(fileName: String?, directory: URL) {
        guard let fileName, !fileName.isEmpty else { return }
        let url = directory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
