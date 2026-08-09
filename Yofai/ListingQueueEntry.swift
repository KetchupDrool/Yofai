import Foundation
import SwiftData

enum ListingQueueStatus: String, Codable, CaseIterable, Equatable {
    case needsDetails = "Needs Details"
    case ready = "Ready"
    case processing = "Processing"
    case failed = "Failed"
    case completed = "Completed"

    var displayName: String { rawValue }
}

@Model
final class ListingQueueEntry {
    var sortOrder: Int
    var statusRaw: String
    var createdAt: Date
    var updatedAt: Date
    var project: ItemProject?

    init(
        project: ItemProject,
        sortOrder: Int,
        status: ListingQueueStatus = .needsDetails,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.project = project
        self.sortOrder = sortOrder
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var status: ListingQueueStatus {
        get { ListingQueueStatus(rawValue: statusRaw) ?? .needsDetails }
        set {
            statusRaw = newValue.rawValue
            updatedAt = .now
        }
    }
}
