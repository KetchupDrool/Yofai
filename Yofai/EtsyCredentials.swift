import Foundation

/// Tokens and related connection metadata. Persist via Keychain only — never SwiftData, UserDefaults, logs, or docs.
struct EtsyCredentials: Equatable, Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date?
    /// Non-secret display label for Settings (shop name if known).
    var shopDisplayName: String?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }
}

protocol EtsyCredentialStoring: AnyObject {
    func load() throws -> EtsyCredentials?
    func save(_ credentials: EtsyCredentials) throws
    func deleteAll() throws
}
