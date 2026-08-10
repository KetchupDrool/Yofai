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
/// Optional caption is share text only — never embeds into image pixels or uploads to a marketplace.
struct ShareBatchItem: Identifiable, Equatable {
    let id: UUID
    let urls: [URL]
    /// Optional local reference text (e.g. export note). Off unless explicitly provided.
    let caption: String?

    init(urls: [URL], caption: String? = nil) {
        self.id = UUID()
        self.urls = urls
        self.caption = {
            guard let caption else { return nil }
            let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }()
    }

    var activityItems: [Any] {
        var items: [Any] = []
        if let caption {
            items.append(caption)
        }
        items.append(contentsOf: urls)
        return items
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
