import Foundation

/// Phase 43 — scroll/focus targets inside marketplace export controls (no routing framework).
enum ExportPrepScrollAnchor: String, Equatable {
    case exportSize
    case fit
    case photoCheck
    case readiness
    case prepTips
    case preview
}

/// Where a tip sends the seller. Tips never auto-change export settings.
enum ExportPrepTipAction: String, Equatable {
    case captureAndCheckPhotos
    case openPhotoCheck
    case openListingWorkspace
    case focusExportSize
    case focusFit
    case focusPreview
    case openReposition
    case none
}

enum ExportPrepTipID: String, Equatable {
    case addPhotos
    case missingFiles
    case invalidExportSize
    case reviewSmallPhotos
    case reviewFitPadding
    case reviewFitCropping
    case adjustCropPosition
    case checkCropPosition
    case finishListingDetails
    case readyPreview
}

struct ExportPrepTip: Equatable, Identifiable {
    var id: ExportPrepTipID
    var title: String
    var detail: String
    var actionLabel: String?
    var action: ExportPrepTipAction
    /// Lower number = higher priority.
    var priority: Int

    var accessibilitySummary: String {
        if let actionLabel {
            return "\(title). \(detail). Action: \(actionLabel)."
        }
        return "\(title). \(detail)."
    }
}

/// Phase 43 — deterministic prep tips from local readiness/Photo Check state. Not persisted.
enum ExportPrepTipSupport {
    static let maxVisibleTips = 3

    /// Generates prioritized tips. Does not mutate project state.
    static func tips(
        for project: ItemProject,
        summary: ExportReadinessSummary? = nil,
        limit: Int = maxVisibleTips
    ) -> [ExportPrepTip] {
        let readiness = summary ?? ExportReadiness.summary(for: project)
        let candidates = candidateTips(for: project, readiness: readiness)
        let unique = dedupePreservingPriority(candidates)
        return Array(unique.prefix(max(0, limit)))
    }

    /// Single highest-priority tip for compact surfaces, if any.
    static func topTip(for project: ItemProject, summary: ExportReadinessSummary? = nil) -> ExportPrepTip? {
        tips(for: project, summary: summary, limit: 1).first
    }

    /// First readable photo useful for Fill + Crop Reposition (aspect mismatch preferred).
    static func repositionPhoto(in project: ItemProject) -> ItemProjectPhoto? {
        guard project.listingExportFitMode == .fillCrop else { return nil }
        let photos = project.sortedPhotos
        let mismatch = photos.first { photo in
            let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
            return facts.filePresent && facts.fileReadable && facts.sourceAspectDiffersFromCanvas == true
        }
        if let mismatch { return mismatch }
        return photos.first { photo in
            let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
            return facts.filePresent && facts.fileReadable
        }
    }

    // MARK: - Generation

    private static func candidateTips(
        for project: ItemProject,
        readiness: ExportReadinessSummary
    ) -> [ExportPrepTip] {
        var tips: [ExportPrepTip] = []
        let photos = project.sortedPhotos

        if photos.isEmpty {
            tips.append(
                ExportPrepTip(
                    id: .addPhotos,
                    title: "Add product photos",
                    detail: "Capture or choose photos before export.",
                    actionLabel: SellerNavigationSupport.projectIntakeLinkTitle,
                    action: .captureAndCheckPhotos,
                    priority: 0
                )
            )
            return tips
        }

        var missing = 0
        var lowRes = 0
        var aspectMismatch = 0
        var cropAdjusted = 0

        for photo in photos {
            let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
            if !facts.filePresent || !facts.fileReadable {
                missing += 1
                continue
            }
            if facts.sourceSmallerThanExportCanvas == true { lowRes += 1 }
            if facts.sourceAspectDiffersFromCanvas == true { aspectMismatch += 1 }
            if facts.fillCropPositionAdjusted == true { cropAdjusted += 1 }
        }

        if missing > 0 {
            tips.append(
                ExportPrepTip(
                    id: .missingFiles,
                    title: "Fix missing photos",
                    detail: missing == 1
                        ? "1 photo file is missing or unreadable."
                        : "\(missing) photo files are missing or unreadable.",
                    actionLabel: SellerNavigationSupport.projectIntakeLinkTitle,
                    action: .captureAndCheckPhotos,
                    priority: 1
                )
            )
        }

        if ListingExportPreset(rawValue: project.listingExportPresetRaw) == nil {
            tips.append(
                ExportPrepTip(
                    id: .invalidExportSize,
                    title: "Check export size",
                    detail: "Pick a valid local export canvas.",
                    actionLabel: "Go to Export Size",
                    action: .focusExportSize,
                    priority: 2
                )
            )
        }

        if lowRes > 0 {
            tips.append(
                ExportPrepTip(
                    id: .reviewSmallPhotos,
                    title: "Review small photos",
                    detail: "Some photos are below the selected export size.",
                    actionLabel: "Open Photo Check",
                    action: .openPhotoCheck,
                    priority: 10
                )
            )
        }

        if aspectMismatch > 0 {
            switch project.listingExportFitMode {
            case .containPad:
                tips.append(
                    ExportPrepTip(
                        id: .reviewFitPadding,
                        title: "Review photo fit",
                        detail: "Contain + Pad will add background around some photos.",
                        actionLabel: "Go to Fit",
                        action: .focusFit,
                        priority: 20
                    )
                )
            case .fillCrop:
                tips.append(
                    ExportPrepTip(
                        id: .reviewFitCropping,
                        title: "Review photo fit",
                        detail: "Fill + Crop will trim edges on some photos.",
                        actionLabel: "Go to Fit",
                        action: .focusFit,
                        priority: 20
                    )
                )
            }
        }

        // Reposition when Fill + Crop can crop, or when a custom position exists (informational, not an error).
        if project.listingExportFitMode == .fillCrop, missing < photos.count {
            if aspectMismatch > 0, cropAdjusted == 0 {
                tips.append(
                    ExportPrepTip(
                        id: .adjustCropPosition,
                        title: "Adjust crop position",
                        detail: "Move the photo inside the export frame.",
                        actionLabel: "Reposition",
                        action: .openReposition,
                        priority: 25
                    )
                )
            } else if cropAdjusted > 0 {
                tips.append(
                    ExportPrepTip(
                        id: .checkCropPosition,
                        title: "Check crop position",
                        detail: "Some photos use a custom reposition.",
                        actionLabel: "Reposition",
                        action: .openReposition,
                        priority: 26
                    )
                )
            }
        }

        if !ListingQueueSupport.isReady(project) {
            tips.append(
                ExportPrepTip(
                    id: .finishListingDetails,
                    title: "Finish listing details",
                    detail: "Title, price, quantity, or tags still need a quick check.",
                    actionLabel: SellerNavigationSupport.projectWorkspaceLinkTitle,
                    action: .openListingWorkspace,
                    priority: 30
                )
            )
        }

        // Ready: optional preview tip only. No watermark tips. No guidance-only false warnings.
        if readiness.status == .ready, tips.isEmpty {
            tips.append(
                ExportPrepTip(
                    id: .readyPreview,
                    title: "Ready to export",
                    detail: "Preview the final framing before exporting.",
                    actionLabel: "Preview",
                    action: .focusPreview,
                    priority: 100
                )
            )
        }

        return tips
    }

    private static func dedupePreservingPriority(_ tips: [ExportPrepTip]) -> [ExportPrepTip] {
        var seen = Set<ExportPrepTipID>()
        var result: [ExportPrepTip] = []
        for tip in tips.sorted(by: { $0.priority < $1.priority }) {
            if seen.insert(tip.id).inserted {
                result.append(tip)
            }
        }
        return result
    }
}
