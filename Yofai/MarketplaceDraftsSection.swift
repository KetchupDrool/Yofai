import SwiftUI
import SwiftData

/// Phase 61 — product-level marketplace drafts list. Free primary + Pro additional drafts.
struct MarketplaceDraftsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ItemProject

    @State private var createError: String?
    @State private var showCreatePicker = false

    private var entitlementState: EntitlementState {
        EntitlementStore.shared.state
    }

    private var canManageAdditional: Bool {
        MarketplaceListingDraftSupport.canManageAdditionalDrafts(state: entitlementState)
    }

    private var additionalDrafts: [MarketplaceListingDraft] {
        MarketplaceListingDraftSupport.sortedDrafts(on: project)
    }

    private var availableTargets: [MarketplaceTarget] {
        MarketplaceListingDraftSupport.availableTargetsForNewDraft(on: project)
    }

    var body: some View {
        Section {
            Text(MarketplaceListingDraftCopy.preparePackagesLine)
                .font(.footnote)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(MarketplaceListingDraftCopy.preparePackagesLine)

            NavigationLink {
                ListingWorkspaceView(project: project)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(MarketplaceListingDraftCopy.primaryDraftTitle)
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Text(MarketplaceListingDraftCopy.primaryDraftDetail)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !project.trimmedListingTitle.isEmpty {
                        Text(project.trimmedListingTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                    Text(project.listingMarketplaceTarget.displayTitle)
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
            }
            .accessibilityLabel("\(MarketplaceListingDraftCopy.primaryDraftTitle). \(project.listingMarketplaceTarget.displayTitle)")

            if canManageAdditional {
                ForEach(additionalDrafts, id: \.stableID) { draft in
                    NavigationLink {
                        MarketplaceListingDraftEditorView(draft: draft)
                    } label: {
                        draftRow(draft)
                    }
                    .accessibilityLabel("\(draft.displayTitle). \(draft.listingTitleOrPlaceholder)")
                }

                if availableTargets.isEmpty {
                    Text("All marketplace targets already have a draft on this product.")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } else {
                    Button {
                        showCreatePicker = true
                    } label: {
                        Label(MarketplaceListingDraftCopy.createDraftTitle, systemImage: "plus.circle.fill")
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                    .accessibilityLabel(MarketplaceListingDraftCopy.createDraftTitle)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(MarketplaceListingDraftCopy.proLockedTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Text(MarketplaceListingDraftCopy.proLockedDetail)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    NavigationLink {
                        YofaiProPaywallView()
                    } label: {
                        Text("View \(FreemiumCopy.proTitle)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                    .accessibilityLabel("View \(FreemiumCopy.proTitle)")
                }
                .accessibilityElement(children: .combine)
            }

            Text(MarketplaceListingDraftCopy.manualPackageReminder)
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Text(MarketplaceListingDraftCopy.sectionTitle)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            if let createError {
                Text(createError)
                    .foregroundStyle(DarkroomTheme.danger)
            }
        }
        .confirmationDialog(
            MarketplaceListingDraftCopy.createDraftTitle,
            isPresented: $showCreatePicker,
            titleVisibility: .visible
        ) {
            ForEach(availableTargets) { target in
                Button(target.displayTitle) {
                    createDraft(for: target)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(MarketplaceListingDraftCopy.manualPackageReminder)
        }
    }

    private func draftRow(_ draft: MarketplaceListingDraft) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(draft.displayTitle)
                .foregroundStyle(DarkroomTheme.textPrimary)
            Text(draft.listingTitleOrPlaceholder)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
            Text(draft.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
    }

    private func createDraft(for target: MarketplaceTarget) {
        createError = nil
        do {
            _ = try MarketplaceListingDraftSupport.createDraft(
                for: target,
                on: project,
                in: modelContext,
                state: entitlementState
            )
            try? modelContext.save()
        } catch MarketplaceListingDraftError.proRequired {
            createError = MarketplaceListingDraftCopy.proLockedDetail
        } catch MarketplaceListingDraftError.duplicateMarketplace {
            createError = MarketplaceListingDraftCopy.duplicateTargetMessage
        } catch {
            createError = "Could not create draft."
        }
    }
}

/// Basic editor for a Pro marketplace draft (local fields only).
struct MarketplaceListingDraftEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var draft: MarketplaceListingDraft
    @State private var saveMessage: String?

    var body: some View {
        Form {
            Section {
                Text(draft.marketplaceTarget.displayTitle)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                TextField("Draft label", text: $draft.draftLabel)
                TextField("Title", text: $draft.title)
                TextField("Description", text: $draft.draftDescription, axis: .vertical)
                    .lineLimit(3...8)
                TextField("Price", text: $draft.priceText)
                    .keyboardType(.decimalPad)
                Stepper(value: $draft.quantity, in: 1...999) {
                    Text("Quantity: \(draft.quantity)")
                }
                TextField("Category", text: $draft.category)
                TextField("Condition", text: $draft.condition)
                TextField("Materials", text: $draft.materials)
                TextField("Shipping notes", text: $draft.shippingNotes)
                TextField("Processing time", text: $draft.processingTime)
                TextField("Returns policy", text: $draft.returnsPolicy)
                TextField("Personalization notes", text: $draft.personalizationNotes, axis: .vertical)
                    .lineLimit(2...5)
                TextField("Marketplace seller notes", text: $draft.marketplaceSellerNotes, axis: .vertical)
                    .lineLimit(2...5)
            } header: {
                Text("Listing fields")
            } footer: {
                Text(MarketplaceListingDraftCopy.manualPackageReminder)
            }

            Section("Local export settings") {
                Picker("Export size", selection: Binding(
                    get: { draft.exportPreset },
                    set: { draft.exportPreset = $0 }
                )) {
                    ForEach(ListingExportPreset.allCases) { preset in
                        Text(preset.displayTitle).tag(preset)
                    }
                }
                Picker("Fit", selection: Binding(
                    get: { draft.exportFitMode },
                    set: { draft.exportFitMode = $0 }
                )) {
                    ForEach(ListingExportFitMode.allCases) { mode in
                        Text(mode.displayTitle).tag(mode)
                    }
                }
                Picker("Background", selection: Binding(
                    get: { draft.exportBackground },
                    set: { draft.exportBackground = $0 }
                )) {
                    ForEach(ListingExportBackground.allCases) { background in
                        Text(background.rawValue).tag(background)
                    }
                }
                Toggle("Watermark", isOn: $draft.watermarkEnabled)
                if draft.watermarkEnabled {
                    TextField("Watermark text", text: $draft.watermarkText)
                }
                Text(draft.marketplaceTarget.canvasGuidance)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Button(MarketplaceListingDraftCopy.draftSaved) {
                    draft.touchUpdated()
                    draft.project?.touchModified()
                    try? modelContext.save()
                    saveMessage = MarketplaceListingDraftCopy.draftSaved
                }
                if let saveMessage {
                    Text(saveMessage)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.success)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .darkroomScreen()
        .navigationTitle(draft.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: draft.title) { _, _ in draft.touchUpdated() }
        .onChange(of: draft.draftDescription) { _, _ in draft.touchUpdated() }
        .onChange(of: draft.priceText) { _, _ in draft.touchUpdated() }
    }
}
