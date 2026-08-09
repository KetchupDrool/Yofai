import SwiftUI

struct SellerDefaultsSettingsSection: View {
    @State private var defaults = SellerDefaults()
    @State private var showClearConfirm = false
    @State private var statusMessage: String?

    private let store = SellerDefaultsStore()

    var body: some View {
        Section {
            TextField("Category", text: $defaults.category)
            TextField("Materials", text: $defaults.materials)
            TextField("Shipping profile", text: $defaults.shippingProfile)
            TextField("Processing time", text: $defaults.processingTime)

            Picker("Export preset", selection: Binding(
                get: { defaults.exportPreset },
                set: { defaults.exportPreset = $0 }
            )) {
                ForEach(ListingExportPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }

            Picker("Export background", selection: Binding(
                get: { defaults.exportBackground },
                set: { defaults.exportBackground = $0 }
            )) {
                ForEach(ListingExportBackground.allCases) { background in
                    Text(background.rawValue).tag(background)
                }
            }

            TextField("Watermark text", text: Binding(
                get: { defaults.watermarkText },
                set: { defaults.watermarkText = String($0.prefix(PhotoEditState.watermarkMaxLength)) }
            ))

            Button("Save Seller Defaults") {
                store.save(defaults)
                statusMessage = "Defaults saved on this device."
            }
            .foregroundStyle(DarkroomTheme.accent)

            Button("Clear All Defaults", role: .destructive) {
                showClearConfirm = true
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
            }
        } header: {
            Text("Seller Defaults")
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Applied only when creating a new Item Project with Use Seller Defaults. Existing projects are never overwritten. No Etsy credentials are stored here.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .onAppear {
            defaults = store.load()
        }
        .confirmationDialog(
            "Clear all seller defaults?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear All Defaults", role: .destructive) {
                store.clear()
                defaults = SellerDefaults()
                statusMessage = "Defaults cleared."
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes only saved Seller Defaults on this device. Projects, drafts, photos, and Etsy connection stay unchanged.")
        }
    }
}
