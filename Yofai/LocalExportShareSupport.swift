import Foundation

/// Phase 46 — seller-facing local export/share wording. No Direct Upload / publish claims.
enum LocalExportShareSupport {
    static let localJPEGsLabel = "Local JPEGs"
    static let manualUploadLabel = "Manual upload"
    static let shareExportedPhotosTitle = "Share Exported Photos"
    static let shareWithNoteTitle = "Share with Note"
    static let copyExportNoteTitle = "Copy Export Note"
    static let viewExportedFilesTitle = ExportBatchFileAccessSupport.viewExportedFilesTitle

    /// Compact package label: marketplace, canvas, count, local framing.
    static func packageSummaryLine(for batch: ProjectExportBatch) -> String {
        [
            marketplaceLabel(for: batch),
            batch.pixelSizeLabel,
            batch.photoCountLabel,
            localJPEGsLabel
        ].joined(separator: " • ")
    }

    static func marketplaceLabel(for batch: ProjectExportBatch) -> String {
        if batch.marketplaceTargetRaw.isEmpty {
            return "Earlier export"
        }
        return batch.recordedMarketplaceTarget.displayTitle
    }

    /// Post-export result card. Local wording only — never “published” / “uploaded”.
    static func resultSummaryText(for batch: ProjectExportBatch) -> String {
        var lines = [
            "Exported \(batch.successCount) local JPEG\(batch.successCount == 1 ? "" : "s")",
            "For \(marketplaceLabel(for: batch))",
            batch.pixelSizeLabel,
            batch.recordedFitMode.displayTitle
        ]
        if batch.watermarkEnabled {
            lines.append("Watermark on")
        } else {
            lines.append("Watermark off")
        }
        lines.append(manualUploadLabel)
        if batch.hasSellerNote {
            lines.append("Note: \(ExportBatchNoteSupport.normalized(batch.sellerNote))")
        }
        return lines.joined(separator: "\n")
    }

    /// Optional share caption from the existing seller note. Blank → nil.
    static func shareCaption(for batch: ProjectExportBatch, includeNote: Bool) -> String? {
        guard includeNote, batch.hasSellerNote else { return nil }
        let note = ExportBatchNoteSupport.normalized(batch.sellerNote)
        guard !note.isEmpty else { return nil }
        return "\(exportedForPhrase(for: batch)) — \(note)"
    }

    static func exportedForPhrase(for batch: ProjectExportBatch) -> String {
        if batch.marketplaceTargetRaw.isEmpty {
            return "Local export"
        }
        return "Exported for \(batch.recordedMarketplaceTarget.displayTitle)"
    }

    /// Text suitable for Copy Export Note (note body only).
    static func copyableNoteText(for batch: ProjectExportBatch) -> String? {
        guard batch.hasSellerNote else { return nil }
        let note = ExportBatchNoteSupport.normalized(batch.sellerNote)
        return note.isEmpty ? nil : note
    }

    /// True when copy contains Direct Upload / publish implications that Local Export Mode must avoid.
    static func containsForbiddenShareWording(_ text: String) -> Bool {
        let lower = text.lowercased()
        let banned = [
            "published to",
            "uploaded to",
            "direct upload",
            "send to marketplace",
            "marketplace accepted",
            "compliant"
        ]
        return banned.contains { lower.contains($0) }
    }
}
