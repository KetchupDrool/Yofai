import Foundation
import Combine
import SwiftUI

/// First-launch welcome + guided walkthrough copy and page model.
/// Offline, no network. No AI / Direct Upload / publish / fake Pro success claims.
enum FirstLaunchGuidePage: Int, CaseIterable, Identifiable, Equatable {
    case welcome
    case startProduct
    case addPhotos
    case photoCheck
    case editFit
    case exportLocal
    case exportHistory
    case yofaiPro

    var id: Int { rawValue }

    var systemImage: String {
        switch self {
        case .welcome: return "camera.aperture"
        case .startProduct: return "shippingbox"
        case .addPhotos: return "photo.on.rectangle.angled"
        case .photoCheck: return "checkmark.seal"
        case .editFit: return "crop.rotate"
        case .exportLocal: return "square.and.arrow.down"
        case .exportHistory: return "clock.arrow.circlepath"
        case .yofaiPro: return "star.circle"
        }
    }

    var title: String {
        switch self {
        case .welcome: return FirstLaunchGuideCopy.welcomeTitle
        case .startProduct: return FirstLaunchGuideCopy.startProductTitle
        case .addPhotos: return FirstLaunchGuideCopy.addPhotosTitle
        case .photoCheck: return FirstLaunchGuideCopy.photoCheckTitle
        case .editFit: return FirstLaunchGuideCopy.editFitTitle
        case .exportLocal: return FirstLaunchGuideCopy.exportLocalTitle
        case .exportHistory: return FirstLaunchGuideCopy.exportHistoryTitle
        case .yofaiPro: return FirstLaunchGuideCopy.yofaiProTitle
        }
    }

    var bodyText: String {
        switch self {
        case .welcome: return FirstLaunchGuideCopy.welcomeBody
        case .startProduct: return FirstLaunchGuideCopy.startProductBody
        case .addPhotos: return FirstLaunchGuideCopy.addPhotosBody
        case .photoCheck: return FirstLaunchGuideCopy.photoCheckBody
        case .editFit: return FirstLaunchGuideCopy.editFitBody
        case .exportLocal: return FirstLaunchGuideCopy.exportLocalBody
        case .exportHistory: return FirstLaunchGuideCopy.exportHistoryBody
        case .yofaiPro: return FirstLaunchGuideCopy.yofaiProBody
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .welcome: return FirstLaunchGuideCopy.getStarted
        case .yofaiPro: return FirstLaunchGuideCopy.done
        default: return FirstLaunchGuideCopy.continueTitle
        }
    }

    var isWelcome: Bool { self == .welcome }

    static var walkthroughPages: [FirstLaunchGuidePage] {
        allCases.filter { $0 != .welcome }
    }
}

enum FirstLaunchGuideCopy {
    static let welcomeTitle = "Yofai"
    static let welcomeBody =
        "Marketplace product photo prep that exports local JPEGs for manual upload."
    static let startProductTitle = "Start a Product"
    static let startProductBody =
        "Create an Item Project for one listing so photos, checks, edits, and exports stay together."
    static let addPhotosTitle = "Add Photos"
    static let addPhotosBody =
        "Capture with the camera or choose existing photos. Everything stays on this device."
    static let photoCheckTitle = "Photo Check"
    static let photoCheckBody =
        "Run local Photo Check for framing and clarity facts before you edit. Checks are deterministic on-device — not AI."
    static let editFitTitle = "Edit / Fit / Reposition"
    static let editFitBody =
        "Fit photos to your export size with Contain + Pad or Fill + Crop, and reposition when you need a better crop."
    static let exportLocalTitle = "Export Local JPEGs"
    static let exportLocalBody =
        "Export listing-ready JPEGs saved on this iPhone for manual upload. You upload the files yourself in each marketplace."
    static let exportHistoryTitle = "View / Share Export History"
    static let exportHistoryBody =
        "Open export history to review, share, or re-find local JPEG packages when files are still on disk."
    static let yofaiProTitle = "Yofai Pro"
    static let yofaiProBody =
        "Yofai Pro is an optional Apple subscription for additive extras. Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export. Purchases use StoreKit when products are available — Free local export never requires a purchase."

    static let skip = "Skip"
    static let getStarted = "Get Started"
    static let continueTitle = "Continue"
    static let done = "Done"
    static let replayFromSettingsTitle = "Replay Welcome Guide"
    static let replayFromSettingsDetail = "Show the first-launch welcome and walkthrough again."
    static let pageIndicatorAccessibilityFormat = "Step %d of %d"

    static var allUserFacingStrings: [String] {
        [
            welcomeTitle, welcomeBody,
            startProductTitle, startProductBody,
            addPhotosTitle, addPhotosBody,
            photoCheckTitle, photoCheckBody,
            editFitTitle, editFitBody,
            exportLocalTitle, exportLocalBody,
            exportHistoryTitle, exportHistoryBody,
            yofaiProTitle, yofaiProBody,
            skip, getStarted, continueTitle, done,
            replayFromSettingsTitle, replayFromSettingsDetail
        ]
    }
}

/// Short motion timings for the first-launch guide. No video; Reduce Motion → nil / instant.
enum FirstLaunchGuideMotion {
    static let welcomeDuration: TimeInterval = 0.55
    static let pageDuration: TimeInterval = 0.35
    static let stepContentDuration: TimeInterval = 0.40
    static let chromeDuration: TimeInterval = 0.45
    /// One-frame delay so hide → show actually animates (same-runloop toggles are invisible).
    static let frameDelayNanoseconds: UInt64 = 16_000_000

    /// Staged demo beats (enter → act → settle). Kept short; not a video intro.
    static let sceneEnterDelayNanoseconds: UInt64 = 40_000_000
    static let sceneActDelayNanoseconds: UInt64 = 420_000_000
    static let sceneSettleDelayNanoseconds: UInt64 = 520_000_000
    static let demoStageHeight: CGFloat = 220

    static func welcomeAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: welcomeDuration, dampingFraction: 0.86)
    }

    static func pageAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: pageDuration)
    }

    static func stepContentAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: stepContentDuration, dampingFraction: 0.88)
    }

    static func chromeAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: chromeDuration)
    }

    static func sceneEnterAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.82)
    }

    static func sceneActAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.78)
    }

    static func sceneSettleAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.28)
    }
}

/// Demo stage timeline for each onboarding page.
enum FirstLaunchGuideScenePhase: Int, CaseIterable, Equatable {
    case idle
    case enter
    case act
    case settle

    var hasEntered: Bool { self != .idle }
    var hasActed: Bool { self == .act || self == .settle }
    var hasSettled: Bool { self == .settle }
}

/// One scene kind per guide page (testable mapping).
enum FirstLaunchGuideSceneKind: String, CaseIterable, Equatable {
    case welcomeBrand
    case startProduct
    case addPhotos
    case photoCheck
    case editFit
    case exportLocal
    case exportHistory
    case yofaiPro

    static func kind(for page: FirstLaunchGuidePage) -> FirstLaunchGuideSceneKind {
        switch page {
        case .welcome: return .welcomeBrand
        case .startProduct: return .startProduct
        case .addPhotos: return .addPhotos
        case .photoCheck: return .photoCheck
        case .editFit: return .editFit
        case .exportLocal: return .exportLocal
        case .exportHistory: return .exportHistory
        case .yofaiPro: return .yofaiPro
        }
    }
}

/// Persists whether the first-launch guide was completed or skipped.
@MainActor
final class FirstLaunchGuideStore: ObservableObject {
    static let shared = FirstLaunchGuideStore()

    static let completedKey = "yofai.firstLaunchGuide.completed.v1"

    private let defaults: UserDefaults

    @Published private(set) var hasCompletedGuide: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedGuide = defaults.bool(forKey: Self.completedKey)
    }

    func markCompleted() {
        defaults.set(true, forKey: Self.completedKey)
        hasCompletedGuide = true
    }

    /// Test / debug only — clears completion so launch presents the guide again.
    func resetCompletionForTesting() {
        defaults.removeObject(forKey: Self.completedKey)
        hasCompletedGuide = false
    }
}

/// Presents the guide on first launch and supports Settings replay.
@MainActor
final class FirstLaunchGuidePresenter: ObservableObject {
    @Published var isPresented = false

    private let store: FirstLaunchGuideStore

    init(store: FirstLaunchGuideStore = .shared) {
        self.store = store
    }

    var hasCompletedGuide: Bool { store.hasCompletedGuide }

    func presentIfNeededOnLaunch() {
        guard !store.hasCompletedGuide else { return }
        isPresented = true
    }

    func presentReplay() {
        isPresented = true
    }

    func dismissFinished() {
        store.markCompleted()
        isPresented = false
    }
}
