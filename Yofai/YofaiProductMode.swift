import Foundation

/// Phase 45 — product delivery modes. Direct Upload is future-only and not implemented.
enum YofaiProductMode: String, Equatable, CaseIterable {
    /// Current production behavior: local JPEG prep + share; seller uploads manually.
    case localExport = "Local Export Mode"
    /// Future only — official API/OAuth per marketplace after explicit approval. Not available.
    case directUpload = "Direct Upload Mode"

    /// Shipping behavior until a Direct Upload phase is explicitly implemented and approved.
    static var current: YofaiProductMode { .localExport }

    var isImplemented: Bool {
        switch self {
        case .localExport: return true
        case .directUpload: return false
        }
    }

    var sellerFacingSummary: String {
        switch self {
        case .localExport:
            return "Prepare and save photos locally. You upload them in the marketplace app or website."
        case .directUpload:
            return "Not available yet. Future uploads would use official marketplace APIs only."
        }
    }
}
