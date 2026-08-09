import XCTest
import SwiftData
@testable import Yofai

@MainActor
final class Phase23ListingDraftTests: XCTestCase {
    func testNormalizedTagsRemoveBlanksAndPreserveOrder() {
        let tags = ItemProject.normalizedTags(fromRaw: " wood, , brass ,, handmade , ")
        XCTAssertEqual(tags, ["wood", "brass", "handmade"])
    }

    func testValidationRejectsBlankTitleInvalidPriceLowQuantityAndTooManyTags() throws {
        let schema = YofaiModelSchema.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let project = ItemProject(name: "Lamp")
        context.insert(project)

        XCTAssertFalse(project.isListingDraftComplete)
        XCTAssertTrue(project.listingDraftIssues.contains("Title is required"))
        XCTAssertTrue(project.listingDraftIssues.contains("Price is required"))

        project.listingTitle = "Ceramic Lamp"
        project.listingPriceText = "abc"
        project.listingQuantity = 0
        project.listingTags = (1...14).map { "tag\($0)" }
        XCTAssertTrue(project.listingDraftIssues.contains("Price must be a valid amount"))
        XCTAssertTrue(project.listingDraftIssues.contains("Quantity must be at least 1"))
        XCTAssertTrue(project.listingDraftIssues.contains("Maximum 13 tags"))

        project.listingPriceText = "-1"
        XCTAssertTrue(project.listingDraftIssues.contains("Price must be nonnegative"))

        project.listingPriceText = "24.50"
        project.listingQuantity = 2
        project.listingTags = ItemProject.normalizedTags(fromRaw: "a,b,c")
        project.listingDescription = "A warm lamp"
        project.listingCategory = "Home & Living"
        project.listingMaterials = "ceramic, brass"
        project.listingShippingProfile = "US standard"
        project.listingProcessingTime = "1-3 days"
        project.touchModified()
        try context.save()

        XCTAssertTrue(project.isListingDraftComplete)
        XCTAssertEqual(project.listingTitle, "Ceramic Lamp")
        XCTAssertEqual(project.parsedListingPrice, Decimal(string: "24.50"))
        XCTAssertEqual(project.listingQuantity, 2)
        XCTAssertEqual(project.listingTags.count, 3)
    }

    func testListingFieldsPersistAcrossContextReload() throws {
        let schema = YofaiModelSchema.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])

        let projectID: PersistentIdentifier
        do {
            let context = ModelContext(container)
            let project = ItemProject(name: "Persist Me")
            project.listingTitle = "Persist Title"
            project.listingDescription = "Desc"
            project.listingPriceText = "10"
            project.listingQuantity = 3
            project.listingCategory = "Art"
            project.listingTags = ["one", "two"]
            project.listingMaterials = "clay"
            project.listingShippingProfile = "Free"
            project.listingProcessingTime = "3-5 business days"
            context.insert(project)
            try context.save()
            projectID = project.persistentModelID
        }

        let reload = ModelContext(container)
        let fetched = reload.model(for: projectID) as? ItemProject
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.listingTitle, "Persist Title")
        XCTAssertEqual(fetched?.listingDescription, "Desc")
        XCTAssertEqual(fetched?.listingPriceText, "10")
        XCTAssertEqual(fetched?.listingQuantity, 3)
        XCTAssertEqual(fetched?.listingCategory, "Art")
        XCTAssertEqual(fetched?.listingTags, ["one", "two"])
        XCTAssertEqual(fetched?.listingMaterials, "clay")
        XCTAssertEqual(fetched?.listingShippingProfile, "Free")
        XCTAssertEqual(fetched?.listingProcessingTime, "3-5 business days")
        XCTAssertTrue(fetched?.isListingDraftComplete == true)
    }
}
