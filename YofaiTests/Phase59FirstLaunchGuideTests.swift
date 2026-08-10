import XCTest
@testable import Yofai

@MainActor
final class Phase59FirstLaunchGuideTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "yofai.tests.firstLaunch.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testGuideShowsOnlyUntilCompletedOrSkipped() {
        let store = FirstLaunchGuideStore(defaults: defaults)
        let presenter = FirstLaunchGuidePresenter(store: store)

        XCTAssertFalse(store.hasCompletedGuide)
        presenter.presentIfNeededOnLaunch()
        XCTAssertTrue(presenter.isPresented)

        presenter.dismissFinished()
        XCTAssertTrue(store.hasCompletedGuide)
        XCTAssertFalse(presenter.isPresented)

        presenter.presentIfNeededOnLaunch()
        XCTAssertFalse(presenter.isPresented)
    }

    func testReplayFromSettingsWorksAfterCompletion() {
        let store = FirstLaunchGuideStore(defaults: defaults)
        let presenter = FirstLaunchGuidePresenter(store: store)
        store.markCompleted()

        presenter.presentIfNeededOnLaunch()
        XCTAssertFalse(presenter.isPresented)

        presenter.presentReplay()
        XCTAssertTrue(presenter.isPresented)

        presenter.dismissFinished()
        XCTAssertTrue(store.hasCompletedGuide)
        XCTAssertFalse(presenter.isPresented)
    }

    func testWalkthroughPagesMatchRequiredOrder() {
        XCTAssertEqual(FirstLaunchGuidePage.allCases.map(\.title), [
            "Yofai",
            "Start a Product",
            "Add Photos",
            "Photo Check",
            "Edit / Fit / Reposition",
            "Export Local JPEGs",
            "View / Share Export History",
            "Yofai Pro"
        ])
        XCTAssertEqual(FirstLaunchGuidePage.walkthroughPages.count, 7)
        XCTAssertEqual(FirstLaunchGuidePage.welcome.primaryButtonTitle, "Get Started")
        XCTAssertEqual(FirstLaunchGuidePage.startProduct.primaryButtonTitle, "Continue")
        XCTAssertEqual(FirstLaunchGuidePage.yofaiPro.primaryButtonTitle, "Done")
        XCTAssertEqual(FirstLaunchGuideCopy.skip, "Skip")
    }

    func testCopyAvoidsRiskyClaimsAndStaysOfflineLocal() {
        for text in FirstLaunchGuideCopy.allUserFacingStrings {
            XCTAssertFalse(
                AppStoreLaunchSupport.containsActiveAIProductClaim(text),
                "AI claim in: \(text)"
            )
            XCTAssertFalse(
                text.localizedCaseInsensitiveContains("Direct Upload"),
                "Direct Upload in: \(text)"
            )
            XCTAssertFalse(
                text.localizedCaseInsensitiveContains("upload to etsy"),
                "Upload claim in: \(text)"
            )
            XCTAssertFalse(
                text.localizedCaseInsensitiveContains("publish to ebay"),
                "Publish claim in: \(text)"
            )
            XCTAssertFalse(
                FreemiumCopy.purchaseSuccessPro == text,
                "Fake Pro success copy must not be a guide string"
            )
        }

        XCTAssertTrue(FirstLaunchGuideCopy.exportLocalBody.localizedCaseInsensitiveContains("manual upload"))
        XCTAssertTrue(FirstLaunchGuideCopy.photoCheckBody.localizedCaseInsensitiveContains("deterministic"))
        XCTAssertTrue(FirstLaunchGuideCopy.yofaiProBody.localizedCaseInsensitiveContains("optional"))
        XCTAssertTrue(FirstLaunchGuideCopy.yofaiProBody.localizedCaseInsensitiveContains("Free"))
        XCTAssertFalse(FirstLaunchGuideCopy.yofaiProBody.localizedCaseInsensitiveContains("purchase success"))
    }

    func testPersistenceKeyAndReset() {
        let store = FirstLaunchGuideStore(defaults: defaults)
        XCTAssertEqual(FirstLaunchGuideStore.completedKey, "yofai.firstLaunchGuide.completed.v1")
        store.markCompleted()
        XCTAssertTrue(defaults.bool(forKey: FirstLaunchGuideStore.completedKey))

        store.resetCompletionForTesting()
        XCTAssertFalse(store.hasCompletedGuide)
        XCTAssertFalse(defaults.bool(forKey: FirstLaunchGuideStore.completedKey))
    }

    func testStoreKitProductIDsAndPresetsUnchanged() {
        XCTAssertEqual(YofaiProductIDs.monthly, "com.shawnwright.yofai.pro.monthly")
        XCTAssertEqual(YofaiProductIDs.yearly, "com.shawnwright.yofai.pro.yearly")
        XCTAssertEqual(ListingExportPreset.allCases.count, 7)
        XCTAssertEqual(ListingExportPreset.etsySquare.pixelSize.width, 2000)
        XCTAssertEqual(ListingExportPreset.etsyListing.pixelSize.height, 2400)
        XCTAssertEqual(YofaiProductMode.current, .localExport)
        XCTAssertFalse(YofaiProductMode.directUpload.isImplemented)
    }

    func testFreeLocalExportStillAvailableWithoutGuideCompletionFlag() {
        // Guide completion must not gate Free core export helpers.
        XCTAssertFalse(LocalExportShareSupport.containsForbiddenShareWording(
            FirstLaunchGuideCopy.exportLocalBody
        ))
        XCTAssertEqual(FreemiumLimits.launch.freeActiveProductLimit, 12)
        XCTAssertEqual(EntitlementStore.shared.state.plan, .free)
    }

    func testMotionTimingsStayShortAndHonorReduceMotion() {
        XCTAssertLessThanOrEqual(FirstLaunchGuideMotion.welcomeDuration, 0.7)
        XCTAssertLessThanOrEqual(FirstLaunchGuideMotion.pageDuration, 0.5)
        XCTAssertLessThanOrEqual(FirstLaunchGuideMotion.stepContentDuration, 0.5)
        XCTAssertGreaterThan(FirstLaunchGuideMotion.frameDelayNanoseconds, 0)
        XCTAssertEqual(FirstLaunchGuideMotion.demoStageHeight, 220)
        XCTAssertNil(FirstLaunchGuideMotion.welcomeAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.pageAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.stepContentAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.chromeAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.sceneEnterAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.sceneActAnimation(reduceMotion: true))
        XCTAssertNil(FirstLaunchGuideMotion.sceneSettleAnimation(reduceMotion: true))
        XCTAssertNotNil(FirstLaunchGuideMotion.pageAnimation(reduceMotion: false))
        XCTAssertNotNil(FirstLaunchGuideMotion.stepContentAnimation(reduceMotion: false))
        XCTAssertNotNil(FirstLaunchGuideMotion.sceneEnterAnimation(reduceMotion: false))
    }

    func testSceneKindsMapToEveryGuidePage() {
        XCTAssertEqual(FirstLaunchGuideScenePhase.allCases.count, 4)
        XCTAssertEqual(FirstLaunchGuideSceneKind.allCases.count, FirstLaunchGuidePage.allCases.count)
        XCTAssertEqual(
            FirstLaunchGuidePage.allCases.map { FirstLaunchGuideSceneKind.kind(for: $0) },
            FirstLaunchGuideSceneKind.allCases
        )
        XCTAssertEqual(FirstLaunchGuideScenePhase.idle.hasEntered, false)
        XCTAssertEqual(FirstLaunchGuideScenePhase.enter.hasEntered, true)
        XCTAssertEqual(FirstLaunchGuideScenePhase.act.hasActed, true)
        XCTAssertEqual(FirstLaunchGuideScenePhase.settle.hasSettled, true)
    }
}
