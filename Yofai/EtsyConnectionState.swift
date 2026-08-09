import Foundation

/// User-visible Etsy shop connection status (Phase 24 foundation).
enum EtsyConnectionState: Equatable {
    case notConnected
    case connecting
    case connected(shopDisplayName: String?)
    case connectionExpired
    case error(message: String)

    var statusLabel: String {
        switch self {
        case .notConnected:
            return "Not connected"
        case .connecting:
            return "Connecting"
        case .connected(let shopDisplayName):
            if let shopDisplayName, !shopDisplayName.isEmpty {
                return "Connected · \(shopDisplayName)"
            }
            return "Connected"
        case .connectionExpired:
            return "Connection expired"
        case .error:
            return "Error"
        }
    }

    var detailMessage: String? {
        switch self {
        case .error(let message):
            return message
        case .connectionExpired:
            return "Reconnect your shop when live OAuth is available."
        case .connecting:
            return "Waiting for authorization…"
        case .notConnected, .connected:
            return nil
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
