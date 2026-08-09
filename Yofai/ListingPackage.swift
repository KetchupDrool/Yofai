import Foundation
import SwiftData

@Model
final class ListingPackage {
    var createdAt: Date
    /// Folder under Application Support/ListingPackages
    var packageFolderName: String
    var photoCount: Int
    /// Source export batch folder name (metadata only; package copies files separately).
    var sourceBatchFolderName: String
    var jpegFileNames: [String]
    var detailsFileName: String
    var project: ItemProject?

    init(
        createdAt: Date = .now,
        packageFolderName: String,
        photoCount: Int,
        sourceBatchFolderName: String,
        jpegFileNames: [String],
        detailsFileName: String = "listing-details.txt",
        project: ItemProject? = nil
    ) {
        self.createdAt = createdAt
        self.packageFolderName = packageFolderName
        self.photoCount = photoCount
        self.sourceBatchFolderName = sourceBatchFolderName
        self.jpegFileNames = jpegFileNames
        self.detailsFileName = detailsFileName
        self.project = project
    }

    var fileURLs: [URL] {
        var urls: [URL] = []
        if let details = LocalEditStore.listingPackageFileURL(
            folderName: packageFolderName,
            fileName: detailsFileName
        ) {
            urls.append(details)
        }
        for name in jpegFileNames {
            if let url = LocalEditStore.listingPackageFileURL(folderName: packageFolderName, fileName: name) {
                urls.append(url)
            }
        }
        return urls
    }

    var hasShareableFiles: Bool {
        !fileURLs.isEmpty
    }
}

enum ListingPackageError: Error, Equatable {
    case noSuccessfulExportBatch
    case copyFailed
    case writeDetailsFailed
}

enum ListingPackageSupport {
    static func listingDetailsText(for project: ItemProject) -> String {
        let tags = project.listingTags.joined(separator: ", ")
        return """
        Title: \(project.listingTitle)
        Description: \(project.listingDescription)
        Price: \(project.listingPriceText)
        Quantity: \(project.listingQuantity)
        Category: \(project.listingCategory)
        Tags: \(tags)
        Materials: \(project.listingMaterials)
        Shipping profile: \(project.listingShippingProfile)
        Processing time: \(project.listingProcessingTime)
        """
    }

    static func newestSuccessfulBatch(for project: ItemProject) -> ProjectExportBatch? {
        project.sortedExportBatches.first { $0.successCount > 0 && $0.hasShareableFiles }
    }

    /// Creates a local package from the newest successful export batch. Does not modify source photos or batches.
    static func createPackage(for project: ItemProject) throws -> ListingPackage {
        guard let batch = newestSuccessfulBatch(for: project) else {
            throw ListingPackageError.noSuccessfulExportBatch
        }

        let folderName = try LocalEditStore.createListingPackageFolder()
        do {
            try LocalEditStore.copyExportBatchIntoListingPackage(
                batchFolderName: batch.batchFolderName,
                fileNames: batch.orderedFileNames,
                packageFolderName: folderName
            )
        } catch {
            LocalEditStore.deleteListingPackageFolder(folderName: folderName)
            throw ListingPackageError.copyFailed
        }

        do {
            try LocalEditStore.writeListingPackageDetails(
                ListingPackageSupport.listingDetailsText(for: project),
                packageFolderName: folderName,
                fileName: "listing-details.txt"
            )
        } catch {
            LocalEditStore.deleteListingPackageFolder(folderName: folderName)
            throw ListingPackageError.writeDetailsFailed
        }

        return ListingPackage(
            packageFolderName: folderName,
            photoCount: batch.orderedFileNames.count,
            sourceBatchFolderName: batch.batchFolderName,
            jpegFileNames: batch.orderedFileNames,
            detailsFileName: "listing-details.txt",
            project: project
        )
    }
}
