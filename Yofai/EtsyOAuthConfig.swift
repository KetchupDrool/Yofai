import Foundation

/// OAuth configuration placeholders for Phase 24.
/// Incomplete development configuration — do not treat as production-ready.
enum EtsyOAuthConfig {
    /// Development placeholder redirect URI. Must match a future Etsy app registration before live OAuth.
    static let redirectURIString = "yofai://etsy-oauth-callback"

    static var redirectURI: URL {
        URL(string: redirectURIString)!
    }

    /// Always false until backend + Etsy developer app + approved redirect are in place.
    static let isConfigurationComplete = false

    static let incompleteConfigurationMessage =
        "Live Etsy OAuth is not enabled. Connection is not available in this version."
}
