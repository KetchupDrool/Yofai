import XCTest
import CoreGraphics
@testable import Yofai

final class Phase33SellerExportPresetClarityTests: XCTestCase {
    func testPixelSizesUnchanged() {
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize, CGSize(width: 2000, height: 2000))
        XCTAssertEqual(ListingExportPreset.etsyListing.pixelSize, CGSize(width: 3000, height: 2400))
        XCTAssertEqual(ListingExportPreset.instagramSquare.pixelSize, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(ListingExportPreset.facebookPost.pixelSize, CGSize(width: 1200, height: 630))
        XCTAssertEqual(ListingExportPreset.marketplace.pixelSize, CGSize(width: 1600, height: 1600))
    }

    func testStoredRawValuesUnchangedForPersistence() {
        XCTAssertEqual(ListingExportPreset.etsySquare.rawValue, "Etsy square")
        XCTAssertEqual(ListingExportPreset.etsyListing.rawValue, "Etsy listing")
        XCTAssertEqual(ListingExportPreset.instagramSquare.rawValue, "Instagram square")
        XCTAssertEqual(ListingExportPreset.facebookPost.rawValue, "Facebook post")
        XCTAssertEqual(ListingExportPreset.marketplace.rawValue, "Marketplace")
    }

    func testCaseIterableStillReturnsFivePresets() {
        // Phase 36 appended eBay + Poshmark; legacy five raw values remain first and unchanged.
        XCTAssertEqual(ListingExportPreset.legacyPhase33Presets.count, 5)
        XCTAssertEqual(
            ListingExportPreset.legacyPhase33Presets.map(\.rawValue),
            ["Etsy square", "Etsy listing", "Instagram square", "Facebook post", "Marketplace"]
        )
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
    }

    func testDisplayTitlesClarifyMarketplaceWithoutChangingRawValue() {
        XCTAssertEqual(ListingExportPreset.etsySquare.displayTitle, "Etsy square")
        XCTAssertEqual(ListingExportPreset.etsyListing.displayTitle, "Etsy listing")
        XCTAssertEqual(ListingExportPreset.instagramSquare.displayTitle, "Instagram square")
        XCTAssertEqual(ListingExportPreset.facebookPost.displayTitle, "Facebook post")
        XCTAssertEqual(ListingExportPreset.marketplace.displayTitle, "Square 1600")
        XCTAssertNotEqual(ListingExportPreset.marketplace.displayTitle, ListingExportPreset.marketplace.rawValue)
    }

    func testPickerLabelsIncludePixelSizes() {
        for preset in ListingExportPreset.allCases {
            XCTAssertTrue(preset.pickerLabel.contains(preset.displayTitle))
            XCTAssertTrue(preset.pickerLabel.contains(preset.pixelSizeLabel))
            XCTAssertEqual(
                preset.pixelSizeLabel,
                "\(Int(preset.pixelSize.width))×\(Int(preset.pixelSize.height))"
            )
        }
    }

    func testSellerGroups() {
        XCTAssertEqual(ListingExportPreset.etsySquare.sellerGroup, .listing)
        XCTAssertEqual(ListingExportPreset.etsyListing.sellerGroup, .listing)
        XCTAssertEqual(ListingExportPreset.marketplace.sellerGroup, .listing)
        XCTAssertEqual(ListingExportPreset.instagramSquare.sellerGroup, .otherCanvas)
        XCTAssertEqual(ListingExportPreset.facebookPost.sellerGroup, .otherCanvas)

        XCTAssertEqual(
            ListingExportPreset.presets(in: .listing).map(\.rawValue),
            ["Etsy square", "Etsy listing", "Marketplace", "eBay", "Poshmark"]
        )
        XCTAssertEqual(
            ListingExportPreset.presets(in: .otherCanvas).map(\.rawValue),
            ["Instagram square", "Facebook post"]
        )
    }

    func testDisplayCopyDoesNotClaimSpecificMarketplaceCompliance() {
        let joined = ListingExportPreset.allCases
            .map { "\($0.displayTitle) \($0.displaySubtitle) \($0.pickerLabel)" }
            .joined(separator: " | ")
            .lowercased()

        XCTAssertFalse(joined.contains("mercari"))
        XCTAssertFalse(joined.contains("facebook marketplace"))
        // Allowed: eBay / Poshmark as named recommended canvases; must not claim compliance.
        XCTAssertTrue(joined.contains("ebay"))
        XCTAssertTrue(joined.contains("poshmark"))
        XCTAssertTrue(ListingExportPreset.ebay.displaySubtitle.lowercased().contains("not a compliance guarantee"))
        XCTAssertTrue(ListingExportPreset.poshmark.displaySubtitle.lowercased().contains("not a compliance guarantee"))

        XCTAssertTrue(ListingExportPreset.facebookPost.displaySubtitle.lowercased().contains("not marketplace product"))
        XCTAssertTrue(ListingExportPreset.marketplace.displaySubtitle.lowercased().contains("generic square"))
        XCTAssertTrue(ListingExportPreset.localExportDisclaimer.lowercased().contains("not marketplace compliance"))
    }

    func testRawValueDecodingStillWorksForSellerDefaultsAndEditState() {
        XCTAssertEqual(ListingExportPreset(rawValue: "Marketplace"), .marketplace)
        XCTAssertEqual(ListingExportPreset(rawValue: "Etsy square"), .etsySquare)
        XCTAssertEqual(ListingExportPreset(rawValue: "Facebook post"), .facebookPost)

        var defaults = SellerDefaults()
        defaults.exportPreset = .marketplace
        XCTAssertEqual(defaults.exportPresetRaw, "Marketplace")
        XCTAssertEqual(defaults.exportPreset.displayTitle, "Square 1600")

        var state = PhotoEditState()
        state.exportPreset = .marketplace
        XCTAssertTrue(state.listingSummary.contains("Square 1600"))
        XCTAssertTrue(state.listingSummary.contains("1600×1600"))
    }
}
