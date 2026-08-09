import XCTest
import SwiftData
import UIKit
import CoreGraphics
@testable import Yofai

@MainActor
final class Phase36VerifiedMarketplaceExportPresetsTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: YofaiModelSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: YofaiModelSchema.schema, configurations: [configuration])
    }

    private func makeImage(color: UIColor, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    func testEbayPresetIsExactly1600x1600() {
        XCTAssertEqual(ListingExportPreset.ebay.pixelSize, CGSize(width: 1600, height: 1600))
        XCTAssertEqual(ListingExportPreset.ebay.rawValue, "eBay")
        XCTAssertEqual(ListingExportPreset.ebay.displayTitle, "eBay")
        XCTAssertEqual(ListingExportPreset.ebay.pixelSizeLabel, "1600×1600")
        XCTAssertEqual(ListingExportPreset.ebay.pickerLabel, "eBay (1600×1600)")
        XCTAssertEqual(ListingExportPreset.ebay.sellerGroup, .listing)
    }

    func testPoshmarkPresetIsExactly1000x1000() {
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSize, CGSize(width: 1000, height: 1000))
        XCTAssertEqual(ListingExportPreset.poshmark.rawValue, "Poshmark")
        XCTAssertEqual(ListingExportPreset.poshmark.displayTitle, "Poshmark")
        XCTAssertEqual(ListingExportPreset.poshmark.pixelSizeLabel, "1000×1000")
        XCTAssertEqual(ListingExportPreset.poshmark.pickerLabel, "Poshmark (1000×1000)")
        XCTAssertEqual(ListingExportPreset.poshmark.sellerGroup, .listing)
    }

    func testLegacyFivePhase33SizesAndRawValuesUnchanged() {
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.etsyListing.pixelSize, CGSize(width: 3000, height: 2400))
        XCTAssertEqual(ListingExportPreset.instagramSquare.pixelSize, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(ListingExportPreset.facebookPost.pixelSize, CGSize(width: 1200, height: 630))
        XCTAssertEqual(ListingExportPreset.marketplace.pixelSize, CGSize(width: 1600, height: 1600))

        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.etsyListing.rawValue, "Etsy listing")
        XCTAssertEqual(ListingExportPreset.instagramSquare.rawValue, "Instagram square")
        XCTAssertEqual(ListingExportPreset.facebookPost.rawValue, "Facebook post")
        XCTAssertEqual(ListingExportPreset.marketplace.rawValue, "Marketplace")
        XCTAssertEqual(ListingExportPreset.marketplace.displayTitle, "Square 1600")
    }

    func testCaseIterableCountIncreasedByTwoOnly() {
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.legacyPhase33Presets.count, 5)
        XCTAssertTrue(ListingExportPreset.allCases.contains(.ebay))
        XCTAssertTrue(ListingExportPreset.allCases.contains(.poshmark))
    }

    func testOldStoredPresetValuesStillDecode() {
        XCTAssertEqual(ListingExportPreset(rawValue: "Etsy square"), .etsySquare)
        XCTAssertEqual(ListingExportPreset(rawValue: "Marketplace"), .marketplace)
        XCTAssertEqual(ListingExportPreset(rawValue: "Facebook post"), .facebookPost)
        XCTAssertEqual(ListingExportPreset(rawValue: "eBay"), .ebay)
        XCTAssertEqual(ListingExportPreset(rawValue: "Poshmark"), .poshmark)
        XCTAssertNil(ListingExportPreset(rawValue: "Facebook Marketplace"))
        XCTAssertNil(ListingExportPreset(rawValue: "Mercari"))
    }

    func testSellerDefaultsAndPhotoEditStateAcceptNewPresets() {
        var defaults = SellerDefaults()
        defaults.exportPreset = .ebay
        XCTAssertEqual(defaults.exportPresetRaw, "eBay")
        defaults.exportPreset = .poshmark
        XCTAssertEqual(defaults.exportPresetRaw, "Poshmark")

        var state = PhotoEditState()
        state.exportPreset = .ebay
        XCTAssertTrue(state.listingSummary.contains("eBay"))
        XCTAssertTrue(state.listingSummary.contains("1600×1600"))
        state.exportPreset = .poshmark
        XCTAssertTrue(state.listingSummary.contains("Poshmark"))
        XCTAssertTrue(state.listingSummary.contains("1000×1000"))
    }

    func testPhotoCheckCanvasSupportsEbayAndPoshmark() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let ebayFile = try LocalEditStore.saveProjectImage(makeImage(color: .blue, size: CGSize(width: 800, height: 800)))
        let ebayPhoto = ItemProjectPhoto(localFileName: ebayFile, sortOrder: 0)
        let ebayProject = ItemProject(name: "eBay item", photos: [ebayPhoto])
        ebayProject.listingExportPreset = .ebay
        context.insert(ebayProject)

        let ebayFacts = PhotoTechnicalCheck.facts(for: ebayPhoto, project: ebayProject)
        XCTAssertEqual(ebayFacts.exportCanvasPreset, .ebay)
        XCTAssertEqual(ebayFacts.exportCanvasWidth, 1600)
        XCTAssertEqual(ebayFacts.exportCanvasHeight, 1600)
        XCTAssertEqual(ebayFacts.sourceSmallerThanExportCanvas, true)

        let poshFile = try LocalEditStore.saveProjectImage(makeImage(color: .green, size: CGSize(width: 1000, height: 1000)))
        let poshPhoto = ItemProjectPhoto(localFileName: poshFile, sortOrder: 0)
        let poshProject = ItemProject(name: "Posh item", photos: [poshPhoto])
        poshProject.listingExportPreset = .poshmark
        context.insert(poshProject)

        let poshFacts = PhotoTechnicalCheck.facts(for: poshPhoto, project: poshProject)
        XCTAssertEqual(poshFacts.exportCanvasPreset, .poshmark)
        XCTAssertEqual(poshFacts.exportCanvasWidth, 1000)
        XCTAssertEqual(poshFacts.exportCanvasHeight, 1000)
        XCTAssertEqual(poshFacts.sourceSmallerThanExportCanvas, false)
        XCTAssertEqual(poshFacts.sourceAspectDiffersFromCanvas, false)
    }

    func testBatchExportUsesEbayAndPoshmarkCanvasSizes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let file = try LocalEditStore.saveProjectImage(makeImage(color: .orange, size: CGSize(width: 400, height: 400)))
        let photo = ItemProjectPhoto(localFileName: file, sortOrder: 0)
        let project = ItemProject(name: "Batch", photos: [photo])
        project.listingExportPreset = .ebay
        context.insert(project)

        let ebayResult = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(ebayResult.successCount, 1)
        guard let ebayURL = LocalEditStore.exportBatchFileURL(folderName: ebayResult.batchFolderName, fileName: "01.jpg"),
              let ebayData = try? Data(contentsOf: ebayURL),
              let ebayImage = UIImage(data: ebayData) else {
            return XCTFail("Missing eBay export JPEG")
        }
        XCTAssertEqual(Int(ebayImage.size.width), 1600)
        XCTAssertEqual(Int(ebayImage.size.height), 1600)

        project.listingExportPreset = .poshmark
        let poshResult = try ProjectBatchExporter.export(project: project)
        XCTAssertEqual(poshResult.successCount, 1)
        guard let poshURL = LocalEditStore.exportBatchFileURL(folderName: poshResult.batchFolderName, fileName: "01.jpg"),
              let poshData = try? Data(contentsOf: poshURL),
              let poshImage = UIImage(data: poshData) else {
            return XCTFail("Missing Poshmark export JPEG")
        }
        XCTAssertEqual(Int(poshImage.size.width), 1000)
        XCTAssertEqual(Int(poshImage.size.height), 1000)
    }

    func testNoFacebookMarketplaceOrMercariNamedPresets() {
        let rawValues = ListingExportPreset.allCases.map { $0.rawValue.lowercased() }
        let display = ListingExportPreset.allCases.map { $0.displayTitle.lowercased() }
        XCTAssertFalse(rawValues.contains("facebook marketplace"))
        XCTAssertFalse(rawValues.contains("mercari"))
        XCTAssertFalse(display.contains("facebook marketplace"))
        XCTAssertFalse(display.contains("mercari"))
        XCTAssertTrue(ListingExportPreset.localExportDisclaimer.lowercased().contains("not marketplace compliance"))
    }

    func testProjectPersistsNewPresetSelection() throws {
        let container = try makeContainer()
        let projectID: PersistentIdentifier
        do {
            let context = ModelContext(container)
            let project = ItemProject(name: "Persist", photos: [])
            project.listingExportPreset = .poshmark
            context.insert(project)
            try context.save()
            projectID = project.persistentModelID
        }
        let reload = ModelContext(container)
        let project = reload.model(for: projectID) as! ItemProject
        XCTAssertEqual(project.listingExportPreset, .poshmark)
        XCTAssertEqual(project.listingExportPresetRaw, "Poshmark")
    }
}
