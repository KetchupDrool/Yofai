import Foundation

/// Non-networking stub used by the shipping app until live OAuth is approved and configured.
/// Never contacts Etsy. Does not embed a client secret.
@MainActor
final class StubEtsyConnectionService: ObservableObject, EtsyConnecting {
    @Published private(set) var state: EtsyConnectionState = .notConnected

    private let store: EtsyCredentialStoring

    init(store: EtsyCredentialStoring = KeychainEtsyCredentialStore()) {
        self.store = store
        refreshStatus()
    }

    func refreshStatus() {
        do {
            guard let credentials = try store.load() else {
                state = .notConnected
                return
            }
            if credentials.isExpired {
                state = .connectionExpired
            } else {
                state = .connected(shopDisplayName: credentials.shopDisplayName)
            }
        } catch {
            state = .error(message: "Could not read saved connection.")
        }
    }

    func connect() async {
        state = .connecting
        // Yield so UI can observe Connecting before the stub result.
        await Task.yield()

        guard EtsyOAuthConfig.isConfigurationComplete else {
            state = .error(message: EtsyOAuthConfig.incompleteConfigurationMessage)
            return
        }

        // Live OAuth path is intentionally not implemented in Phase 24.
        state = .error(message: "Live Etsy OAuth is not enabled in this build.")
    }

    func disconnect() async {
        do {
            try store.deleteAll()
            state = .notConnected
        } catch {
            state = .error(message: "Could not clear saved connection.")
        }
    }
}
