import Foundation
import SwiftData

@Model
final class ProjectExportBatch {
    var createdAt: Date
    /// Folder name under Application Support/ExportBatches (not under ItemProjects).
    var batchFolderName: String
    var orderedFileNames: [String]
    var successCount: Int
    /// Safe per-photo error messages (no paths with secrets).
    var errorMessages: [String]
    var project: ItemProject?

    // Phase 40 — export history metadata (defaults keep pre-Phase-40 rows loadable).
    /// Empty = legacy batch before Phase 40 (display falls back safely).
    var marketplaceTargetRaw: String = ""
    var exportPresetRaw: String = ""
    var exportFitModeRaw: String = ""
    var exportCanvasWidth: Int = 0
    var exportCanvasHeight: Int = 0
    var watermarkEnabled: Bool = false
    /// Phase 44 — optional local seller note. Empty = no note (legacy-safe default).
    var sellerNote: String = ""

    init(
        createdAt: Date = .now,
        batchFolderName: String,
        orderedFileNames: [String] = [],
        successCount: Int = 0,
        errorMessages: [String] = [],
        project: ItemProject? = nil,
        marketplaceTargetRaw: String = "",
        exportPresetRaw: String = "",
        exportFitModeRaw: String = "",
        exportCanvasWidth: Int = 0,
        exportCanvasHeight: Int = 0,
        watermarkEnabled: Bool = false,
        sellerNote: String = ""
    ) {
        self.createdAt = createdAt
        self.batchFolderName = batchFolderName
        self.orderedFileNames = orderedFileNames
        self.successCount = successCount
        self.errorMessages = errorMessages
        self.project = project
        self.marketplaceTargetRaw = marketplaceTargetRaw
        self.exportPresetRaw = exportPresetRaw
        self.exportFitModeRaw = exportFitModeRaw
        self.exportCanvasWidth = exportCanvasWidth
        self.exportCanvasHeight = exportCanvasHeight
        self.watermarkEnabled = watermarkEnabled
        self.sellerNote = ExportBatchNoteSupport.normalized(sellerNote)
    }

    var fileURLs: [URL] {
        orderedFileNames.compactMap { LocalEditStore.exportBatchFileURL(folderName: batchFolderName, fileName: $0) }
    }

    var hasShareableFiles: Bool {
        !fileURLs.isEmpty
    }

    /// True when this row was recorded after a successful export (Phase 40 history).
    var isCompletedExport: Bool {
        successCount > 0
    }

    var recordedMarketplaceTarget: MarketplaceTarget {
        if marketplaceTargetRaw.isEmpty {
            return .other
        }
        return MarketplaceTarget.resolved(rawValue: marketplaceTargetRaw)
    }

    var recordedExportPreset: ListingExportPreset? {
        guard !exportPresetRaw.isEmpty else { return nil }
        return ListingExportPreset(rawValue: exportPresetRaw)
    }

    var recordedFitMode: ListingExportFitMode {
        ListingExportFitMode.resolved(rawValue: exportFitModeRaw.isEmpty ? nil : exportFitModeRaw)
    }

    var pixelSizeLabel: String {
        if exportCanvasWidth > 0, exportCanvasHeight > 0 {
            return "\(exportCanvasWidth)×\(exportCanvasHeight)"
        }
        if let preset = recordedExportPreset {
            return preset.pixelSizeLabel
        }
        return "—"
    }

    var photoCountLabel: String {
        "\(successCount) photo\(successCount == 1 ? "" : "s")"
    }

    /// Seller-facing compact label. Destination and canvas stay distinct.
    var sellerSummaryLabel: String {
        let market: String
        if marketplaceTargetRaw.isEmpty {
            market = "Earlier export"
        } else {
            market = recordedMarketplaceTarget.displayTitle
        }
        return "\(market) • \(pixelSizeLabel) • \(photoCountLabel)"
    }

    var exportedForLine: String {
        LocalExportShareSupport.exportedForPhrase(for: self)
    }

    var resultSummaryText: String {
        LocalExportShareSupport.resultSummaryText(for: self)
    }

    /// Creates a history row only for successful exports. Captures project export settings at export time.
    static func recordSuccessfulExport(
        from result: ProjectBatchExportResult,
        project: ItemProject
    ) -> ProjectExportBatch? {
        guard result.successCount > 0 else { return nil }
        let preset = project.listingExportPreset
        return ProjectExportBatch(
            batchFolderName: result.batchFolderName,
            orderedFileNames: result.orderedFileNames,
            successCount: result.successCount,
            errorMessages: result.errorMessages,
            project: project,
            marketplaceTargetRaw: project.listingMarketplaceTarget.rawValue,
            exportPresetRaw: preset.rawValue,
            exportFitModeRaw: project.listingExportFitMode.rawValue,
            exportCanvasWidth: Int(preset.pixelSize.width),
            exportCanvasHeight: Int(preset.pixelSize.height),
            watermarkEnabled: project.listingWatermarkEnabled
        )
    }

    /// Restores export-level settings only. Does not touch per-photo edits or offsets.
    func applyExportSettings(to project: ItemProject) {
        if !marketplaceTargetRaw.isEmpty {
            project.listingMarketplaceTarget = recordedMarketplaceTarget
        }
        if let preset = recordedExportPreset {
            project.listingExportPreset = preset
        }
        if !exportFitModeRaw.isEmpty {
            project.listingExportFitMode = recordedFitMode
        }
        project.listingWatermarkEnabled = watermarkEnabled
        project.touchModified()
    }
}

extension ItemProject {
    var sortedCompletedExportBatches: [ProjectExportBatch] {
        sortedExportBatches.filter(\.isCompletedExport)
    }
}
