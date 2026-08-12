import XCTest
import UIKit
@testable import Yofai

@MainActor
final class Phase71LaunchMarkSizingTests: XCTestCase {
    func testLaunchMarkLoadsAtCenteredMarkPointSize() {
        let image = UIImage(named: "LaunchMark")
        XCTAssertNotNil(image, "LaunchMark asset must exist")
        guard let image else { return }

        // UILaunchScreen centers the image at its point size (does not scale-to-fit).
        // A ~160pt mark keeps the full logo visible on iPhone; 1024@1x filled/cropped the screen.
        XCTAssertEqual(image.size.width, 160, accuracy: 1)
        XCTAssertEqual(image.size.height, 160, accuracy: 1)
        XCTAssertLessThan(image.size.width, 400)
        XCTAssertLessThan(image.size.height, 400)
    }

    func testLaunchBackgroundColorExists() {
        XCTAssertNotNil(UIColor(named: "LaunchBackground"))
    }

    func testProductIDsAndPresetsUnchanged() {
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertNil(MarketplaceTarget.facebookMarketplace.recommendedExportPreset)
        XCTAssertNil(MarketplaceTarget.mercari.recommendedExportPreset)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
    }
}
