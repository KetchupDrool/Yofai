import SwiftUI

enum AppStoreLinks {
    /// Replace before App Store submission.
    static let support = URL(string: "https://example.com/yofai/support")!
    /// Replace before App Store submission.
    static let privacyPolicy = URL(string: "https://example.com/yofai/privacy")!
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("App", value: "Yofai")
                    LabeledContent("Version", value: appVersion)
                }

                Section("Privacy") {
                    Text("Yofai is local-only. Photos stay on your device. No account, no backend, no ads, and no tracking in this version. Save Copy writes to Photos only when you choose.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Links") {
                    Link("Support", destination: AppStoreLinks.support)
                    Link("Privacy Policy", destination: AppStoreLinks.privacyPolicy)
                    Text("Replace placeholder URLs before App Store upload.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
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
