import Foundation
import UIKit

enum LocalEditStore {
    private static let folderName = "SavedEdits"

    static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func fileURL(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    /// Saves JPEG to app storage and returns the file name only.
    static func saveFullImage(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw PhotoSaveError.localSaveFailed
        }
        let fileName = "edit-\(UUID().uuidString).jpg"
        let url = fileURL(for: fileName)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PhotoSaveError.localSaveFailed
        }
        return fileName
    }

    static func loadImage(fileName: String?) -> UIImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        let url = fileURL(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    static func deleteFile(fileName: String?) {
        guard let fileName, !fileName.isEmpty else { return }
        let url = fileURL(for: fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
