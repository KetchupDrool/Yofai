import Foundation

/// Phase 48 — post-export next-step availability for Local Export Mode (no upload/publish).
enum LocalExportPostExportSupport {
    static let nextStepHint = "Next: view or share your local JPEGs for manual upload."

    struct ActionAvailability: Equatable {
        var showViewExportedFiles: Bool
        var showShareExportedPhotos: Bool
        var showShareWithNote: Bool
        var showCopyExportNote: Bool
        var showAddEditNote: Bool
    }

    /// Seller-facing actions for a successful export batch. Does not create exports or mutate data.
    static func actions(for batch: ProjectExportBatch) -> ActionAvailability {
        let canShare = ExportBatchFileAccessSupport.canShare(batch)
        let hasNote = batch.hasSellerNote
        return ActionAvailability(
            showViewExportedFiles: true,
            showShareExportedPhotos: canShare,
            showShareWithNote: canShare && hasNote,
            showCopyExportNote: hasNote,
            showAddEditNote: true
        )
    }

    /// Primary next-step title after a successful local export.
    static var primaryNextStepTitle: String {
        ExportBatchFileAccessSupport.viewExportedFilesTitle
    }
}
