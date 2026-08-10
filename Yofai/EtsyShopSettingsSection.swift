import SwiftUI

/// Phase 50 — Etsy shop stub is informational only. No live Connect button while OAuth is disabled.
struct EtsyShopSettingsSection: View {
    @ObservedObject var connection: StubEtsyConnectionService

    var body: some View {
        Section {
            HStack(alignment: .top) {
                Text("Status")
                    .foregroundStyle(DarkroomTheme.textPrimary)
                Spacer()
                Text(AppStoreLaunchSupport.etsyConnectionUnavailableTitle)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Etsy status. \(AppStoreLaunchSupport.etsyConnectionUnavailableTitle)")

            Text(AppStoreLaunchSupport.etsyConnectionUnavailableDetail)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(EtsyOAuthConfig.incompleteConfigurationMessage)
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            // Keep stub refreshed so status stays accurate, but do not offer Connect.
            Color.clear
                .frame(height: 0)
                .onAppear { connection.refreshStatus() }
                .accessibilityHidden(true)
        } header: {
            Text("Etsy Shop")
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Not a live marketplace connection. Local Export Mode only — prepare JPEGs here, upload manually in Etsy’s website or app. No marketplace passwords are stored.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
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
