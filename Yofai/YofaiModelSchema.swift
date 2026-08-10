import Foundation
import SwiftData

enum YofaiModelSchema {
    static let models: [any PersistentModel.Type] = [
        SavedEdit.self,
        ImportedOriginal.self,
        ItemProject.self,
        ItemProjectPhoto.self,
        ListingQueueEntry.self,
        ProjectExportBatch.self,
        ListingPackage.self,
        AIPreparationRecord.self,
        PhotoPlanGoal.self,
        MarketplaceListingDraft.self
    ]

    static var schema: Schema {
        Schema(models)
    }
}
