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

            Picker("Item type", selection: Binding(
                get: { defaults.itemType },
                set: { defaults.itemType = $0 }
            )) {
                Text("None").tag(Optional<ListingItemType>.none)
                ForEach(ListingItemType.allCases) { type in
                    Text(type.rawValue).tag(Optional(type))
                }
            }
            TextField("Condition", text: $defaults.condition)
            TextField("Who made it", text: $defaults.whoMadeIt)
            TextField("When it was made", text: $defaults.whenMade)
            TextField("Return policy text", text: $defaults.returnPolicy, axis: .vertical)
                .lineLimit(2...5)

            Picker("Export preset", selection: Binding(
                get: { defaults.exportPreset },
                set: { defaults.exportPreset = $0 }
            )) {
                ForEach(ListingExportPresetGroup.allCases) { group in
                    Section(group.rawValue) {
                        ForEach(ListingExportPreset.presets(in: group)) { preset in
                            Text(preset.pickerLabel).tag(preset)
                        }
                    }
                }
            }

            Text(defaults.exportPreset.displaySubtitle)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)

            Text(ListingExportPreset.localExportDisclaimer)
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

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
