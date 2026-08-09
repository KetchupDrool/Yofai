import Foundation

/// Testable Etsy connection surface. Implementations must not log credentials.
@MainActor
protocol EtsyConnecting: AnyObject {
    var state: EtsyConnectionState { get }
    func refreshStatus()
    func connect() async
    func disconnect() async
}
