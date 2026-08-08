import Foundation
import CoreGraphics
import UIKit

enum ListingExportPreset: String, CaseIterable, Identifiable, Equatable {
    case etsySquare = "Etsy square"
    case etsyListing = "Etsy listing"
    case instagramSquare = "Instagram square"
    case facebookPost = "Facebook post"
    case marketplace = "Marketplace"

    var id: String { rawValue }

    /// Locked pixel size (width × height).
    var pixelSize: CGSize {
        switch self {
        case .etsySquare: return CGSize(width: 2000, height: 2000)
        case .etsyListing: return CGSize(width: 3000, height: 2400)
        case .instagramSquare: return CGSize(width: 1080, height: 1080)
        case .facebookPost: return CGSize(width: 1200, height: 630)
        case .marketplace: return CGSize(width: 1600, height: 1600)
        }
    }

    var shortLabel: String {
        switch self {
        case .etsySquare: return "Etsy □"
        case .etsyListing: return "Etsy"
        case .instagramSquare: return "IG □"
        case .facebookPost: return "FB"
        case .marketplace: return "Market"
        }
    }
}

enum ListingExportBackground: String, CaseIterable, Identifiable, Equatable {
    case white = "White"
    case black = "Black"
    case softGray = "Soft gray"

    var id: String { rawValue }

    var uiColor: UIColor {
        switch self {
        case .white: return .white
        case .black: return .black
        case .softGray: return UIColor(red: 0.90, green: 0.90, blue: 0.91, alpha: 1)
        }
    }
}
