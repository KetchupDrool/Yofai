import Foundation
import SwiftData
import UIKit

@Model
final class ImportedOriginal {
    var importedAt: Date
    /// File name inside Application Support/Originals (not Photos).
    var localFileName: String?
    @Attribute(.externalStorage) var thumbnailData: Data?

    init(
        importedAt: Date = .now,
        localFileName: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.importedAt = importedAt
        self.localFileName = localFileName
        self.thumbnailData = thumbnailData
    }

    var thumbnailImage: UIImage? {
        guard let thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }

    var fullLocalImage: UIImage? {
        LocalEditStore.loadOriginalImage(fileName: localFileName)
    }
}
