import SwiftUI
import SwiftData

/// Grouped local Listing Information editors for one Item Project.
/// Reuses Phase 23 core draft fields via Project Detail — does not duplicate them.
struct ListingInformationView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ItemProject

    @State private var saveMessage: String?
    @State private var saveIsError = false
    @State private var variations: [ListingVariation] = []
    @State private var attributes: [ListingCategoryAttribute] = []
    @State private var variationOptionsRaw: [UUID: String] = [:]

    var body: some View {
        List {
            coreFieldsSection
            itemDetailsSection
            personalizationSection
            variationsSection
            attributesSection
            returnPolicySection
            altTextSection
            reviewSection
            saveSection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .darkroomScreen()
        .navigationTitle("Listing Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            loadEditors()
        }
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(0.45)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DarkroomTheme.surface)
            )
    }

    private var coreFieldsSection: some View {
        Section {
            labeledValue("Title", project.trimmedListingTitle.isEmpty ? "—" : project.trimmedListingTitle)
            labeledValue("Price", project.listingPriceText.isEmpty ? "—" : project.listingPriceText)
            labeledValue("Quantity", "\(project.listingQuantity)")
            labeledValue("Category", project.listingCategory.isEmpty ? "—" : project.listingCategory)
            labeledValue("Tags", project.listingTags.isEmpty ? "—" : project.listingTagsRawText)
            labeledValue("Materials", project.listingMaterials.isEmpty ? "—" : project.listingMaterials)
            labeledValue("Shipping", project.listingShippingProfile.isEmpty ? "—" : project.listingShippingProfile)
            labeledValue("Processing", project.listingProcessingTime.isEmpty ? "—" : project.listingProcessingTime)

            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                Text("Edit Core Listing Details")
                    .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Core Listing Details")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Title, description, price, quantity, category, tags, materials, shipping, and processing time stay in Project Detail. Not duplicated here.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var itemDetailsSection: some View {
        Section {
            notApplicableToggle("Item type", isOn: $project.listingItemTypeNotApplicable)
            if !project.listingItemTypeNotApplicable {
                Picker("Item type", selection: Binding(
                    get: { project.listingItemType },
                    set: { project.listingItemType = $0 }
                )) {
                    Text("Select").tag(Optional<ListingItemType>.none)
                    ForEach(ListingItemType.allCases) { type in
                        Text(type.rawValue).tag(Optional(type))
                    }
                }
            }

            notApplicableToggle("Condition", isOn: $project.listingConditionNotApplicable)
            if !project.listingConditionNotApplicable {
                TextField("Condition", text: $project.listingCondition)
                    .foregroundStyle(DarkroomTheme.textPrimary)
            }

            notApplicableToggle("Who made it", isOn: $project.listingWhoMadeItNotApplicable)
            if !project.listingWhoMadeItNotApplicable {
                TextField("Who made it", text: $project.listingWhoMadeIt)
                    .foregroundStyle(DarkroomTheme.textPrimary)
            }

            notApplicableToggle("When it was made", isOn: $project.listingWhenMadeNotApplicable)
            if !project.listingWhenMadeNotApplicable {
                TextField("When it was made", text: $project.listingWhenMade)
                    .foregroundStyle(DarkroomTheme.textPrimary)
            }

            notApplicableToggle("SKU", isOn: $project.listingSKUNotApplicable)
            if !project.listingSKUNotApplicable {
                TextField("SKU", text: $project.listingSKU)
                    .foregroundStyle(DarkroomTheme.textPrimary)
            }
        } header: {
            Text("Item Details")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var personalizationSection: some View {
        Section {
            notApplicableToggle("Personalization", isOn: $project.listingPersonalizationNotApplicable)
            if !project.listingPersonalizationNotApplicable {
                Toggle("Enabled", isOn: $project.listingPersonalizationEnabled)
                if project.listingPersonalizationEnabled {
                    notApplicableToggle("Buyer instructions", isOn: $project.listingPersonalizationInstructionsNotApplicable)
                    if !project.listingPersonalizationInstructionsNotApplicable {
                        TextField("Buyer instructions", text: $project.listingPersonalizationInstructions, axis: .vertical)
                            .lineLimit(2...6)
                            .foregroundStyle(DarkroomTheme.textPrimary)
                    }
                    TextField("Character limit", text: $project.listingPersonalizationCharacterLimitText)
                        .keyboardType(.numberPad)
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Toggle("Required", isOn: $project.listingPersonalizationRequired)
                }
            }
        } header: {
            Text("Personalization")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("When enabled, character limit must be a positive whole number.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var variationsSection: some View {
        Section {
            notApplicableToggle("Variations", isOn: $project.listingVariationsNotApplicable)
            if !project.listingVariationsNotApplicable {
                ForEach(Array(variations.enumerated()), id: \.element.id) { index, _ in
                    variationEditor(index: index)
                }

                Button("Add Variation") {
                    let variation = ListingVariation()
                    variations.append(variation)
                    variationOptionsRaw[variation.id] = ""
                }
                .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Variations")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Enabled variations need a name, at least one option, and a SKU. Blank options are removed on save.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var attributesSection: some View {
        Section {
            notApplicableToggle("Category attributes", isOn: $project.listingAttributesNotApplicable)
            if !project.listingAttributesNotApplicable {
                ForEach(Array(attributes.enumerated()), id: \.element.id) { index, _ in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Attribute name", text: Binding(
                            get: { attributes[index].name },
                            set: { attributes[index].name = $0 }
                        ))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                        TextField("Selected value", text: Binding(
                            get: { attributes[index].value },
                            set: { attributes[index].value = $0 }
                        ))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                        Button("Remove Attribute", role: .destructive) {
                            attributes.remove(at: index)
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                }

                Button("Add Attribute") {
                    attributes.append(ListingCategoryAttribute())
                }
                .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Category Attributes")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local name/value pairs only. Blank names or values are removed on save. No Etsy category tree.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var returnPolicySection: some View {
        Section {
            notApplicableToggle("Return policy", isOn: $project.listingReturnPolicyNotApplicable)
            if !project.listingReturnPolicyNotApplicable {
                TextField("Return policy text", text: $project.listingReturnPolicy, axis: .vertical)
                    .lineLimit(3...8)
                    .foregroundStyle(DarkroomTheme.textPrimary)
            }
        } header: {
            Text("Return Policy")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var altTextSection: some View {
        Section {
            if project.sortedPhotos.isEmpty {
                Text("No project photos yet.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                ForEach(Array(project.sortedPhotos.enumerated()), id: \.element.persistentModelID) { index, photo in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            if let thumb = photo.thumbnailImage {
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            Text("Photo \(index + 1)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DarkroomTheme.textPrimary)
                        }
                        Toggle("Not Applicable", isOn: Binding(
                            get: { photo.altTextNotApplicable },
                            set: { photo.altTextNotApplicable = $0 }
                        ))
                        if !photo.altTextNotApplicable {
                            TextField("Alt text", text: Binding(
                                get: { photo.altText },
                                set: { photo.altText = $0 }
                            ), axis: .vertical)
                            .lineLimit(2...4)
                            .foregroundStyle(DarkroomTheme.textPrimary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Photo Alt Text")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Alt text is stored on each photo, so reorder and delete keep the correct text with the remaining photos.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var reviewSection: some View {
        Section {
            let review = ListingInformationSupport.review(for: project)
            Text(review.summaryLine)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textSecondary)

            reviewGroup("Filled", fields: review.filled, color: DarkroomTheme.accent)
            reviewGroup("Missing", fields: review.missing, color: DarkroomTheme.danger)
            reviewGroup("Not Applicable", fields: review.notApplicable, color: DarkroomTheme.textTertiary)
            reviewGroup("Needs Review", fields: review.needingReview, color: DarkroomTheme.danger)
        } header: {
            Text("Listing Information Review")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local completeness only. This does not mark a draft Etsy-ready and does not change Phase 25 queue readiness.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var saveSection: some View {
        Section {
            Button("Save Listing Information") {
                saveListingInformation()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DarkroomTheme.accent)

            if let saveMessage {
                Text(saveMessage)
                    .font(.caption)
                    .foregroundStyle(saveIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .listRowBackground(sectionBackground)
    }

    @ViewBuilder
    private func variationEditor(index: Int) -> some View {
        let id = variations[index].id
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Enabled", isOn: Binding(
                get: { variations[index].isEnabled },
                set: { variations[index].isEnabled = $0 }
            ))
            TextField("Name", text: Binding(
                get: { variations[index].name },
                set: { variations[index].name = $0 }
            ))
            .foregroundStyle(DarkroomTheme.textPrimary)
            TextField("Options (comma-separated)", text: Binding(
                get: { variationOptionsRaw[id] ?? variations[index].optionsRawText },
                set: { variationOptionsRaw[id] = $0 }
            ), axis: .vertical)
            .lineLimit(2...4)
            .foregroundStyle(DarkroomTheme.textPrimary)
            TextField("Price difference", text: Binding(
                get: { variations[index].priceDifferenceText },
                set: { variations[index].priceDifferenceText = $0 }
            ))
            .keyboardType(.decimalPad)
            .foregroundStyle(DarkroomTheme.textPrimary)
            TextField("Quantity", text: Binding(
                get: { String(variations[index].quantity) },
                set: { variations[index].quantity = Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) ?? variations[index].quantity }
            ))
            .keyboardType(.numberPad)
            .foregroundStyle(DarkroomTheme.textPrimary)
            TextField("SKU", text: Binding(
                get: { variations[index].sku },
                set: { variations[index].sku = $0 }
            ))
            .foregroundStyle(DarkroomTheme.textPrimary)
            Button("Remove Variation", role: .destructive) {
                variationOptionsRaw[id] = nil
                variations.remove(at: index)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 4)
    }

    private func reviewGroup(_ title: String, fields: [ListingInfoFieldReport], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) (\(fields.count))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            if fields.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textTertiary)
            } else {
                ForEach(fields) { field in
                    Text(field.detail.map { "\(field.label): \($0)" } ?? field.label)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func notApplicableToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle("\(title) — Not Applicable", isOn: isOn)
    }

    private func labeledValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DarkroomTheme.textPrimary)
        }
        .padding(.vertical, 2)
    }

    private func loadEditors() {
        variations = project.listingVariations
        attributes = project.listingAttributes
        variationOptionsRaw = Dictionary(uniqueKeysWithValues: variations.map { ($0.id, $0.optionsRawText) })
        saveMessage = nil
    }

    private func saveListingInformation() {
        for index in variations.indices {
            let id = variations[index].id
            if let raw = variationOptionsRaw[id] {
                variations[index].options = ListingVariation.normalizedOptions(fromRaw: raw)
            }
        }
        project.listingVariations = variations
        project.listingAttributes = attributes
        ListingInformationSupport.sanitize(project: project)
        variations = project.listingVariations
        attributes = project.listingAttributes
        variationOptionsRaw = Dictionary(uniqueKeysWithValues: variations.map { ($0.id, $0.optionsRawText) })

        let issues = ListingInformationSupport.validationIssues(for: project)
        guard issues.isEmpty else {
            saveIsError = true
            saveMessage = issues.joined(separator: " · ")
            project.touchModified()
            return
        }

        project.touchModified()
        try? modelContext.save()
        saveIsError = false
        saveMessage = "Listing information saved"
    }
}
