import Foundation
import SwiftData

/// Local listing-queue helpers. No network. Never invents upload/Completed results.
enum ListingQueueSupport {
    /// Issues that block Ready (Phase 25 readiness rules).
    static func readinessIssues(for project: ItemProject) -> [String] {
        var issues = project.listingDraftIssues
        let hasExistingPhotoFile = project.sortedPhotos.contains {
            LocalEditStore.projectFileExists(fileName: $0.localFileName)
        }
        if !hasExistingPhotoFile {
            issues.insert("At least one photo file is required", at: 0)
        }
        return issues
    }

    static func isReady(_ project: ItemProject) -> Bool {
        readinessIssues(for: project).isEmpty
    }

    static func completenessSummary(for project: ItemProject) -> String {
        let issues = readinessIssues(for: project)
        if issues.isEmpty {
            return "Draft complete"
        }
        return "Incomplete"
    }

    static func missingRequiredSummary(for project: ItemProject) -> String {
        let issues = readinessIssues(for: project)
        if issues.isEmpty {
            return "None"
        }
        return issues.joined(separator: " · ")
    }

    /// Updates Needs Details / Ready from saved draft + photo files.
    /// Does not invent Completed. Demotes Completed/Failed/Processing when no longer ready.
    static func syncReadiness(for entry: ListingQueueEntry) {
        guard let project = entry.project else {
            entry.status = .failed
            return
        }
        let ready = isReady(project)
        switch entry.status {
        case .completed:
            if !ready {
                entry.status = .needsDetails
            }
        case .processing:
            if !ready {
                entry.status = .needsDetails
            }
        case .failed, .needsDetails, .ready:
            entry.status = ready ? .ready : .needsDetails
        }
        entry.updatedAt = .now
    }

    @discardableResult
    static func add(project: ItemProject, in context: ModelContext) -> ListingQueueEntry? {
        let existing = try? context.fetch(FetchDescriptor<ListingQueueEntry>())
        if let existing, existing.contains(where: { $0.project?.persistentModelID == project.persistentModelID }) {
            return nil
        }
        let nextOrder = (existing?.map(\.sortOrder).max() ?? -1) + 1
        let entry = ListingQueueEntry(project: project, sortOrder: nextOrder)
        syncReadiness(for: entry)
        context.insert(entry)
        return entry
    }

    static func queueEntry(for project: ItemProject, in context: ModelContext) -> ListingQueueEntry? {
        let projectID = project.persistentModelID
        let entries = (try? context.fetch(FetchDescriptor<ListingQueueEntry>())) ?? []
        return entries.first { $0.project?.persistentModelID == projectID }
    }

    static func isQueued(_ project: ItemProject, in context: ModelContext) -> Bool {
        queueEntry(for: project, in: context) != nil
    }

    static func remove(_ entry: ListingQueueEntry, in context: ModelContext) {
        entry.project = nil
        context.delete(entry)
    }

    /// Validates queued drafts locally. Ready items may briefly enter Processing, then return to Ready or Failed.
    /// Does not upload. Does not mark Completed (Completed is mock/test-controlled only).
    static func prepareQueue(_ entries: [ListingQueueEntry]) {
        let ordered = entries.sorted { $0.sortOrder < $1.sortOrder }
        for entry in ordered {
            syncReadiness(for: entry)

            // Leave explicitly completed entries alone when still ready.
            if entry.status == .completed {
                continue
            }

            guard let project = entry.project else {
                entry.status = .failed
                continue
            }

            guard entry.status == .ready, isReady(project) else {
                entry.status = isReady(project) ? .ready : .needsDetails
                continue
            }

            // Only Ready may enter Processing.
            entry.status = .processing
            if isReady(project) {
                entry.status = .ready
            } else {
                entry.status = .failed
            }
        }
    }

    static func reorder(_ entries: [ListingQueueEntry], from source: IndexSet, to destination: Int) {
        var ordered = entries.sorted { $0.sortOrder < $1.sortOrder }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in ordered.enumerated() {
            entry.sortOrder = index
            entry.updatedAt = .now
        }
    }

    /// Local bulk prepare: validate all queued projects, process only Ready, skip Needs Details.
    /// Never uploads. Never marks Completed.
    @discardableResult
    static func prepareReadyListings(_ entries: [ListingQueueEntry]) -> PrepareReadyListingsSummary {
        let ordered = entries.sorted { $0.sortOrder < $1.sortOrder }

        for entry in ordered {
            syncReadiness(for: entry)

            if entry.status == .completed {
                continue
            }

            guard let project = entry.project else {
                entry.status = .failed
                continue
            }

            // Skip Needs Details — do not enter Processing.
            if entry.status == .needsDetails || !isReady(project) {
                entry.status = .needsDetails
                continue
            }

            guard entry.status == .ready else {
                continue
            }

            entry.status = .processing
            if isReady(project) {
                entry.status = .ready
            } else {
                entry.status = .failed
            }
        }

        var ready = 0
        var needs = 0
        var failed = 0
        for entry in ordered {
            switch entry.status {
            case .ready, .completed:
                ready += 1
            case .needsDetails:
                needs += 1
            case .failed:
                failed += 1
            case .processing:
                // Should not remain after prepare; treat as failed validation.
                failed += 1
            }
        }

        return PrepareReadyListingsSummary(
            readyCount: ready,
            needsDetailsCount: needs,
            failedValidationCount: failed
        )
    }
}

struct PrepareReadyListingsSummary: Equatable {
    var readyCount: Int
    var needsDetailsCount: Int
    var failedValidationCount: Int

    var displayMessage: String {
        "Ready \(readyCount) · Needs Details \(needsDetailsCount) · Failed \(failedValidationCount). Nothing was uploaded."
    }
}
