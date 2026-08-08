import SwiftUI

enum AppStoreLinks {
    static let support = URL(string: "https://ketchupdrool.github.io/Yofai/support.html")!
    static let privacyPolicy = URL(string: "https://ketchupdrool.github.io/Yofai/privacy-policy.html")!
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
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
                    Text("Yofai is local-only. Photos stay on your device. No account, no backend, no ads, and no tracking in this version. Save Listing Copy writes a framed export to Photos only when you choose. Deleting History or Originals removes app files only.")
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

#Preview {
    SettingsView()
}
