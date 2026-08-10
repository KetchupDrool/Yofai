import Foundation

/// Phase 41 — transient export-history filter. Not persisted.
enum ExportHistoryFilter: Equatable, Hashable, Identifiable {
    case all
    case marketplace(MarketplaceTarget)
    /// Pre-Phase-40 rows with empty marketplaceTargetRaw.
    case earlierExport

    var id: String {
        switch self {
        case .all: return "all"
        case .marketplace(let target): return "market:\(target.rawValue)"
        case .earlierExport: return "earlier"
        }
    }

    var displayTitle: String {
        switch self {
        case .all: return "All"
        case .marketplace(let target): return target.displayTitle
        case .earlierExport: return "Earlier export"
        }
    }

    /// Empty-state copy when the filter matches nothing.
    var emptyStateMessage: String {
        switch self {
        case .all:
            return "No exports yet."
        case .marketplace(let target):
            return "No \(target.displayTitle) exports yet."
        case .earlierExport:
            return "No earlier exports."
        }
    }
}

enum ExportHistorySupport {
    /// Newest-first completed batches for a project (metadata only).
    static func completedBatches(in project: ItemProject) -> [ProjectExportBatch] {
        project.sortedCompletedExportBatches
    }

    /// Filters that appear in this project’s history, plus All. Transient UI only.
    static func availableFilters(for batches: [ProjectExportBatch]) -> [ExportHistoryFilter] {
        var seenTargets = Set<String>()
        var hasEarlier = false

        for batch in batches {
            if batch.marketplaceTargetRaw.isEmpty {
                hasEarlier = true
            } else {
                seenTargets.insert(batch.marketplaceTargetRaw)
            }
        }

        var result: [ExportHistoryFilter] = [.all]
        for target in MarketplaceTarget.allCases where seenTargets.contains(target.rawValue) {
            result.append(.marketplace(target))
        }
        if hasEarlier {
            result.append(.earlierExport)
        }
        return result
    }

    /// Filters by stored marketplaceTargetRaw only — never infers from canvas size or folder names.
    static func filtered(
        _ batches: [ProjectExportBatch],
        by filter: ExportHistoryFilter
    ) -> [ProjectExportBatch] {
        switch filter {
        case .all:
            return batches
        case .marketplace(let target):
            return batches.filter { batch in
                guard !batch.marketplaceTargetRaw.isEmpty else { return false }
                return batch.marketplaceTargetRaw == target.rawValue
            }
        case .earlierExport:
            return batches.filter { $0.marketplaceTargetRaw.isEmpty }
        }
    }

    /// Metadata-only comparison of the two newest completed exports (already newest-first).
    static func compareNewestTwo(_ batches: [ProjectExportBatch]) -> ExportHistoryComparison {
        guard batches.count >= 2 else {
            return ExportHistoryComparison(
                hasPrevious: false,
                lines: [],
                summaryText: "No previous export to compare."
            )
        }
        let newest = batches[0]
        let previous = batches[1]
        let lines = differenceLines(from: previous, to: newest)
        let summary: String
        if lines.isEmpty {
            summary = "Compared with previous export:\n• Same marketplace, size, fit, photo count, and watermark"
        } else {
            summary = "Compared with previous export:\n" + lines.map { "• \($0)" }.joined(separator: "\n")
        }
        return ExportHistoryComparison(hasPrevious: true, lines: lines, summaryText: summary)
    }

    /// Changed fields only, previous → newest.
    static func differenceLines(from previous: ProjectExportBatch, to newest: ProjectExportBatch) -> [String] {
        var lines: [String] = []

        let prevMarket = previous.marketplaceTargetRaw.isEmpty
            ? "Earlier export"
            : previous.recordedMarketplaceTarget.displayTitle
        let newMarket = newest.marketplaceTargetRaw.isEmpty
            ? "Earlier export"
            : newest.recordedMarketplaceTarget.displayTitle
        if prevMarket != newMarket {
            lines.append("\(prevMarket) → \(newMarket)")
        }

        if previous.pixelSizeLabel != newest.pixelSizeLabel {
            lines.append("\(previous.pixelSizeLabel) → \(newest.pixelSizeLabel)")
        }

        if previous.recordedFitMode != newest.recordedFitMode {
            lines.append("\(previous.recordedFitMode.displayTitle) → \(newest.recordedFitMode.displayTitle)")
        }

        if previous.successCount != newest.successCount {
            lines.append("\(previous.photoCountLabel) → \(newest.photoCountLabel)")
        }

        if previous.watermarkEnabled != newest.watermarkEnabled {
            let prev = previous.watermarkEnabled ? "Watermark on" : "Watermark off"
            let next = newest.watermarkEnabled ? "Watermark on" : "Watermark off"
            lines.append("\(prev) → \(next)")
        }

        let prevDate = previous.createdAt
        let newDate = newest.createdAt
        if abs(prevDate.timeIntervalSince(newDate)) > 0.5 {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            lines.append("\(formatter.string(from: prevDate)) → \(formatter.string(from: newDate))")
        }

        return lines
    }
}

struct ExportHistoryComparison: Equatable {
    var hasPrevious: Bool
    var lines: [String]
    var summaryText: String
}

extension ProjectExportBatch {
    /// Primary history row line: marketplace + canvas (destination and size stay distinct).
    var historyPrimaryLine: String {
        let market: String
        if marketplaceTargetRaw.isEmpty {
            market = "Earlier export"
        } else {
            market = recordedMarketplaceTarget.displayTitle
        }
        return "\(market) • \(pixelSizeLabel)"
    }

    var historySecondaryLine: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        var parts = [
            formatter.string(from: createdAt),
            photoCountLabel,
            recordedFitMode.displayTitle
        ]
        if watermarkEnabled {
            parts.append("Watermark")
        }
        return parts.joined(separator: " · ")
    }
}
