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
    case crop
    case fitModes
    case reposition
    case exportSize
    case marketplaceTarget
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
        case .crop: return "crop"
        case .fitModes: return "rectangle.dashed"
        case .reposition: return "arrow.up.and.down.and.arrow.left.and.right"
        case .exportSize: return "aspectratio"
        case .marketplaceTarget: return "storefront"
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
        case .crop: return FirstLaunchGuideCopy.cropTitle
        case .fitModes: return FirstLaunchGuideCopy.fitModesTitle
        case .reposition: return FirstLaunchGuideCopy.repositionTitle
        case .exportSize: return FirstLaunchGuideCopy.exportSizeTitle
        case .marketplaceTarget: return FirstLaunchGuideCopy.marketplaceTargetTitle
        case .exportLocal: return FirstLaunchGuideCopy.exportLocalTitle
        case .exportHistory: return FirstLaunchGuideCopy.exportHistoryTitle
        case .yofaiPro: return FirstLaunchGuideCopy.yofaiProTitle
        }
    }

    var bullets: [String] {
        switch self {
        case .welcome: return FirstLaunchGuideCopy.welcomeBullets
        case .startProduct: return FirstLaunchGuideCopy.startProductBullets
        case .addPhotos: return FirstLaunchGuideCopy.addPhotosBullets
        case .photoCheck: return FirstLaunchGuideCopy.photoCheckBullets
        case .crop: return FirstLaunchGuideCopy.cropBullets
        case .fitModes: return FirstLaunchGuideCopy.fitModesBullets
        case .reposition: return FirstLaunchGuideCopy.repositionBullets
        case .exportSize: return FirstLaunchGuideCopy.exportSizeBullets
        case .marketplaceTarget: return FirstLaunchGuideCopy.marketplaceTargetBullets
        case .exportLocal: return FirstLaunchGuideCopy.exportLocalBullets
        case .exportHistory: return FirstLaunchGuideCopy.exportHistoryBullets
        case .yofaiPro: return FirstLaunchGuideCopy.yofaiProBullets
        }
    }

    /// Combined body for VoiceOver / legacy tests.
    var bodyText: String {
        bullets.joined(separator: " ")
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
    static let welcomeBullets = [
        "Marketplace product photo prep on your iPhone.",
        "Export local JPEGs for manual upload."
    ]
    static let startProductTitle = "Start with a Product"
    static let startProductBullets = [
        "Keep photos and listing info together.",
        "Prepare one item at a time."
    ]
    static let addPhotosTitle = "Add Photos"
    static let addPhotosBullets = [
        "Add product photos from camera or library.",
        "Keep the best photos for export."
    ]
    static let photoCheckTitle = "Check Your Photos"
    static let photoCheckBullets = [
        "Photo Check flags basic photo issues.",
        "Review size, fit, and export notes before saving JPEGs."
    ]
    static let cropTitle = "Crop and Focus"
    static let cropBullets = [
        "Crop trims the photo around the product.",
        "Use it when the product needs better framing."
    ]
    static let fitModesTitle = "Fit Your Photo"
    static let fitModesBullets = [
        "Contain + Pad keeps the whole photo visible.",
        "Fill + Crop fills the square and may trim edges."
    ]
    static let repositionTitle = "Reposition the Crop"
    static let repositionBullets = [
        "Move the photo inside Fill + Crop.",
        "Keep the product centered before export."
    ]
    static let exportSizeTitle = "Pick Export Size"
    static let exportSizeBullets = [
        "Choose the local JPEG size you want.",
        "Use verified presets where available."
    ]
    static let marketplaceTargetTitle = "Choose Marketplace Target"
    static let marketplaceTargetBullets = [
        "Label exports for Etsy, eBay, Poshmark, and more.",
        "This does not upload or publish anything."
    ]
    static let exportLocalTitle = "Export JPEGs"
    static let exportLocalBullets = [
        "Save local JPEGs for manual upload.",
        "Nothing is sent to a marketplace."
    ]
    static let exportHistoryTitle = "Use Export History"
    static let exportHistoryBullets = [
        "View and re-share previous local exports.",
        "Reuse prepared files later."
    ]
    static let yofaiProTitle = "Yofai Pro"
    static let yofaiProBullets = [
        "Free keeps the core local export workflow.",
        "Pro is optional and adds unlimited products and marketplace tools."
    ]

    // Legacy aliases used by older call sites / Settings replay copy.
    static var welcomeBody: String { welcomeBullets.joined(separator: " ") }
    static var startProductBody: String { startProductBullets.joined(separator: " ") }
    static var addPhotosBody: String { addPhotosBullets.joined(separator: " ") }
    static var photoCheckBody: String { photoCheckBullets.joined(separator: " ") }
    static var editFitBody: String { fitModesBullets.joined(separator: " ") }
    static var exportLocalBody: String { exportLocalBullets.joined(separator: " ") }
    static var exportHistoryBody: String { exportHistoryBullets.joined(separator: " ") }
    static var yofaiProBody: String { yofaiProBullets.joined(separator: " ") }

    static let skip = "Skip"
    static let getStarted = "Get Started"
    static let continueTitle = "Continue"
    static let done = "Done"
    static let replayFromSettingsTitle = "Replay Welcome Guide"
    static let replayFromSettingsDetail = "Show the first-launch welcome and walkthrough again."
    static let pageIndicatorAccessibilityFormat = "Step %d of %d"

    static var allUserFacingStrings: [String] {
        FirstLaunchGuidePage.allCases.flatMap { page in
            [page.title] + page.bullets
        } + [
            skip, getStarted, continueTitle, done,
            replayFromSettingsTitle, replayFromSettingsDetail
        ]
    }

    static let bannedWalkthroughFragments: [String] = [
        "upload directly",
        "publish to marketplace",
        "post automatically",
        "connect marketplace account",
        "marketplace automation",
        "ready to publish",
        "direct upload"
    ]
}

/// Motion timings for the first-launch guide. Phase 68: slower so copy can be read.
/// No video; Reduce Motion → nil / instant.
enum FirstLaunchGuideMotion {
    static let welcomeDuration: TimeInterval = 0.90
    static let pageDuration: TimeInterval = 0.55
    static let stepContentDuration: TimeInterval = 0.70
    static let chromeDuration: TimeInterval = 0.65
    /// One-frame delay so hide → show actually animates (same-runloop toggles are invisible).
    static let frameDelayNanoseconds: UInt64 = 16_000_000

    /// Staged demo beats (enter → act → settle). Slower premium pacing.
    static let sceneEnterDelayNanoseconds: UInt64 = 80_000_000
    static let sceneActDelayNanoseconds: UInt64 = 750_000_000
    static let sceneSettleDelayNanoseconds: UInt64 = 900_000_000
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
        reduceMotion ? nil : .spring(response: 0.65, dampingFraction: 0.84)
    }

    static func sceneActAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.58, dampingFraction: 0.80)
    }

    static func sceneSettleAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.45)
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
    case crop
    case fitModes
    case reposition
    case exportSize
    case marketplaceTarget
    case exportLocal
    case exportHistory
    case yofaiPro

    static func kind(for page: FirstLaunchGuidePage) -> FirstLaunchGuideSceneKind {
        switch page {
        case .welcome: return .welcomeBrand
        case .startProduct: return .startProduct
        case .addPhotos: return .addPhotos
        case .photoCheck: return .photoCheck
        case .crop: return .crop
        case .fitModes: return .fitModes
        case .reposition: return .reposition
        case .exportSize: return .exportSize
        case .marketplaceTarget: return .marketplaceTarget
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
