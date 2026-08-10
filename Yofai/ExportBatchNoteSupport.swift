import Foundation

/// Phase 44 — local optional export-batch notes. Not publish status; seller-authored only.
enum ExportBatchNoteSupport {
    /// Practical hard limit for seller memory notes (between 200–300).
    static let maxLength = 240

    /// Trims whitespace, enforces length, blank → empty string (no note).
    static func normalized(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.count <= maxLength {
            return trimmed
        }
        return String(trimmed.prefix(maxLength))
    }

    static func hasNote(_ text: String) -> Bool {
        !normalized(text).isEmpty
    }

    /// Compact one-line preview for history rows.
    static func displayLine(_ text: String, limit: Int = 80) -> String? {
        let note = normalized(text)
        guard !note.isEmpty else { return nil }
        if note.count <= limit { return note }
        return String(note.prefix(limit - 1)) + "…"
    }
}

extension ProjectExportBatch {
    var hasSellerNote: Bool {
        ExportBatchNoteSupport.hasNote(sellerNote)
    }

    var sellerNoteDisplayLine: String? {
        ExportBatchNoteSupport.displayLine(sellerNote)
    }

    /// Updates only the seller note. Does not touch export files or settings metadata.
    func setSellerNote(_ text: String) {
        sellerNote = ExportBatchNoteSupport.normalized(text)
    }
}
