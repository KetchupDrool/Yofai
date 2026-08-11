import Foundation

/// Phase 35 — seller-first navigation helpers (no persistence / no migrations).
enum YofaiAppTab: Int, CaseIterable, Identifiable, Equatable {
    case home
    case products
    case originals
    case history
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .products: return "Products"
        case .originals: return "Originals"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .products: return "shippingbox"
        case .originals: return "photo.on.rectangle"
        case .history: return "clock"
        case .settings: return "gearshape"
        }
    }

    /// Primary seller path tabs vs secondary library tools.
    var isSellerPrimary: Bool {
        switch self {
        case .home, .products:
            return true
        case .originals, .history, .settings:
            return false
        }
    }

    static var defaultTab: YofaiAppTab { .home }
}

enum SellerNavigationSupport {
    static let recentProductLimit = 5

    static func recentProducts<T>(_ products: [T]) -> [T] {
        Array(products.prefix(recentProductLimit))
    }

    /// Labels for Home primary actions.
    static let startProductTitle = "Start Product"
    static let continueProductsSectionTitle = "Continue Product"
    static let secondaryToolsSectionTitle = "More Tools"
    static let quickImportTitle = "Import Single Photo"
    static let browseOriginalsTitle = "Browse Originals"
    static let browseHistoryTitle = "Browse History"

    static let productsListTitle = "Products"
    static let newProductAccessibilityLabel = "New Product"
    static let listingQueueAccessibilityLabel = "Listing Queue"

    static let projectIntakeLinkTitle = "Photos"
    static let projectWorkspaceLinkTitle = "Export JPEGs"

    static let homeWorkflowHint =
        "Primary path: Start or continue a product → photos → Photo Check → edit → Export JPEGs."
}
