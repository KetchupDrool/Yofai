import SwiftUI
import UIKit

/// Phase 40/41/44/46/47 — local export history with filters, compare, notes, share, and file access.
struct ExportHistorySection: View {
    @Bindable var project: ItemProject
    var onUseSettings: (ProjectExportBatch) -> Void
    var onExportAgain: ((ProjectExportBatch) -> Void)?
    /// Second argument: include export note as optional share caption (off unless true).
    var onShare: ((ProjectExportBatch, Bool) -> Void)?
    var onDelete: ((ProjectExportBatch) -> Void)?

    @State private var selectedFilter: ExportHistoryFilter = .all
    @State private var batchForNote: ProjectExportBatch?
    @State private var batchForFiles: ProjectExportBatch?
    @State private var noteCopiedMessage: String?

    private var allBatches: [ProjectExportBatch] {
        ExportHistorySupport.completedBatches(in: project)
    }

    private var availableFilters: [ExportHistoryFilter] {
        ExportHistorySupport.availableFilters(for: allBatches)
    }

    private var filteredBatches: [ProjectExportBatch] {
        ExportHistorySupport.filtered(allBatches, by: resolvedFilter)
    }

    /// Keeps selection valid when history/filter chips change.
    private var resolvedFilter: ExportHistoryFilter {
        if availableFilters.contains(selectedFilter) {
            return selectedFilter
        }
        return .all
    }

    private var comparison: ExportHistoryComparison {
        ExportHistorySupport.compareNewestTwo(allBatches)
    }

    var body: some View {
        Section {
            if allBatches.isEmpty {
                Text("No local exports yet.")
                    .font(.subheadline)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("No local exports yet.")
            } else {
                if availableFilters.count > 1 {
                    filterChips
                }

                if allBatches.count >= 2 {
                    comparisonBlock
                } else {
                    Text("No previous export to compare.")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if filteredBatches.isEmpty {
                    Text(resolvedFilter.emptyStateMessage)
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(filteredBatches) { batch in
                        historyRow(batch)
                    }
                }

                if let noteCopiedMessage {
                    Text(noteCopiedMessage)
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.accent)
                        .accessibilityLabel(noteCopiedMessage)
                }
            }
        } header: {
            Text("Export History")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local only. View or share local JPEGs for manual upload — not publish status. Filter and compare use saved export details. Notes are optional reminders. Deleting a row removes that export folder only, not your product photos.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .onChange(of: availableFilters) { _, filters in
            if !filters.contains(selectedFilter) {
                selectedFilter = .all
            }
        }
        .sheet(item: $batchForNote) { batch in
            ExportBatchNoteEditor(batch: batch)
        }
        .sheet(item: $batchForFiles) { batch in
            ExportedFilesViewer(batch: batch) { includeNote in
                onShare?(batch, includeNote)
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(availableFilters) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.displayTitle)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                resolvedFilter == filter
                                    ? DarkroomTheme.accent.opacity(0.22)
                                    : DarkroomTheme.surfaceRaised,
                                in: Capsule()
                            )
                            .foregroundStyle(
                                resolvedFilter == filter
                                    ? DarkroomTheme.accent
                                    : DarkroomTheme.textSecondary
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(resolvedFilter == filter ? .isSelected : [])
                }
            }
        }
    }

    private var comparisonBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(comparison.summaryText)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private func historyRow(_ batch: ProjectExportBatch) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(batch.historyPrimaryLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("\(batch.exportedForLine). \(batch.historyPrimaryLine)")
            Text(batch.historySecondaryLine)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let noteLine = batch.historyNoteLine {
                Text(noteLine)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(noteLine)
            }

            if let unavailable = ExportBatchFileAccessSupport.availabilityMessage(for: batch) {
                Text(unavailable)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(unavailable)
            }

            actionsRow(batch)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func actionsRow(_ batch: ProjectExportBatch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Primary: View + Share. Secondary actions live in More (seller-friendly order).
            VStack(alignment: .leading, spacing: 10) {
                Button(ExportBatchFileAccessSupport.viewExportedFilesTitle) {
                    batchForFiles = batch
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
                .frame(minHeight: 44, alignment: .leading)
                .accessibilityLabel(ExportBatchFileAccessSupport.viewExportedFilesTitle)

                if let onShare, ExportBatchFileAccessSupport.canShare(batch) {
                    Button(LocalExportShareSupport.shareExportedPhotosTitle) {
                        onShare(batch, false)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .frame(minHeight: 32, alignment: .leading)
                    .accessibilityLabel(LocalExportShareSupport.shareExportedPhotosTitle)
                }

                Menu {
                    if let onShare, ExportBatchFileAccessSupport.canShare(batch),
                       ExportBatchFileAccessSupport.canOfferShareWithNote(batch) {
                        Button(LocalExportShareSupport.shareWithNoteTitle) {
                            onShare(batch, true)
                        }
                    }
                    if ExportBatchFileAccessSupport.canOfferCopyNote(batch) {
                        Button(LocalExportShareSupport.copyExportNoteTitle) {
                            if let text = LocalExportShareSupport.copyableNoteText(for: batch) {
                                UIPasteboard.general.string = text
                                noteCopiedMessage = "Export note copied."
                            }
                        }
                    }
                    Button(batch.hasSellerNote ? "Edit Note" : "Add Note") {
                        batchForNote = batch
                    }
                    Button("Use These Export Settings") {
                        onUseSettings(batch)
                    }
                    if let onExportAgain {
                        Button("Export Again") {
                            onExportAgain(batch)
                        }
                    }
                    if let onDelete {
                        Button("Delete", role: .destructive) {
                            onDelete(batch)
                        }
                    }
                } label: {
                    Text("More")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                        .frame(minHeight: 32, alignment: .leading)
                }
                .accessibilityLabel("More export actions")
            }
        }
    }
}
