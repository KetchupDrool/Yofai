import SwiftUI

struct EtsyShopSettingsSection: View {
    @ObservedObject var connection: StubEtsyConnectionService
    @State private var showDisconnectConfirm = false

    var body: some View {
        Section {
            statusRow

            if let detail = connection.state.detailMessage {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(detailColor(for: connection.state))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(EtsyOAuthConfig.incompleteConfigurationMessage)
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            actions
        } header: {
            Text("Etsy Shop")
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Tokens are stored in Keychain only when a connection exists. No live Etsy requests in this build. Local projects and listing drafts are unchanged.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
    }

    private var statusRow: some View {
        HStack {
            Text("Status")
                .foregroundStyle(DarkroomTheme.textPrimary)
            Spacer()
            Text(connection.state.statusLabel)
                .foregroundStyle(statusColor)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Etsy status \(connection.state.statusLabel)")
    }

    @ViewBuilder
    private var actions: some View {
        switch connection.state {
        case .connecting:
            ProgressView("Connecting…")
                .tint(DarkroomTheme.accent)

        case .connected, .connectionExpired:
            Button("Disconnect", role: .destructive) {
                showDisconnectConfirm = true
            }
            .confirmationDialog(
                "Disconnect Etsy shop?",
                isPresented: $showDisconnectConfirm,
                titleVisibility: .visible
            ) {
                Button("Disconnect", role: .destructive) {
                    Task { await connection.disconnect() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes locally stored Etsy credentials from Keychain. Projects, drafts, photos, History, and Originals stay on this device.")
            }

            if case .connectionExpired = connection.state {
                Button("Connect Etsy Shop") {
                    Task { await connection.connect() }
                }
                .foregroundStyle(DarkroomTheme.accent)
            }

        case .notConnected, .error:
            Button("Connect Etsy Shop") {
                Task { await connection.connect() }
            }
            .foregroundStyle(DarkroomTheme.accent)

            if case .error = connection.state {
                Button("Disconnect", role: .destructive) {
                    Task { await connection.disconnect() }
                }
            }
        }
    }

    private var statusColor: Color {
        switch connection.state {
        case .connected:
            return DarkroomTheme.accent
        case .connecting:
            return DarkroomTheme.textSecondary
        case .connectionExpired, .error:
            return DarkroomTheme.danger
        case .notConnected:
            return DarkroomTheme.textSecondary
        }
    }

    private func detailColor(for state: EtsyConnectionState) -> Color {
        if case .error = state {
            return DarkroomTheme.danger
        }
        return DarkroomTheme.textSecondary
    }
}

/// Preview / test harness section that drives any `EtsyConnecting` mock.
struct EtsyShopConnectionPreviewSection: View {
    @ObservedObject var connection: MockEtsyConnectionService

    var body: some View {
        Section {
            Text(connection.state.statusLabel)
                .foregroundStyle(DarkroomTheme.textPrimary)
            if let detail = connection.state.detailMessage {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
            }
            Button("Connect Etsy Shop") {
                Task { await connection.connect() }
            }
            Button("Disconnect", role: .destructive) {
                Task { await connection.disconnect() }
            }
        } header: {
            Text("Etsy Shop (Mock)")
        }
    }
}
