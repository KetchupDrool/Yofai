import SwiftUI

/// Phase 40/41/44 — local export history with marketplace filters, compare, and optional notes.
struct ExportHistorySection: View {
    @Bindable var project: ItemProject
    var onUseSettings: (ProjectExportBatch) -> Void
    var onExportAgain: ((ProjectExportBatch) -> Void)?
    var onShare: ((ProjectExportBatch) -> Void)?
    var onDelete: ((ProjectExportBatch) -> Void)?

    @State private var selectedFilter: ExportHistoryFilter = .all
    @State private var batchForNote: ProjectExportBatch?

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
                Text("No exports yet.")
                    .font(.subheadline)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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
            }
        } header: {
            Text("Export History")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local only. Filter and compare use saved export details — not photo pixels, and not publish status. Notes are optional reminders. Deleting a row removes that export folder only, not your product photos.")
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
            Text(batch.exportedForLine)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
            Text(batch.historySecondaryLine)
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)

            if let note = batch.sellerNoteDisplayLine {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Export note: \(note)")
            }

            HStack(spacing: 12) {
                Button("Use These Export Settings") {
                    onUseSettings(batch)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)

                if let onExportAgain {
                    Button("Export Again") {
                        onExportAgain(batch)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                }

                Button(batch.hasSellerNote ? "Edit Note" : "Add Note") {
                    batchForNote = batch
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
                .accessibilityLabel(batch.hasSellerNote ? "Edit Note" : "Add Note")

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
