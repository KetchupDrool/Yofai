import Foundation
import Security

/// Keychain-backed credential store. Does not log token values.
final class KeychainEtsyCredentialStore: EtsyCredentialStoring {
    private let service: String
    private let account: String

    init(
        service: String = "com.shawnwright.yofai.etsy.credentials",
        account: String = "etsy-seller"
    ) {
        self.service = service
        self.account = account
    }

    func load() throws -> EtsyCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw EtsyCredentialStoreError.keychainFailure(status)
        }
        guard let data = item as? Data else {
            throw EtsyCredentialStoreError.invalidData
        }
        do {
            return try JSONDecoder().decode(EtsyCredentials.self, from: data)
        } catch {
            throw EtsyCredentialStoreError.invalidData
        }
    }

    func save(_ credentials: EtsyCredentials) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(credentials)
        } catch {
            throw EtsyCredentialStoreError.invalidData
        }

        try deleteAll()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EtsyCredentialStoreError.keychainFailure(status)
        }
    }

    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EtsyCredentialStoreError.keychainFailure(status)
        }
    }
}

enum EtsyCredentialStoreError: Error, Equatable {
    case keychainFailure(OSStatus)
    case invalidData
}
