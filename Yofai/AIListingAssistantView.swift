import SwiftUI
import SwiftData

/// Local AI Listing Assistant. No network. Production provider is disconnected.
struct AIListingAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ItemProject

    @State private var recordToDelete: AIPreparationRecord?

    private var provider: AIListingProviding { DisconnectedAIListingProvider.shared }

    var body: some View {
        List {
            statusSection
            preparationsSection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .darkroomScreen()
        .navigationTitle("AI Listing Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog(
            "Delete AI Preparation?",
            isPresented: Binding(
                get: { recordToDelete != nil },
                set: { if !$0 { recordToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Preparation", role: .destructive) {
                if let record = recordToDelete {
                    modelContext.delete(record)
                    recordToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                recordToDelete = nil
            }
        } message: {
            Text("Removes only this local AI Preparation record and its suggestions.")
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

    private var statusSection: some View {
        Section {
            Text(provider.statusMessage)
                .font(.headline)
                .foregroundStyle(DarkroomTheme.accent)
            Text("No photos or listing data leave this device in this phase. AI generation is not connected.")
                .font(.subheadline)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(provider.isConnected ? "Provider connected" : "Provider disconnected")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } header: {
            Text("Status")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var preparationsSection: some View {
        Section {
            NavigationLink {
                AIPreparationEditorView(project: project, existing: nil)
            } label: {
                Text("New AI Preparation")
                    .foregroundStyle(DarkroomTheme.accent)
            }

            if project.sortedAIPreparations.isEmpty {
                Text("No AI Preparation records yet.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                ForEach(project.sortedAIPreparations, id: \.persistentModelID) { record in
                    NavigationLink {
                        AIPreparationDetailView(project: project, record: record)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.createdAt, format: .dateTime.month().day().hour().minute())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DarkroomTheme.textPrimary)
                            Text(record.status.displayName)
                                .font(.caption)
                                .foregroundStyle(DarkroomTheme.textSecondary)
                            Text("\(record.selectedPhotoIDs.count) photo\(record.selectedPhotoIDs.count == 1 ? "" : "s") · \(record.suggestionTypes.count) suggestion type\(record.suggestionTypes.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(DarkroomTheme.textTertiary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            recordToDelete = record
                        }
                    }
                }
            }
        } header: {
            Text("AI Preparations")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Preparations are local SwiftData records. Deleting a project removes them. Duplicate Listing Draft does not copy them.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }
}

struct AIPreparationEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: ItemProject
    var existing: AIPreparationRecord?

    @State private var selectedPhotoIDs: Set<UUID> = []
    @State private var selectedTypes: Set<AISuggestionType> = []
    @State private var excludedFields: Set<AIContextField> = []
    @State private var showReview = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            photosSection
            typesSection
            contextSection
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(DarkroomTheme.danger)
                }
                .listRowBackground(sectionBackground)
            }
            Section {
                Button("Review AI Preparation") {
                    validateAndReview()
                }
                .foregroundStyle(DarkroomTheme.accent)
            }
            .listRowBackground(sectionBackground)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .darkroomScreen()
        .navigationTitle(existing == nil ? "New Preparation" : "Edit Preparation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExisting()
        }
        .navigationDestination(isPresented: $showReview) {
            AIPreparationReviewView(
                project: project,
                selectedPhotoIDs: orderedSelectedPhotoIDs,
                suggestionTypes: orderedSelectedTypes,
                excludedFields: Array(excludedFields),
                existing: existing
            )
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

    private var orderedSelectedPhotoIDs: [UUID] {
        project.sortedPhotos.map(\.stableID).filter { selectedPhotoIDs.contains($0) }
    }

    private var orderedSelectedTypes: [AISuggestionType] {
        AISuggestionType.allCases.filter { selectedTypes.contains($0) }
    }

    private var photosSection: some View {
        Section {
            if project.sortedPhotos.isEmpty {
                Text("Add project photos first.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                ForEach(project.sortedPhotos, id: \.stableID) { photo in
                    Button {
                        if selectedPhotoIDs.contains(photo.stableID) {
                            selectedPhotoIDs.remove(photo.stableID)
                        } else {
                            selectedPhotoIDs.insert(photo.stableID)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedPhotoIDs.contains(photo.stableID) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(DarkroomTheme.accent)
                            if let thumb = photo.thumbnailImage {
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            Text("Photo \(photo.sortOrder + 1)")
                                .foregroundStyle(DarkroomTheme.textPrimary)
                            Spacer()
                        }
                    }
                }
            }
        } header: {
            Text("Product Reference Photos")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Selected photos stay in current project order.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var typesSection: some View {
        Section {
            ForEach(AISuggestionType.allCases) { type in
                Toggle(type.rawValue, isOn: Binding(
                    get: { selectedTypes.contains(type) },
                    set: { on in
                        if on { selectedTypes.insert(type) } else { selectedTypes.remove(type) }
                    }
                ))
            }
        } header: {
            Text("Requested Suggestions")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var contextSection: some View {
        Section {
            ForEach(AIContextField.allCases) { field in
                Toggle("Exclude \(field.displayName)", isOn: Binding(
                    get: { excludedFields.contains(field) },
                    set: { on in
                        if on { excludedFields.insert(field) } else { excludedFields.remove(field) }
                    }
                ))
                if !excludedFields.contains(field) {
                    Text(AIListingAssistantSupport.contextValue(for: field, project: project).isEmpty
                         ? "—"
                         : AIListingAssistantSupport.contextValue(for: field, project: project))
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } header: {
            Text("Local Listing Context")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Excluded fields are not included in the local AI Preparation context.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private func loadExisting() {
        guard let existing else { return }
        selectedPhotoIDs = Set(existing.selectedPhotoIDs)
        selectedTypes = Set(existing.suggestionTypes)
        excludedFields = Set(existing.excludedContextFields)
    }

    private func validateAndReview() {
        errorMessage = nil
        guard !orderedSelectedPhotoIDs.isEmpty else {
            errorMessage = "Select at least one project photo."
            return
        }
        guard !orderedSelectedTypes.isEmpty else {
            errorMessage = "Select at least one suggestion type."
            return
        }
        showReview = true
    }
}

struct AIPreparationReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: ItemProject
    let selectedPhotoIDs: [UUID]
    let suggestionTypes: [AISuggestionType]
    let excludedFields: [AIContextField]
    var existing: AIPreparationRecord?

    @State private var savedRecord: AIPreparationRecord?
    @State private var saveMessage: String?

    private var includedFields: [AIContextField] {
        AIContextField.allCases.filter { !excludedFields.contains($0) }
    }

    var body: some View {
        List {
            Section {
                Text("Photos: \(selectedPhotoIDs.count) in project order")
                Text("Suggestion types: \(suggestionTypes.map(\.rawValue).joined(separator: ", "))")
                    .fixedSize(horizontal: false, vertical: true)
                Text("Included context: \(includedFields.map(\.displayName).joined(separator: ", "))")
                    .fixedSize(horizontal: false, vertical: true)
                Text("Excluded context: \(excludedFields.isEmpty ? "None" : excludedFields.map(\.displayName).joined(separator: ", "))")
                    .fixedSize(horizontal: false, vertical: true)
                Text("AI is not connected yet. Saving keeps this request local only.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Review Before Save")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            .listRowBackground(sectionBackground)

            Section {
                Button("Save as Draft") {
                    save(status: .draft)
                }
                .foregroundStyle(DarkroomTheme.accent)

                Button("Save as Ready for AI") {
                    save(status: .readyForAI)
                }
                .foregroundStyle(DarkroomTheme.accent)

                if let saveMessage {
                    Text(saveMessage)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.accent)
                }

                if let savedRecord {
                    NavigationLink("Open Preparation") {
                        AIPreparationDetailView(project: project, record: savedRecord)
                    }
                }
            }
            .listRowBackground(sectionBackground)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .darkroomScreen()
        .navigationTitle("Review Request")
        .navigationBarTitleDisplayMode(.inline)
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

    private func save(status: AIPreparationStatus) {
        let record: AIPreparationRecord
        if let existing {
            record = existing
        } else {
            record = AIPreparationRecord(project: project)
            modelContext.insert(record)
        }
        record.selectedPhotoIDs = selectedPhotoIDs
        record.suggestionTypes = suggestionTypes
        record.excludedContextFields = excludedFields
        record.includedContextFields = includedFields
        record.status = status
        record.errorMessage = ""
        project.touchModified()
        try? modelContext.save()
        savedRecord = record
        saveMessage = "AI Preparation saved locally (\(status.displayName))."
    }
}

struct AIPreparationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ItemProject
    @Bindable var record: AIPreparationRecord

    @State private var workingSuggestions: [AISuggestionDraft] = []
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var showApplyConfirm = false
    @State private var showReorderConfirm = false
    @State private var pendingConfirmReorder = false
    @State private var changePreview: [String] = []

    private var provider: AIListingProviding { DisconnectedAIListingProvider.shared }

    var body: some View {
        List {
            overviewSection
            actionsSection
            suggestionsSection
            applySection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .darkroomScreen()
        .navigationTitle("Preparation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            workingSuggestions = record.suggestions
        }
        .confirmationDialog("Apply approved suggestions?", isPresented: $showApplyConfirm, titleVisibility: .visible) {
            Button("Apply Approved") {
                apply(confirmReorder: pendingConfirmReorder)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(changePreview.isEmpty ? "Only approved, non-discarded suggestions will update the draft." : changePreview.joined(separator: "\n"))
        }
        .confirmationDialog("Apply proposed photo order?", isPresented: $showReorderConfirm, titleVisibility: .visible) {
            Button("Confirm Photo Order & Apply") {
                pendingConfirmReorder = true
                apply(confirmReorder: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(photoOrderComparisonText)
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

    private var overviewSection: some View {
        Section {
            Text(provider.statusMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
            Text("Status: \(record.status.displayName)")
            Text(record.createdAt, format: .dateTime.month().day().hour().minute())
            Text("Photos: \(record.selectedPhotoIDs.count) · Types: \(record.suggestionTypes.count)")
            if !record.errorMessage.isEmpty {
                Text(record.errorMessage)
                    .foregroundStyle(DarkroomTheme.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Excluded: \(record.excludedContextFields.isEmpty ? "None" : record.excludedContextFields.map(\.displayName).joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Text("Overview")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var actionsSection: some View {
        Section {
            Button("Request AI Suggestions") {
                Task {
                    await AIListingAssistantSupport.requestSuggestions(
                        for: record,
                        project: project,
                        provider: provider
                    )
                    workingSuggestions = record.suggestions
                    statusIsError = record.status == .failed
                    statusMessage = record.errorMessage.isEmpty
                        ? "Suggestions ready for review."
                        : record.errorMessage
                }
            }
            .foregroundStyle(DarkroomTheme.accent)

            Button("Create Manual Placeholders") {
                workingSuggestions = AIListingAssistantSupport.makePlaceholderSuggestions(
                    types: record.suggestionTypes,
                    selectedPhotoIDs: record.selectedPhotoIDs
                )
                record.suggestions = workingSuggestions
                record.status = .awaitingReview
                record.errorMessage = ""
                statusIsError = false
                statusMessage = "Manual placeholders ready. Enter text yourself — no AI content was generated."
                try? modelContext.save()
            }
            .foregroundStyle(DarkroomTheme.accent)

            Button("Save Suggestion Edits") {
                persistWorkingSuggestions(markSellerEdited: true)
                statusIsError = false
                statusMessage = "Suggestion edits saved locally."
            }
            .foregroundStyle(DarkroomTheme.accent)

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(statusIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text("Actions")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Request AI uses the disconnected provider in this build. Manual placeholders never invent AI copy.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var suggestionsSection: some View {
        Section {
            if workingSuggestions.isEmpty {
                Text("No suggestions yet.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                ForEach(Array(workingSuggestions.enumerated()), id: \.element.id) { index, _ in
                    suggestionEditor(index: index)
                }
            }
        } header: {
            Text("Suggestions")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var applySection: some View {
        Section {
            Button("Preview & Apply Approved") {
                persistWorkingSuggestions(markSellerEdited: false)
                changePreview = previewChanges()
                if needsReorderConfirmation {
                    showReorderConfirm = true
                } else {
                    pendingConfirmReorder = false
                    showApplyConfirm = true
                }
            }
            .foregroundStyle(DarkroomTheme.accent)
        } header: {
            Text("Apply")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Applies only approved suggestions. Never changes price, quantity, shipping, processing, returns, variations, personalization, SKU, condition, item type, export settings, or queue state. Never auto-applies.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    @ViewBuilder
    private func suggestionEditor(index: Int) -> some View {
        let suggestion = workingSuggestions[index]
        VStack(alignment: .leading, spacing: 8) {
            Text(suggestion.type.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
            Text(suggestion.source.displayName)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)

            if suggestion.isDiscarded {
                Text("Discarded")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.danger)
            } else {
                switch suggestion.type {
                case .tags:
                    TextField("Tags (comma-separated)", text: Binding(
                        get: { workingSuggestions[index].tagsValue.joined(separator: ", ") },
                        set: { raw in
                            workingSuggestions[index].tagsValue = ItemProject.normalizedTags(fromRaw: raw)
                            markEdited(index)
                        }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                case .photoAltText:
                    ForEach(record.selectedPhotoIDs, id: \.self) { photoID in
                        let label = project.photos.first(where: { $0.stableID == photoID }).map { "Photo \($0.sortOrder + 1)" } ?? photoID.uuidString
                        TextField(label, text: Binding(
                            get: { workingSuggestions[index].altTextByPhotoID[photoID.uuidString] ?? "" },
                            set: { value in
                                workingSuggestions[index].altTextByPhotoID[photoID.uuidString] = value
                                markEdited(index)
                            }
                        ), axis: .vertical)
                        .lineLimit(2...3)
                    }
                case .photoOrderRecommendation:
                    Text("Current: \(currentOrderLabels.joined(separator: " → "))")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    Text("Proposed: \(proposedOrderLabels(for: workingSuggestions[index]).joined(separator: " → "))")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    Text("Edit proposed order as comma-separated photo numbers (1-based in current project order).")
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                    TextField("Proposed order", text: Binding(
                        get: {
                            workingSuggestions[index].proposedPhotoOrderIDs.compactMap { idString in
                                guard let uuid = UUID(uuidString: idString),
                                      let photo = project.photos.first(where: { $0.stableID == uuid }) else { return nil }
                                return String(photo.sortOrder + 1)
                            }.joined(separator: ", ")
                        },
                        set: { raw in
                            let numbers = raw.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                            let sorted = project.sortedPhotos
                            workingSuggestions[index].proposedPhotoOrderIDs = numbers.compactMap { number in
                                guard number >= 1, number <= sorted.count else { return nil }
                                return sorted[number - 1].stableID.uuidString
                            }
                            markEdited(index)
                        }
                    ))
                default:
                    TextField(suggestion.type.rawValue, text: Binding(
                        get: { workingSuggestions[index].textValue },
                        set: { value in
                            workingSuggestions[index].textValue = value
                            markEdited(index)
                        }
                    ), axis: .vertical)
                    .lineLimit(2...6)
                }

                Toggle("Approve for apply", isOn: Binding(
                    get: { workingSuggestions[index].isApproved },
                    set: { workingSuggestions[index].isApproved = $0 }
                ))
            }

            Button(suggestion.isDiscarded ? "Restore Suggestion" : "Discard Suggestion") {
                workingSuggestions[index].isDiscarded.toggle()
                if workingSuggestions[index].isDiscarded {
                    workingSuggestions[index].isApproved = false
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(DarkroomTheme.danger)
        }
        .padding(.vertical, 4)
    }

    private var currentOrderLabels: [String] {
        project.sortedPhotos.map { "P\($0.sortOrder + 1)" }
    }

    private func proposedOrderLabels(for suggestion: AISuggestionDraft) -> [String] {
        let ids = suggestion.proposedPhotoOrderIDs.compactMap(UUID.init(uuidString:))
        return ids.compactMap { id in
            project.photos.first(where: { $0.stableID == id }).map { "P\($0.sortOrder + 1)" }
        }
    }

    private var photoOrderComparisonText: String {
        let approvedOrder = workingSuggestions.first {
            $0.type == .photoOrderRecommendation && $0.isApproved && !$0.isDiscarded
        }
        let proposed = approvedOrder.map { proposedOrderLabels(for: $0).joined(separator: " → ") } ?? "—"
        return "Current order: \(currentOrderLabels.joined(separator: " → "))\nProposed order: \(proposed)\nAlt text stays on each photo."
    }

    private var needsReorderConfirmation: Bool {
        workingSuggestions.contains {
            $0.type == .photoOrderRecommendation && $0.isApproved && !$0.isDiscarded
        }
    }

    private func markEdited(_ index: Int) {
        if workingSuggestions[index].source != .applied {
            workingSuggestions[index].source = .sellerEdited
        }
    }

    private func persistWorkingSuggestions(markSellerEdited: Bool) {
        if markSellerEdited {
            for index in workingSuggestions.indices where !workingSuggestions[index].isDiscarded {
                if workingSuggestions[index].source == .placeholderManual || workingSuggestions[index].source == .futureAI {
                    // keep unless text changed via markEdited already
                }
            }
        }
        record.suggestions = workingSuggestions
        if record.status == .draft || record.status == .readyForAI || record.status == .failed {
            if !workingSuggestions.isEmpty {
                record.status = .awaitingReview
            }
        }
        try? modelContext.save()
    }

    private func previewChanges() -> [String] {
        var lines: [String] = []
        for suggestion in workingSuggestions where suggestion.isApproved && !suggestion.isDiscarded {
            switch suggestion.type {
            case .listingTitle:
                lines.append("Title → \(suggestion.textValue)")
            case .description:
                lines.append("Description → (updated)")
            case .tags:
                lines.append("Tags → \(suggestion.tagsValue.joined(separator: ", "))")
            case .categoryText:
                lines.append("Category → \(suggestion.textValue)")
            case .materials:
                lines.append("Materials → \(suggestion.textValue)")
            case .photoAltText:
                lines.append("Photo alt text → (selected photos)")
            case .photoOrderRecommendation:
                lines.append("Photo order → \(proposedOrderLabels(for: suggestion).joined(separator: " → "))")
            }
        }
        return lines
    }

    private func apply(confirmReorder: Bool) {
        persistWorkingSuggestions(markSellerEdited: false)
        do {
            let changes = try AIListingAssistantSupport.applyApprovedSuggestions(
                from: record,
                to: project,
                confirmPhotoReorder: confirmReorder
            )
            workingSuggestions = record.suggestions
            // Do not create History / exports / packages / queue entries.
            try? modelContext.save()
            statusIsError = false
            statusMessage = changes.isEmpty ? "No approved suggestions to apply." : "Applied: \(changes.joined(separator: " · "))"
        } catch {
            statusIsError = true
            statusMessage = (error as? LocalizedError)?.errorDescription ?? "Could not apply suggestions."
        }
    }
}
