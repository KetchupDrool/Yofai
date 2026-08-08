import Foundation
import SwiftData
import UIKit

@Model
final class SavedEdit {
    var savedAt: Date
    var filterName: String
    var quarterTurns: Int
    @Attribute(.externalStorage) var thumbnailData: Data?

    init(
        savedAt: Date = .now,
        filterName: String,
        quarterTurns: Int,
        thumbnailData: Data? = nil
    ) {
        self.savedAt = savedAt
        self.filterName = filterName
        self.quarterTurns = quarterTurns
        self.thumbnailData = thumbnailData
    }

    var rotationDegrees: Int {
        let turns = ((quarterTurns % 4) + 4) % 4
        return turns * 90
    }

    var thumbnailImage: UIImage? {
        guard let thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }

    static func makeThumbnailData(from image: UIImage, maxDimension: CGFloat = 240) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}
