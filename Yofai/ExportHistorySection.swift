import SwiftUI

/// Phase 40 — compact local export history for one Item Project.
struct ExportHistorySection: View {
    @Bindable var project: ItemProject
    var onUseSettings: (ProjectExportBatch) -> Void
    var onShare: ((ProjectExportBatch) -> Void)?
    var onDelete: ((ProjectExportBatch) -> Void)?

    private var batches: [ProjectExportBatch] {
        project.sortedCompletedExportBatches
    }

    var body: some View {
        Section {
            if batches.isEmpty {
                Text("No export history yet. Export Photos to record what you prepared.")
                    .font(.subheadline)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(batches) { batch in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(batch.sellerSummaryLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.textPrimary)
                        Text(batch.exportedForLine)
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                        Text(batch.createdAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption2)
                            .foregroundStyle(DarkroomTheme.textTertiary)
                        Text("Fit: \(batch.recordedFitMode.displayTitle)\(batch.watermarkEnabled ? " · Watermark" : "")")
                            .font(.caption2)
                            .foregroundStyle(DarkroomTheme.textTertiary)

                        HStack(spacing: 14) {
                            Button("Use These Export Settings") {
                                onUseSettings(batch)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.accent)

                            if let onShare, batch.hasShareableFiles {
                                Button("Share") {
                                    onShare(batch)
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DarkroomTheme.accent)
                            }

                            if let onDelete {
                                Button("Delete", role: .destructive) {
                                    onDelete(batch)
                                }
                                .font(.caption.weight(.semibold))
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text("Export History")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local only. Shows what you exported for — not published to any marketplace. Deleting a row removes that export folder only, not your product photos.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
    }
}
