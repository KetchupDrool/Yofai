import SwiftUI
import UIKit

/// Stable share payload so the sheet is only presented after a file exists.
struct ShareFileItem: Identifiable, Equatable {
    let id: UUID
    let url: URL

    init(url: URL) {
        self.id = UUID()
        self.url = url
    }
}

/// Multi-file share payload for export batches (actual JPEG file URLs).
struct ShareBatchItem: Identifiable, Equatable {
    let id: UUID
    let urls: [URL]

    init(urls: [URL]) {
        self.id = UUID()
        self.urls = urls
    }
}

enum ShareExport {
    /// Writes a temporary JPEG for UIActivityViewController (more reliable than raw UIImage).
    static func writeTemporaryJPEG(_ image: UIImage) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw PhotoSaveError.renderFailed
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yofai-share-\(UUID().uuidString).jpg", isDirectory: false)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PhotoSaveError.localSaveFailed
        }
        return url
    }

    static func removeTemporaryFile(at url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
