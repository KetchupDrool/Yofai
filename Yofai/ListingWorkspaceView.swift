import SwiftUI
import SwiftData
import UIKit

/// Single local workflow surface for one Item Project’s listing readiness, photos, exports, and queue status.
/// Reuses existing models — does not duplicate listing drafts.
struct ListingWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ItemProject

    @State private var validationMessage: String?
    @State private var isExporting = false
    @State private var exportProgressCompleted = 0
    @State private var exportProgressTotal = 0
    @State private var exportStatusMessage: String?
    @State private var exportStatusIsError = false
    @State private var shareBatchItem: ShareBatchItem?
    @State private var queueActionMessage: String?
    @State private var packageStatusMessage: String?
    @State private var packageStatusIsError = false
    @State private var sharePackageItem: ShareBatchItem?
    @State private var packageToDelete: ListingPackage?
    @State private var exportScrollTarget: String?
    @State private var recentlyExportedBatch: ProjectExportBatch?
    @State private var noteEditorBatch: ProjectExportBatch?
    @State private var filesViewerBatch: ProjectExportBatch?

    private var queueEntry: ListingQueueEntry? {
        ListingQueueSupport.queueEntry(for: project, in: modelContext)
    }

    private var isQueued: Bool {
        ListingQueueSupport.isQueued(project, in: modelContext)
    }

    private var newestSuccessfulBatch: ProjectExportBatch? {
        project.sortedExportBatches.first { $0.successCount > 0 }
    }

    private var displayTitle: String {
        let title = project.trimmedListingTitle
        return title.isEmpty ? project.name : title
    }

    private var queueStatusLabel: String {
        if let entry = queueEntry {
            return entry.status.displayName
        }
        return "Not in queue"
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
            overviewSection
            readinessSection
            listingInformationSection
            aiAssistantSection
            productIntakeSection
            photosSection
            MarketplaceExportSettingsBlock(
                project: project,
                showPreview: true,
                readinessStyle: .full,
                prepTipsStyle: .full,
                showWorkspaceLinkInPrepTips: false,
                onFocusAnchor: { anchor in
                    exportScrollTarget = anchor.rawValue
                }
            )
            exportSection
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
                onShare: { batch, includeNote in
                    let caption = LocalExportShareSupport.shareCaption(for: batch, includeNote: includeNote)
                    shareBatchItem = ShareBatchItem(urls: batch.fileURLs, caption: caption)
                },
                onDelete: { batch in
                    LocalEditStore.deleteExportBatchFolder(folderName: batch.batchFolderName)
                    modelContext.delete(batch)
                    project.touchModified()
                }
            )
            .listRowBackground(sectionBackground)
            packageSection
            queueSection
            actionsSection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .darkroomScreen()
        .navigationTitle("Listing Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            refreshQueueReadiness()
        }
        .onChange(of: exportScrollTarget) { _, target in
            guard let target else { return }
            withAnimation {
                proxy.scrollTo(target, anchor: .top)
            }
            exportScrollTarget = nil
        }
        .sheet(item: $shareBatchItem) { item in
            ActivityShareView(items: item.activityItems)
        }
        .sheet(item: $sharePackageItem) { item in
            ActivityShareView(items: item.activityItems)
        }
        .sheet(item: $noteEditorBatch) { batch in
            ExportBatchNoteEditor(batch: batch)
        }
        .sheet(item: $filesViewerBatch) { batch in
            ExportedFilesViewer(batch: batch) { includeNote in
                let caption = LocalExportShareSupport.shareCaption(for: batch, includeNote: includeNote)
                shareBatchItem = ShareBatchItem(urls: batch.fileURLs, caption: caption)
            }
        }
        .confirmationDialog(
            "Delete listing package?",
            isPresented: Binding(
                get: { packageToDelete != nil },
                set: { if !$0 { packageToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Package", role: .destructive) {
                if let packageToDelete {
                    deletePackage(packageToDelete)
                }
                packageToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                packageToDelete = nil
            }
        } message: {
            Text("Removes only this package’s local files. Export batches and project photos stay.")
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

    private var overviewSection: some View {
        Section {
            HStack(alignment: .top, spacing: 14) {
                cover
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(.headline)
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Text(project.name)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    Text(ListingQueueSupport.completenessSummary(for: project))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            ListingQueueSupport.isReady(project)
                                ? DarkroomTheme.accent
                                : DarkroomTheme.textSecondary
                        )
                    Text(project.listingInformationReview.summaryLine)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    Text("Queue: \(queueStatusLabel)")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    Text("\(project.photoCount) photo\(project.photoCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }
                Spacer(minLength: 0)
            }
        } header: {
            Text("Overview")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var cover: some View {
        Group {
            if let image = project.coverThumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
        }
        .frame(width: 72, height: 72)
        .background(DarkroomTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var readinessSection: some View {
        Section {
            Text("Missing: \(ListingQueueSupport.missingRequiredSummary(for: project))")
                .font(.subheadline)
                .foregroundStyle(
                    ListingQueueSupport.isReady(project)
                        ? DarkroomTheme.accent
                        : DarkroomTheme.danger
                )
                .fixedSize(horizontal: false, vertical: true)

            Button("Validate Readiness") {
                validateReadiness()
            }
            .foregroundStyle(DarkroomTheme.accent)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(
                        ListingQueueSupport.isReady(project)
                            ? DarkroomTheme.accent
                            : DarkroomTheme.danger
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text("Readiness")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Uses Phase 25 rules only: photo file, title, price, quantity, ≤13 tags.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var listingInformationSection: some View {
        Section {
            let review = project.listingInformationReview
            Text(review.summaryLine)
                .font(.subheadline)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                ListingInformationView(project: project)
            } label: {
                Text("Open Listing Information")
                    .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Listing Information")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local listing fields and review only. Does not invent Etsy-ready status or change queue readiness.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var aiAssistantSection: some View {
        Section {
            Text(DisconnectedAIListingProvider.shared.statusMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
            Text("No photos or listing data leave this device in this phase.")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(project.sortedAIPreparations.count) preparation\(project.sortedAIPreparations.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)

            NavigationLink {
                AIListingAssistantView(project: project)
            } label: {
                Text("Open AI Listing Assistant")
                    .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("AI Listing Assistant")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local preparation and suggestion review only. AI is not connected yet.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var productIntakeSection: some View {
        Section {
            Text("Guided photo plan and camera capture for this project.")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
            let canvasNotes = PhotoTechnicalCheck.photosWithSourceSmallerThanExportCanvas(in: project).count
            Text("\(canvasNotes) photo\(canvasNotes == 1 ? "" : "s") smaller than export canvas (\(project.listingExportPreset.pickerLabel)) or unreadable")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                ProductIntakeView(project: project)
            } label: {
                Text("Product Intake / Capture Photos")
                    .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Product Intake")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Uses existing project photos. Photo-plan goals and export-canvas notes are local guidance only.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var photosSection: some View {
        Section {
            if project.sortedPhotos.isEmpty {
                Text("No photos yet.")
                    .font(.subheadline)
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                ForEach(Array(project.sortedPhotos.enumerated()), id: \.element.persistentModelID) { index, photo in
                    HStack(spacing: 10) {
                        Text("\(index + 1).")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.textTertiary)
                            .frame(width: 22, alignment: .leading)
                        if let thumb = photo.thumbnailImage {
                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        } else {
                            Image(systemName: "photo")
                                .frame(width: 40, height: 40)
                                .foregroundStyle(DarkroomTheme.textTertiary)
                        }
                        Text(LocalEditStore.projectFileExists(fileName: photo.localFileName) ? "Ready file" : "File missing")
                            .font(.caption)
                            .foregroundStyle(
                                LocalEditStore.projectFileExists(fileName: photo.localFileName)
                                    ? DarkroomTheme.textSecondary
                                    : DarkroomTheme.danger
                            )
                        Spacer()
                    }
                }
            }

            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                Text("Manage Photos & Listing Details")
                    .foregroundStyle(DarkroomTheme.accent)
            }

            if project.photoCount > 0 {
                NavigationLink {
                    BulkEditPhotosView(project: project)
                } label: {
                    Text("Bulk Edit Photos")
                        .foregroundStyle(DarkroomTheme.accent)
                }
            }
        } header: {
            Text("Photos (current order)")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Reorder, add, remove, and edit photos in Project Detail — existing flows only.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var packageSection: some View {
        Section {
            Button("Create Listing Package") {
                createListingPackage()
            }
            .foregroundStyle(DarkroomTheme.accent)

            if let packageStatusMessage {
                Text(packageStatusMessage)
                    .font(.caption)
                    .foregroundStyle(packageStatusIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(project.sortedListingPackages) { package in
                VStack(alignment: .leading, spacing: 6) {
                    Text(package.createdAt, format: .dateTime.month().day().hour().minute())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Text("\(package.photoCount) photo\(package.photoCount == 1 ? "" : "s") · batch \(package.sourceBatchFolderName.prefix(12))…")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    HStack(spacing: 16) {
                        if package.hasShareableFiles {
                            Button(LocalExportShareSupport.shareExportedPhotosTitle) {
                                sharePackageItem = ShareBatchItem(urls: package.fileURLs)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.accent)
                            .accessibilityLabel(LocalExportShareSupport.shareExportedPhotosTitle)
                        }
                        Button("Delete Package", role: .destructive) {
                            packageToDelete = package
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Listing Package")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Requires a successful local export batch first. Packages are shareable local JPEGs for manual upload — separate from export batches and source photos.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var exportSection: some View {
        Section {
            Button {
                Task { await exportListingImages() }
            } label: {
                if isExporting {
                    HStack {
                        ProgressView()
                        Text("Exporting \(exportProgressCompleted)/\(max(exportProgressTotal, 1))…")
                    }
                } else {
                    Text("Export Photos")
                        .foregroundStyle(DarkroomTheme.accent)
                }
            }
            .disabled(isExporting || project.photoCount == 0)

            Text("Need another marketplace? Switch Marketplace above, then Export Photos again. Photo edits stay.")
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if let exportStatusMessage {
                Text(exportStatusMessage)
                    .font(.caption)
                    .foregroundStyle(exportStatusIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(exportStatusIsError ? "Export error. \(exportStatusMessage)" : exportStatusMessage)
            }

            if let recentlyExportedBatch, !exportStatusIsError {
                LocalExportNextStepActions(
                    batch: recentlyExportedBatch,
                    onViewFiles: { filesViewerBatch = recentlyExportedBatch },
                    onShare: { includeNote in
                        let caption = LocalExportShareSupport.shareCaption(
                            for: recentlyExportedBatch,
                            includeNote: includeNote
                        )
                        shareBatchItem = ShareBatchItem(
                            urls: recentlyExportedBatch.fileURLs,
                            caption: caption
                        )
                    },
                    onNoteCopied: {
                        exportStatusMessage = "Export note copied."
                        exportStatusIsError = false
                    },
                    onEditNote: { noteEditorBatch = recentlyExportedBatch }
                )
            } else if let newestSuccessfulBatch {
                // No fresh export this session — still allow view/share of newest local batch.
                LocalExportNextStepActions(
                    batch: newestSuccessfulBatch,
                    onViewFiles: { filesViewerBatch = newestSuccessfulBatch },
                    onShare: { includeNote in
                        let caption = LocalExportShareSupport.shareCaption(
                            for: newestSuccessfulBatch,
                            includeNote: includeNote
                        )
                        shareBatchItem = ShareBatchItem(
                            urls: newestSuccessfulBatch.fileURLs,
                            caption: caption
                        )
                    },
                    onNoteCopied: {
                        exportStatusMessage = "Export note copied."
                        exportStatusIsError = false
                    },
                    onEditNote: { noteEditorBatch = newestSuccessfulBatch }
                )
            }
        } header: {
            Text("Export")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local JPEGs for manual upload. Does not publish to a marketplace.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var queueSection: some View {
        Section {
            Text(queueStatusLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)

            if isQueued {
                Button("Remove from Listing Queue", role: .destructive) {
                    removeFromQueue()
                }
            } else {
                Button("Add to Listing Queue") {
                    addToQueue()
                }
                .foregroundStyle(DarkroomTheme.accent)
            }

            if let queueActionMessage {
                Text(queueActionMessage)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
            }
        } header: {
            Text("Listing Queue")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var actionsSection: some View {
        Section {
            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                Text("Review / Edit Listing Details")
                    .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Actions")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private func validateReadiness() {
        refreshQueueReadiness()
        let issues = ListingQueueSupport.readinessIssues(for: project)
        if issues.isEmpty {
            validationMessage = "Ready — all Phase 25 requirements met."
        } else {
            validationMessage = "Not ready: " + issues.joined(separator: " · ")
        }
    }

    private func refreshQueueReadiness() {
        if let entry = queueEntry {
            ListingQueueSupport.syncReadiness(for: entry)
        }
    }

    private func addToQueue() {
        if ListingQueueSupport.add(project: project, in: modelContext) != nil {
            queueActionMessage = "Added to Listing Queue."
            validationMessage = nil
        } else {
            queueActionMessage = "Already in the Listing Queue."
        }
        refreshQueueReadiness()
    }

    private func removeFromQueue() {
        guard let entry = queueEntry else {
            queueActionMessage = "Not in the Listing Queue."
            return
        }
        ListingQueueSupport.remove(entry, in: modelContext)
        queueActionMessage = "Removed from Listing Queue."
        refreshQueueReadiness()
    }

    private func exportListingImages() async {
        guard !isExporting else { return }
        isExporting = true
        exportStatusMessage = nil
        exportStatusIsError = false
        recentlyExportedBatch = nil
        exportProgressCompleted = 0
        exportProgressTotal = project.photoCount
        defer { isExporting = false }

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

    private func createListingPackage() {
        do {
            let package = try ListingPackageSupport.createPackage(for: project)
            modelContext.insert(package)
            project.touchModified()
            packageStatusIsError = false
            packageStatusMessage = "Package created with \(package.photoCount) JPEG\(package.photoCount == 1 ? "" : "s") + listing-details.txt."
        } catch ListingPackageError.noSuccessfulExportBatch {
            packageStatusIsError = true
            packageStatusMessage = "No successful export yet. Use Export Photos first."
        } catch {
            packageStatusIsError = true
            packageStatusMessage = "Could not create listing package."
        }
    }

    private func deletePackage(_ package: ListingPackage) {
        LocalEditStore.deleteListingPackageFolder(folderName: package.packageFolderName)
        modelContext.delete(package)
        project.touchModified()
    }
}
