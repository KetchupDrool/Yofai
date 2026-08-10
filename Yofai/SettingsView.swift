import SwiftUI

enum AppStoreLinks {
    static let support = URL(string: "https://ketchupdrool.github.io/Yofai/support.html")!
    static let privacyPolicy = URL(string: "https://ketchupdrool.github.io/Yofai/privacy-policy.html")!
}

struct SettingsView: View {
    @StateObject private var etsyConnection = StubEtsyConnectionService()

    var body: some View {
        NavigationStack {
            List {
                YofaiProSettingsSection()
                    .listRowBackground(settingsRowBackground)

                EtsyShopSettingsSection(connection: etsyConnection)
                    .listRowBackground(settingsRowBackground)

                SellerDefaultsSettingsSection()
                    .listRowBackground(settingsRowBackground)

                Section {
                    LabeledContent("App", value: "Yofai")
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
                .listRowBackground(settingsRowBackground)

                Section {
                    Text("Yofai keeps photos and listing drafts on your device. No ads or tracking in this version. Save Listing Copy writes a framed export to Photos only when you choose. An optional Etsy Shop connection stores tokens in Keychain only; live Etsy OAuth is not enabled yet. Deleting History, Originals, or Projects removes app files only.")
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("Privacy")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
                .listRowBackground(settingsRowBackground)

                Section {
                    Link("Support", destination: AppStoreLinks.support)
                    Link("Privacy Policy", destination: AppStoreLinks.privacyPolicy)
                } header: {
                    Text("Links")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
                .listRowBackground(settingsRowBackground)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .tint(DarkroomTheme.accent)
            .darkroomScreen()
            .navigationTitle("Settings")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                etsyConnection.refreshStatus()
            }
        }
    }

    private var settingsRowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(0.45)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DarkroomTheme.surface)
            )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview("Settings") {
    SettingsView()
}

#Preview("Etsy Mock Connected") {
    PreviewEtsyMockConnected()
}

private struct PreviewEtsyMockConnected: View {
    @StateObject private var mock = MockEtsyConnectionService(
        connectBehavior: .succeed(shopDisplayName: "Preview Shop")
    )

    var body: some View {
        List {
            EtsyShopConnectionPreviewSection(connection: mock)
        }
        .task {
            await mock.connect()
        }
    }
}
