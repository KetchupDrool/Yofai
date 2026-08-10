import SwiftUI

enum AppStoreLinks {
    static let support = URL(string: "https://ketchupdrool.github.io/Yofai/support.html")!
    static let privacyPolicy = URL(string: "https://ketchupdrool.github.io/Yofai/privacy-policy.html")!
    /// Apple Standard EULA — required Terms of Use for auto-renewable subscriptions.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

struct SettingsView: View {
    @EnvironmentObject private var firstLaunchGuide: FirstLaunchGuidePresenter
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
                    Button {
                        firstLaunchGuide.presentReplay()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(FirstLaunchGuideCopy.replayFromSettingsTitle)
                                .foregroundStyle(DarkroomTheme.textPrimary)
                            Text(FirstLaunchGuideCopy.replayFromSettingsDetail)
                                .font(.footnote)
                                .foregroundStyle(DarkroomTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityLabel(FirstLaunchGuideCopy.replayFromSettingsTitle)
                    .accessibilityHint(FirstLaunchGuideCopy.replayFromSettingsDetail)
                } header: {
                    Text("Help")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
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
                    Text("Yofai keeps product photos, edits, listing drafts, export history, and notes on this device. Local JPEG export is for manual marketplace upload. No ads, no tracking SDKs, no account, no backend, and no marketplace upload in this version. Camera is used to capture product photos. Photos permission is used when you choose photos or save a listing copy. Live Etsy OAuth is not enabled. Yofai Pro is an optional Apple subscription; Free keeps the core local export workflow.")
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(AppStoreLaunchSupport.privacySummary)
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
                    Link("Terms of Use", destination: AppStoreLinks.termsOfUse)
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
        .environmentObject(FirstLaunchGuidePresenter(store: FirstLaunchGuideStore()))
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
