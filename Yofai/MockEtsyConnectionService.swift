import Foundation

/// In-memory credential store for unit tests and SwiftUI previews.
final class InMemoryEtsyCredentialStore: EtsyCredentialStoring {
    private var credentials: EtsyCredentials?

    init(credentials: EtsyCredentials? = nil) {
        self.credentials = credentials
    }

    func load() throws -> EtsyCredentials? {
        credentials
    }

    func save(_ credentials: EtsyCredentials) throws {
        self.credentials = credentials
    }

    func deleteAll() throws {
        credentials = nil
    }
}

/// Controllable mock for automated tests and previews. Performs no network I/O.
@MainActor
final class MockEtsyConnectionService: ObservableObject, EtsyConnecting {
    enum ConnectBehavior: Equatable {
        case succeed(shopDisplayName: String)
        case cancel
        case fail(message: String)
        case expireAfterConnect(shopDisplayName: String)
    }

    @Published private(set) var state: EtsyConnectionState = .notConnected

    private let store: EtsyCredentialStoring
    var connectBehavior: ConnectBehavior
    /// Artificial delay so UI can show Connecting during tests if needed.
    var connectDelayNanoseconds: UInt64

    init(
        store: EtsyCredentialStoring = InMemoryEtsyCredentialStore(),
        connectBehavior: ConnectBehavior = .succeed(shopDisplayName: "Mock Shop"),
        connectDelayNanoseconds: UInt64 = 0
    ) {
        self.store = store
        self.connectBehavior = connectBehavior
        self.connectDelayNanoseconds = connectDelayNanoseconds
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
        if connectDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: connectDelayNanoseconds)
        }

        switch connectBehavior {
        case .succeed(let shopDisplayName):
            let credentials = EtsyCredentials(
                accessToken: "mock-access-token",
                refreshToken: "mock-refresh-token",
                expiresAt: Date().addingTimeInterval(3600),
                shopDisplayName: shopDisplayName
            )
            do {
                try store.save(credentials)
                state = .connected(shopDisplayName: shopDisplayName)
            } catch {
                state = .error(message: "Could not save connection.")
            }

        case .cancel:
            // Aborted auth — restore whatever is already stored (usually not connected).
            refreshStatus()

        case .fail(let message):
            state = .error(message: message)

        case .expireAfterConnect(let shopDisplayName):
            let credentials = EtsyCredentials(
                accessToken: "mock-access-token",
                refreshToken: "mock-refresh-token",
                expiresAt: Date().addingTimeInterval(-60),
                shopDisplayName: shopDisplayName
            )
            do {
                try store.save(credentials)
                state = .connectionExpired
            } catch {
                state = .error(message: "Could not save connection.")
            }
        }
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
