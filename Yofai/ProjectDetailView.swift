import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: ItemProject

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isAddingPhotos = false
    @State private var addError: String?
    @State private var showDeleteConfirm = false

    // Listing draft editors (local only — Phase 23)
    @State private var draftTitle: String = ""
    @State private var draftDescription: String = ""
    @State private var draftPriceText: String = ""
    @State private var draftQuantityText: String = "1"
    @State private var draftCategory: String = ""
    @State private var draftTagsRaw: String = ""
    @State private var draftMaterials: String = ""
    @State private var draftShippingProfile: String = ""
    @State private var draftProcessingTime: String = ""
    @State private var listingSaveMessage: String?
    @State private var listingSaveIsError = false

    @State private var isExportingBatch = false
    @State private var exportProgressCompleted = 0
    @State private var exportProgressTotal = 0
    @State private var exportStatusMessage: String?
    @State private var exportStatusIsError = false
    @State private var shareBatchItem: ShareBatchItem?
    @State private var batchToDelete: ProjectExportBatch?
    @State private var recentlyExportedBatch: ProjectExportBatch?
    @State private var noteEditorBatch: ProjectExportBatch?
    @State private var showDuplicateSheet = false
    @State private var duplicateName = ""
    @State private var duplicateError: String?
    @State private var exportScrollTarget: String?

    private var sortedPhotos: [ItemProjectPhoto] {
        project.sortedPhotos
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
            Section {
                TextField("Item name", text: $project.name)
                    .onChange(of: project.name) { _, _ in
                        project.touchModified()
                    }

                NavigationLink {
                    ProductIntakeView(project: project)
                } label: {
                    Text(SellerNavigationSupport.projectIntakeLinkTitle)
                        .foregroundStyle(DarkroomTheme.accent)
                }
                .accessibilityLabel(SellerNavigationSupport.projectIntakeLinkTitle)

                NavigationLink {
                    ListingWorkspaceView(project: project)
                } label: {
                    Text(SellerNavigationSupport.projectWorkspaceLinkTitle)
                        .foregroundStyle(DarkroomTheme.accent)
                }
                .accessibilityLabel(SellerNavigationSupport.projectWorkspaceLinkTitle)
            } header: {
                Text("Item")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            } footer: {
                Text("Seller path: capture & check photos, then prepare listing and local export.")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            .listRowBackground(sectionBackground)

            listingDetailsSection

            projectExportSettingsSection

            batchExportSection

            ExportHistorySection(
                project: project,
                onUseSettings: { batch in
                    batch.applyExportSettings(to: project)
                    exportStatusMessage = "Export settings restored. Photo edits unchanged. Tap Export Photos when ready."
                    exportStatusIsError = false
                },
                onExportAgain: { batch in
                    batch.applyExportSettings(to: project)
                    exportStatusMessage = "Settings ready for Export Again. Photo edits unchanged — tap Export Photos to export."
                    exportStatusIsError = false
                },
                onShare: { batch in
                    shareBatchItem = ShareBatchItem(urls: batch.fileURLs)
                },
                onDelete: { batch in
                    batchToDelete = batch
                }
            )
            .listRowBackground(sectionBackground)

            Section {
                if sortedPhotos.isEmpty {
                    Text("No photos in this project yet.")
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                } else {
                    ForEach(sortedPhotos) { photo in
                        let missing = !LocalEditStore.projectFileExists(fileName: photo.localFileName)
                        if missing {
                            projectPhotoRow(photo, isMissing: true)
                        } else {
                            NavigationLink {
                                ProjectPhotoEditDestination(photo: photo)
                            } label: {
                                projectPhotoRow(photo, isMissing: false)
                            }
                        }
                    }
                    .onMove(perform: movePhotos)
                    .onDelete(perform: removePhotos)
                }
            } header: {
                Text("Photos")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            } footer: {
                Text("Drag to reorder. Swipe to remove from this project only. Tap Edit to open the existing editor.")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            .listRowBackground(sectionBackground)

            if !sortedPhotos.isEmpty {
                Section {
                    NavigationLink {
                        BulkEditPhotosView(project: project)
                    } label: {
                        Text("Bulk Edit Photos")
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                }
                .listRowBackground(sectionBackground)
            }

            if let addError {
                Section {
                    Text(addError)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.danger)
                }
                .listRowBackground(sectionBackground)
            }

            Section {
                Button {
                    duplicateName = ""
                    duplicateError = nil
                    showDuplicateSheet = true
                } label: {
                    Text("Duplicate Listing Draft")
                        .foregroundStyle(DarkroomTheme.accent)
                        .frame(maxWidth: .infinity)
                }

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete Project")
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(sectionBackground)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .darkroomScreen()
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: exportScrollTarget) { _, target in
            guard let target else { return }
            withAnimation {
                proxy.scrollTo(target, anchor: .top)
            }
            exportScrollTarget = nil
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
            ToolbarItem(placement: .primaryAction) {
                let adding = isAddingPhotos
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    if adding {
                        ProgressView()
                    } else {
                        Image(systemName: "plus")
                    }
                }
                .disabled(adding)
                .accessibilityLabel("Add Photos")
            }
        }
        .onAppear {
            loadListingDraftIntoEditors()
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await addPhotos(from: newItems) }
        }
        .confirmationDialog(
            "Delete this project?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Project", role: .destructive) {
                deleteProject()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes this project and its local project photo files. Originals, History, and Photos library stay.")
        }
        .sheet(isPresented: $showDuplicateSheet) {
            duplicateListingDraftSheet
        }
        .confirmationDialog(
            "Delete export batch?",
            isPresented: Binding(
                get: { batchToDelete != nil },
                set: { if !$0 { batchToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Batch", role: .destructive) {
                if let batchToDelete {
                    deleteBatch(batchToDelete)
                }
                batchToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                batchToDelete = nil
            }
        } message: {
            Text("Removes only this export batch’s JPEG files. Project photos stay.")
        }
        .sheet(item: $shareBatchItem) { item in
            ActivityShareView(items: item.urls)
        }
        .sheet(item: $noteEditorBatch) { batch in
            ExportBatchNoteEditor(batch: batch)
        }
        } // ScrollViewReader
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

    @ViewBuilder
    private var listingDetailsSection: some View {
        Section {
            Text(project.listingCompletenessSummary)
                .font(.caption.weight(.semibold))
                .foregroundStyle(project.isListingDraftComplete ? DarkroomTheme.accent : DarkroomTheme.textSecondary)

            labeledField("Title", text: $draftTitle, axis: .horizontal)
            labeledField("Description", text: $draftDescription, axis: .vertical, lineLimit: 4...8)
            labeledField("Price", text: $draftPriceText, axis: .horizontal, keyboard: .decimalPad)
            labeledField("Quantity", text: $draftQuantityText, axis: .horizontal, keyboard: .numberPad)
            labeledField("Category", text: $draftCategory, axis: .horizontal)
            labeledField("Tags (comma-separated, max 13)", text: $draftTagsRaw, axis: .vertical, lineLimit: 2...4)
            labeledField("Materials", text: $draftMaterials, axis: .vertical, lineLimit: 2...4)
            labeledField("Shipping profile", text: $draftShippingProfile, axis: .horizontal)
            labeledField("Processing time", text: $draftProcessingTime, axis: .horizontal)

            Button("Save Listing Draft") {
                saveListingDraft()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DarkroomTheme.accent)

            if let listingSaveMessage {
                Text(listingSaveMessage)
                    .font(.caption)
                    .foregroundStyle(listingSaveIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
            }
        } header: {
            Text("Listing Details")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local draft only. Nothing is sent to Etsy.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private func labeledField(
        _ title: String,
        text: Binding<String>,
        axis: Axis,
        lineLimit: ClosedRange<Int> = 1...1,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
            if axis == .vertical {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(lineLimit)
                    .keyboardType(keyboard)
                    .foregroundStyle(DarkroomTheme.textPrimary)
            } else {
                TextField(title, text: text)
                    .keyboardType(keyboard)
                    .foregroundStyle(DarkroomTheme.textPrimary)
            }
        }
        .padding(.vertical, 2)
    }

    private func loadListingDraftIntoEditors() {
        draftTitle = project.listingTitle
        draftDescription = project.listingDescription
        draftPriceText = project.listingPriceText
        draftQuantityText = String(max(project.listingQuantity, 1))
        draftCategory = project.listingCategory
        draftTagsRaw = project.listingTagsRawText
        draftMaterials = project.listingMaterials
        draftShippingProfile = project.listingShippingProfile
        draftProcessingTime = project.listingProcessingTime
        listingSaveMessage = nil
    }

    private func saveListingDraft() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = ItemProject.normalizedTags(fromRaw: draftTagsRaw)
        let quantity = Int(draftQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let priceTrimmed = draftPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let price = ItemProject.parsePrice(priceTrimmed)

        var issues: [String] = []
        if title.isEmpty {
            issues.append("Title is required")
        }
        if priceTrimmed.isEmpty {
            issues.append("Price is required")
        } else if price == nil {
            issues.append("Price must be a valid amount")
        } else if let price, price < 0 {
            issues.append("Price must be nonnegative")
        }
        if quantity < 1 {
            issues.append("Quantity must be at least 1")
        }
        if tags.count > ItemProject.maxTagCount {
            issues.append("Maximum \(ItemProject.maxTagCount) tags")
        }

        guard issues.isEmpty else {
            listingSaveIsError = true
            listingSaveMessage = issues.joined(separator: " · ")
            return
        }

        project.listingTitle = title
        project.listingDescription = draftDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingPriceText = priceTrimmed
        project.listingQuantity = quantity
        project.listingCategory = draftCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingTags = tags
        project.listingMaterials = draftMaterials.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingShippingProfile = draftShippingProfile.trimmingCharacters(in: .whitespacesAndNewlines)
        project.listingProcessingTime = draftProcessingTime.trimmingCharacters(in: .whitespacesAndNewlines)
        project.touchModified()
        syncQueueReadiness()

        draftTagsRaw = project.listingTagsRawText
        draftQuantityText = String(quantity)
        listingSaveIsError = false
        listingSaveMessage = "Listing draft saved"
    }

    private func syncQueueReadiness() {
        for entry in project.queueEntries {
            ListingQueueSupport.syncReadiness(for: entry)
        }
    }

    private var duplicateListingDraftSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("New item name", text: $duplicateName)
                        .textInputAutocapitalization(.words)
                    if let duplicateError {
                        Text(duplicateError)
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.danger)
                    }
                } header: {
                    Text("New Project")
                }

                Section {
                    Text("Does not copy photos, local image files, saved edits, export batches, packages, queue entries, AI preparations, goal completion/attachments, History, or Originals.")
                    Text("Copies listing details, listing information, export settings, and photo-plan goal names/order only.")
                    Text("The new project starts outside the Listing Queue.")
                } header: {
                    Text("What is copied")
                }
            }
            .scrollContentBackground(.hidden)
            .darkroomScreen()
            .navigationTitle("Duplicate Listing Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDuplicateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Duplicate") {
                        createDuplicateListingDraft()
                    }
                }
            }
        }
    }

    private func createDuplicateListingDraft() {
        let trimmed = duplicateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            duplicateError = "A new item name is required."
            return
        }
        let copy = project.duplicateListingDraft(newName: trimmed)
        modelContext.insert(copy)
        showDuplicateSheet = false
    }

    @ViewBuilder
    private var projectExportSettingsSection: some View {
        MarketplaceExportSettingsBlock(
            project: project,
            showPreview: true,
            readinessStyle: .compact,
            showWorkspaceLinkInReadiness: true,
            prepTipsStyle: .compact,
            showWorkspaceLinkInPrepTips: true,
            onFocusAnchor: { anchor in
                exportScrollTarget = anchor.rawValue
            }
        )
    }

    @ViewBuilder
    private var batchExportSection: some View {
        Section {
            Button {
                Task { await exportListingImages() }
            } label: {
                if isExportingBatch {
                    HStack {
                        ProgressView()
                        Text("Exporting \(exportProgressCompleted)/\(max(exportProgressTotal, 1))…")
                    }
                } else {
                    Text("Export Photos")
                        .foregroundStyle(DarkroomTheme.accent)
                }
            }
            .disabled(isExportingBatch || sortedPhotos.isEmpty)

            Text("Switch Marketplace above, then Export Photos again for another target without redoing photo edits.")
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if let exportStatusMessage {
                Text(exportStatusMessage)
                    .font(.caption)
                    .foregroundStyle(exportStatusIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let recentlyExportedBatch, !exportStatusIsError {
                Button(recentlyExportedBatch.hasSellerNote ? "Edit Note" : "Add Note") {
                    noteEditorBatch = recentlyExportedBatch
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
                .accessibilityLabel(recentlyExportedBatch.hasSellerNote ? "Edit Note" : "Add Note")
            }
        } header: {
            Text("Export")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Saves ordered JPEGs under ExportBatches only. Does not change project photos, Originals, or edit History.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private func exportListingImages() async {
        guard !isExportingBatch else { return }
        isExportingBatch = true
        exportStatusMessage = nil
        exportStatusIsError = false
        recentlyExportedBatch = nil
        exportProgressCompleted = 0
        exportProgressTotal = sortedPhotos.count
        defer { isExportingBatch = false }

        do {
            let result = try ProjectBatchExporter.export(project: project) { completed, total in
                exportProgressCompleted = completed
                exportProgressTotal = total
            }
            if let batch = ProjectExportBatch.recordSuccessfulExport(from: result, project: project) {
                modelContext.insert(batch)
                project.touchModified()
                var summary = batch.resultSummaryText
                if !result.errorMessages.isEmpty {
                    summary += "\n" + result.errorMessages.joined(separator: " · ")
                }
                exportStatusMessage = summary
                exportStatusIsError = false
                recentlyExportedBatch = batch
            } else {
                // Clean up empty/failed folder if nothing succeeded.
                LocalEditStore.deleteExportBatchFolder(folderName: result.batchFolderName)
                exportStatusMessage = result.errorMessages.isEmpty
                    ? "Export did not complete. No history entry was saved."
                    : result.errorMessages.joined(separator: " · ")
                exportStatusIsError = true
            }
        } catch {
            exportStatusMessage = "Export failed."
            exportStatusIsError = true
        }
    }

    private func deleteBatch(_ batch: ProjectExportBatch) {
        LocalEditStore.deleteExportBatchFolder(folderName: batch.batchFolderName)
        modelContext.delete(batch)
        project.touchModified()
    }

    private func projectPhotoRow(_ photo: ItemProjectPhoto, isMissing: Bool) -> some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail = photo.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
            }
            .frame(width: 56, height: 56)
            .background(DarkroomTheme.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("Photo \(photo.sortOrder + 1)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                Text(photo.addedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                if isMissing {
                    Text("File missing")
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.danger)
                }
            }

            Spacer(minLength: 0)

            if !isMissing {
                Text("Edit")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }

    private func movePhotos(from source: IndexSet, to destination: Int) {
        var ordered = sortedPhotos
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, photo) in ordered.enumerated() {
            photo.sortOrder = index
        }
        project.touchModified()
        syncQueueReadiness()
    }

    private func removePhotos(at offsets: IndexSet) {
        let ordered = sortedPhotos
        for index in offsets {
            let photo = ordered[index]
            PhotoPlanSupport.clearAttachments(referencing: photo.stableID, in: project)
            LocalEditStore.deleteProjectFile(fileName: photo.localFileName)
            modelContext.delete(photo)
        }
        let remaining = project.sortedPhotos
        for (index, photo) in remaining.enumerated() {
            photo.sortOrder = index
        }
        project.touchModified()
        syncQueueReadiness()
    }

    private func addPhotos(from items: [PhotosPickerItem]) async {
        isAddingPhotos = true
        addError = nil
        defer {
            isAddingPhotos = false
            pickerItems = []
        }

        do {
            var nextOrder = (sortedPhotos.map(\.sortOrder).max() ?? -1) + 1
            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    throw PhotoSaveError.loadFailed
                }
                let fileName = try LocalEditStore.saveProjectImage(uiImage)
                let photo = ItemProjectPhoto(
                    localFileName: fileName,
                    thumbnailData: SavedEdit.makeThumbnailData(from: ImageEditing.normalizedOrientation(uiImage)),
                    sortOrder: nextOrder,
                    project: project
                )
                modelContext.insert(photo)
                nextOrder += 1
            }
            project.touchModified()
            syncQueueReadiness()
        } catch let error as PhotoSaveError {
            addError = error.localizedDescription
        } catch {
            addError = PhotoSaveError.loadFailed.localizedDescription
        }
    }

    private func deleteProject() {
        LocalEditStore.deleteAllListingPackages(for: project)
        LocalEditStore.deleteAllExportBatches(for: project)
        LocalEditStore.deleteAllFiles(for: project)
        modelContext.delete(project)
        dismiss()
    }
}

/// Loads the full project photo only when navigating to Edit (not while rendering the list).
struct ProjectPhotoEditDestination: View {
    let photo: ItemProjectPhoto

    var body: some View {
        Group {
            if let image = photo.fullLocalImage {
                EditView(sourceImage: image, projectPhoto: photo)
            } else {
                ContentUnavailableView(
                    "Image Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(PhotoSaveError.missingLocalFile.localizedDescription)
                )
            }
        }
    }
}
