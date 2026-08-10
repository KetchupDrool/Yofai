import XCTest
import SwiftData
@testable import Yofai

@MainActor
final class Phase24EtsyConnectionTests: XCTestCase {
    func testConnectionStateLabelsCoverAllCases() {
        XCTAssertEqual(EtsyConnectionState.notConnected.statusLabel, "Not connected")
        XCTAssertEqual(EtsyConnectionState.connecting.statusLabel, "Connecting")
        XCTAssertEqual(EtsyConnectionState.connected(shopDisplayName: "Lamp Co").statusLabel, "Connected · Lamp Co")
        XCTAssertEqual(EtsyConnectionState.connected(shopDisplayName: nil).statusLabel, "Connected")
        XCTAssertEqual(EtsyConnectionState.connectionExpired.statusLabel, "Connection expired")
        XCTAssertEqual(EtsyConnectionState.error(message: "Nope").statusLabel, "Error")
        XCTAssertEqual(EtsyConnectionState.error(message: "Nope").detailMessage, "Nope")
    }

    func testOAuthConfigUsesIncompletePlaceholderRedirect() {
        XCTAssertEqual(EtsyOAuthConfig.redirectURIString, "yofai://etsy-oauth-callback")
        XCTAssertEqual(EtsyOAuthConfig.redirectURI.absoluteString, "yofai://etsy-oauth-callback")
        XCTAssertFalse(EtsyOAuthConfig.isConfigurationComplete)
        XCTAssertTrue(EtsyOAuthConfig.incompleteConfigurationMessage.lowercased().contains("not enabled"))
        XCTAssertTrue(AppStoreLaunchSupport.etsyConnectionUnavailableTitle.lowercased().contains("not available"))
    }

    func testMockSuccessfulConnectionReachesConnected() async throws {
        let store = InMemoryEtsyCredentialStore()
        let service = MockEtsyConnectionService(
            store: store,
            connectBehavior: .succeed(shopDisplayName: "Mock Shop")
        )
        XCTAssertEqual(service.state, .notConnected)

        await service.connect()

        XCTAssertEqual(service.state, .connected(shopDisplayName: "Mock Shop"))
        let saved = try store.load()
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.shopDisplayName, "Mock Shop")
        // Do not assert token string values in logs; presence only.
        XCTAssertFalse(saved?.accessToken.isEmpty ?? true)
    }

    func testMockCancellationReturnsToNotConnected() async throws {
        let store = InMemoryEtsyCredentialStore()
        let service = MockEtsyConnectionService(store: store, connectBehavior: .cancel)
        await service.connect()
        XCTAssertEqual(service.state, .notConnected)
        XCTAssertNil(try store.load())
    }

    func testMockCancellationDoesNotWriteCredentials() async throws {
        let store = InMemoryEtsyCredentialStore()
        let service = MockEtsyConnectionService(store: store, connectBehavior: .cancel)
        await service.connect()
        XCTAssertEqual(service.state, .notConnected)
        XCTAssertNil(try store.load())
    }

    func testMockErrorDisplaysSafelyWithoutCrashing() async {
        let service = MockEtsyConnectionService(
            connectBehavior: .fail(message: "Authorization was denied.")
        )
        await service.connect()
        XCTAssertEqual(service.state, .error(message: "Authorization was denied."))
        XCTAssertEqual(service.state.statusLabel, "Error")
        XCTAssertEqual(service.state.detailMessage, "Authorization was denied.")
    }

    func testDisconnectDeletesKeychainCredentials() throws {
        let serviceName = "com.shawnwright.yofai.etsy.credentials.test.\(UUID().uuidString)"
        let store = KeychainEtsyCredentialStore(service: serviceName, account: "phase24-test")
        let credentials = EtsyCredentials(
            accessToken: "temporary-test-token",
            refreshToken: "temporary-refresh",
            expiresAt: Date().addingTimeInterval(600),
            shopDisplayName: "Keychain Shop"
        )
        try store.save(credentials)
        XCTAssertNotNil(try store.load())

        try store.deleteAll()
        XCTAssertNil(try store.load())
    }

    func testMockDisconnectClearsStoreAndReturnsNotConnected() async throws {
        let store = InMemoryEtsyCredentialStore()
        let service = MockEtsyConnectionService(
            store: store,
            connectBehavior: .succeed(shopDisplayName: "Temp")
        )
        await service.connect()
        XCTAssertTrue(service.state.isConnected)

        await service.disconnect()
        XCTAssertEqual(service.state, .notConnected)
        XCTAssertNil(try store.load())
    }

    func testRelaunchRestoresConnectedStateFromStore() async throws {
        let store = InMemoryEtsyCredentialStore()
        let first = MockEtsyConnectionService(
            store: store,
            connectBehavior: .succeed(shopDisplayName: "Persisted Shop")
        )
        await first.connect()

        let relaunched = MockEtsyConnectionService(store: store)
        XCTAssertEqual(relaunched.state, .connected(shopDisplayName: "Persisted Shop"))
    }

    func testRelaunchRestoresExpiredStateFromStore() throws {
        let store = InMemoryEtsyCredentialStore(
            credentials: EtsyCredentials(
                accessToken: "expired-token",
                refreshToken: nil,
                expiresAt: Date().addingTimeInterval(-120),
                shopDisplayName: "Old Shop"
            )
        )
        let relaunched = MockEtsyConnectionService(store: store)
        XCTAssertEqual(relaunched.state, .connectionExpired)
    }

    func testStubConnectShowsIncompleteConfigurationError() async {
        let store = InMemoryEtsyCredentialStore()
        let stub = StubEtsyConnectionService(store: store)
        await stub.connect()
        guard case .error(let message) = stub.state else {
            return XCTFail("Expected error state")
        }
        XCTAssertTrue(message.lowercased().contains("not enabled"))
        XCTAssertNil(try? store.load())
    }

    func testListingDraftsStillPersistAlongsideConnectionFoundation() throws {
        let schema = YofaiModelSchema.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let project = ItemProject(name: "Phase24 Lamp")
        project.listingTitle = "Ceramic Lamp"
        project.listingPriceText = "42.00"
        project.listingQuantity = 1
        project.listingTags = ["ceramic", "lamp"]
        context.insert(project)
        try context.save()

        XCTAssertTrue(project.isListingDraftComplete)
        XCTAssertEqual(project.listingTitle, "Ceramic Lamp")
        XCTAssertEqual(project.listingTags.count, 2)
    }
}
