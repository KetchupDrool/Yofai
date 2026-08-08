import Foundation
import SwiftData
import UIKit

@Model
final class SavedEdit {
    var savedAt: Date
    var filterName: String
    var quarterTurns: Int
    var didCrop: Bool
    var adjustmentSummary: String
    /// Listing export preset display name. nil/empty on older history rows.
    var exportPresetName: String?
    /// Listing background display name. nil/empty on older history rows.
    var exportBackgroundName: String?
    /// File name inside app Application Support/SavedEdits (not Photos).
    var localFileName: String?
    @Attribute(.externalStorage) var thumbnailData: Data?

    init(
        savedAt: Date = .now,
        filterName: String,
        quarterTurns: Int,
        didCrop: Bool = false,
        adjustmentSummary: String = "None",
        exportPresetName: String? = nil,
        exportBackgroundName: String? = nil,
        localFileName: String? = nil,
        thumbnailData: Data? = nil
    ) {
        self.savedAt = savedAt
        self.filterName = filterName
        self.quarterTurns = quarterTurns
        self.didCrop = didCrop
        self.adjustmentSummary = adjustmentSummary
        self.exportPresetName = exportPresetName
        self.exportBackgroundName = exportBackgroundName
        self.localFileName = localFileName
        self.thumbnailData = thumbnailData
    }

    var rotationDegrees: Int {
        let turns = ((quarterTurns % 4) + 4) % 4
        return turns * 90
    }

    /// Preset · background when both were stored (Phase 20+).
    var listingSummary: String? {
        guard let preset = exportPresetName, !preset.isEmpty,
              let background = exportBackgroundName, !background.isEmpty else {
            return nil
        }
        return "\(preset) · \(background)"
    }

    var thumbnailImage: UIImage? {
        guard let thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }

    var fullLocalImage: UIImage? {
        LocalEditStore.loadImage(fileName: localFileName)
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
