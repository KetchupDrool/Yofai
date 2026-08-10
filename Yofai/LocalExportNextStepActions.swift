import SwiftUI
import UIKit

/// Phase 48 — post-export next steps for the just-created local export batch.
struct LocalExportNextStepActions: View {
    let batch: ProjectExportBatch
    var onViewFiles: () -> Void
    var onShare: (Bool) -> Void
    var onNoteCopied: (() -> Void)? = nil
    var onEditNote: () -> Void

    private var availability: LocalExportPostExportSupport.ActionAvailability {
        LocalExportPostExportSupport.actions(for: batch)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalExportPostExportSupport.nextStepHint)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(LocalExportPostExportSupport.nextStepHint)

            Text(LocalExportShareSupport.packageSummaryLine(for: batch))
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("\(batch.exportedForLine). \(LocalExportShareSupport.packageSummaryLine(for: batch))")

            if let unavailable = ExportBatchFileAccessSupport.availabilityMessage(for: batch) {
                Text(unavailable)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(unavailable)
            }

            VStack(alignment: .leading, spacing: 10) {
                if availability.showViewExportedFiles {
                    Button(LocalExportPostExportSupport.primaryNextStepTitle) {
                        onViewFiles()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .frame(minHeight: 44, alignment: .leading)
                    .accessibilityLabel(LocalExportPostExportSupport.primaryNextStepTitle)
                }

                if availability.showShareExportedPhotos {
                    Button(LocalExportShareSupport.shareExportedPhotosTitle) {
                        onShare(false)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .frame(minHeight: 32, alignment: .leading)
                    .accessibilityLabel(LocalExportShareSupport.shareExportedPhotosTitle)
                }

                if availability.showShareWithNote {
                    Button(LocalExportShareSupport.shareWithNoteTitle) {
                        onShare(true)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .frame(minHeight: 32, alignment: .leading)
                    .accessibilityLabel(LocalExportShareSupport.shareWithNoteTitle)
                }

                if availability.showCopyExportNote {
                    Button(LocalExportShareSupport.copyExportNoteTitle) {
                        if let text = LocalExportShareSupport.copyableNoteText(for: batch) {
                            UIPasteboard.general.string = text
                            onNoteCopied?()
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .frame(minHeight: 32, alignment: .leading)
                    .accessibilityLabel(LocalExportShareSupport.copyExportNoteTitle)
                }

                if availability.showAddEditNote {
                    Button(batch.hasSellerNote ? "Edit Note" : "Add Note") {
                        onEditNote()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .frame(minHeight: 32, alignment: .leading)
                    .accessibilityLabel(batch.hasSellerNote ? "Edit Note" : "Add Note")
                }
            }
        }
    }
}
