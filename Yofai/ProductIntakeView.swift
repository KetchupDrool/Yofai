import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Local product intake + guided photo plan. Reuses existing project photo storage.
struct ProductIntakeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: ItemProject

    @State private var newGoalName = ""
    @State private var showCamera = false
    @State private var captureGoalID: PersistentIdentifier?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var goalToAttach: PhotoPlanGoal?
    @State private var photoForCheck: ItemProjectPhoto?

    var body: some View {
        List {
            progressSection
            quickActionsSection
            photoPlanSection
            photosSection
            reviewNeededSection
            exportCanvasNotesSection
            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(statusIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                }
                .listRowBackground(sectionBackground)
            }
        }
        .darkroomFormList()
        .darkroomScreen()
        .navigationTitle("Product Intake")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        .onAppear {
            PhotoPlanSupport.ensureStarterGoals(on: project, in: modelContext)
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await importPhotos(from: newItems) }
        }
        .sheet(isPresented: $showCamera) {
            ProjectCameraCaptureFlow(project: project, initialGoalID: captureGoalID)
        }
        .sheet(item: $goalToAttach) { goal in
            attachPhotoSheet(goal: goal)
        }
        .navigationDestination(item: $photoForCheck) { photo in
            PhotoCheckView(project: project, photo: photo)
        }
    }

    private var sectionBackground: some View {
        DarkroomListRowBackground()
    }

    private var completedGoalCount: Int {
        project.sortedPhotoPlanGoals.filter(\.isComplete).count
    }

    private var progressSection: some View {
        Section {
            Text("Photo plan \(completedGoalCount)/\(project.photoPlanGoals.count) marked complete")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
            Text("\(project.photoCount) project photo\(project.photoCount == 1 ? "" : "s") · \(PhotoPlanSupport.unattachedGoals(in: project).count) unattached goal\(PhotoPlanSupport.unattachedGoals(in: project).count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
            Text("\(PhotoPlanSupport.photosNeedingSellerReview(in: project).count) photo\(PhotoPlanSupport.photosNeedingSellerReview(in: project).count == 1 ? "" : "s") needing seller review")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
            let canvasNotes = PhotoTechnicalCheck.photosWithSourceSmallerThanExportCanvas(in: project).count
            Text("\(canvasNotes) photo\(canvasNotes == 1 ? "" : "s") smaller than export canvas or unreadable")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
            Text("Export canvas: \(project.listingExportPreset.pickerLabel)")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
            Text("Photo-plan goals are local guidance only — not Etsy requirements.")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Text("Progress")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var quickActionsSection: some View {
        Section {
            Button("Capture Photos") {
                captureGoalID = nil
                showCamera = true
            }
            .foregroundStyle(DarkroomTheme.accent)

            PhotosPicker(selection: $pickerItems, maxSelectionCount: 20, matching: .images) {
                Text(isImporting ? "Importing…" : "Import Existing Photo")
                    .foregroundStyle(DarkroomTheme.accent)
            }
            .disabled(isImporting)

            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                Text("Edit / Reorder Photos")
                    .foregroundStyle(DarkroomTheme.accent)
            }

            NavigationLink {
                ListingInformationView(project: project)
            } label: {
                Text("Listing Information")
                    .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Quick Actions")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var photoPlanSection: some View {
        Section {
            ForEach(project.sortedPhotoPlanGoals, id: \.persistentModelID) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Goal name", text: Binding(
                        get: { goal.name },
                        set: {
                            goal.name = $0
                            project.touchModified()
                        }
                    ))
                    .foregroundStyle(DarkroomTheme.textPrimary)

                    Toggle("Complete", isOn: Binding(
                        get: { goal.isComplete },
                        set: {
                            goal.isComplete = $0
                            project.touchModified()
                        }
                    ))

                    if let attachedID = goal.attachedPhotoStableID,
                       let photo = project.photos.first(where: { $0.stableID == attachedID }) {
                        Text("Attached: Photo \(photo.sortOrder + 1)")
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                        Button("Clear Attached Photo") {
                            PhotoPlanSupport.clearAttachment(on: goal)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.danger)
                    } else {
                        Text("No photo attached")
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textTertiary)
                        Button("Attach Existing Photo") {
                            goalToAttach = goal
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                        Button("Capture for This Goal") {
                            captureGoalID = goal.persistentModelID
                            showCamera = true
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                    }
                }
                .padding(.vertical, 4)
            }
            .onMove { source, destination in
                PhotoPlanSupport.moveGoals(project.sortedPhotoPlanGoals, from: source, to: destination)
            }
            .onDelete { offsets in
                let ordered = project.sortedPhotoPlanGoals
                for index in offsets {
                    modelContext.delete(ordered[index])
                }
                let remaining = project.sortedPhotoPlanGoals
                for (index, goal) in remaining.enumerated() {
                    goal.sortOrder = index
                }
                project.touchModified()
            }

            HStack {
                TextField("New goal name", text: $newGoalName)
                Button("Add") {
                    let trimmed = newGoalName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    PhotoPlanSupport.addGoal(named: trimmed, to: project, in: modelContext)
                    newGoalName = ""
                }
                .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Guided Photo Plan")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("A project photo may attach to at most one goal. Clearing an attachment does not delete the photo.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var photosSection: some View {
        Section {
            if project.sortedPhotos.isEmpty {
                Text("No project photos yet.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                ForEach(project.sortedPhotos, id: \.stableID) { photo in
                    HStack(spacing: 10) {
                        if let thumb = photo.thumbnailImage {
                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Photo \(photo.sortOrder + 1)")
                                .foregroundStyle(DarkroomTheme.textPrimary)
                            if let goal = PhotoPlanSupport.goal(attachedTo: photo, in: project) {
                                Text("Goal: \(goal.name)")
                                    .font(.caption)
                                    .foregroundStyle(DarkroomTheme.textSecondary)
                            } else {
                                Text("Unattached")
                                    .font(.caption)
                                    .foregroundStyle(DarkroomTheme.textTertiary)
                            }
                        }
                        Spacer()
                        Button("Check") {
                            photoForCheck = photo
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                    }
                }
            }
        } header: {
            Text("Current Photo Order")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var reviewNeededSection: some View {
        Section {
            let needing = PhotoPlanSupport.photosNeedingSellerReview(in: project)
            if needing.isEmpty {
                Text("All photos have seller review checkboxes checked.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                ForEach(needing, id: \.stableID) { photo in
                    Button("Review Photo \(photo.sortOrder + 1)") {
                        photoForCheck = photo
                    }
                    .foregroundStyle(DarkroomTheme.accent)
                }
            }
        } header: {
            Text("Photos Needing Seller Review")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Seller review checkboxes are local only and never affect queue readiness.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var exportCanvasNotesSection: some View {
        Section {
            let smaller = PhotoTechnicalCheck.photosWithSourceSmallerThanExportCanvas(in: project)
            let aspect = PhotoTechnicalCheck.photosWithAspectDifferingFromExportCanvas(in: project)
            Text("Project export canvas: \(project.listingExportPreset.pickerLabel)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
            Text("Fit: \(project.listingExportFitMode.displayTitle) — \(project.listingExportFitMode.sellerExplanation)")
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if smaller.isEmpty && aspect.isEmpty {
                Text("No export-canvas size or aspect notes for readable photos.")
                    .foregroundStyle(DarkroomTheme.textSecondary)
            } else {
                if !smaller.isEmpty {
                    Text("\(smaller.count) photo\(smaller.count == 1 ? "" : "s") smaller than canvas or unreadable")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    ForEach(smaller, id: \.stableID) { photo in
                        Button("Check Photo \(photo.sortOrder + 1)") {
                            photoForCheck = photo
                        }
                        .foregroundStyle(DarkroomTheme.accent)
                    }
                }
                if !aspect.isEmpty {
                    Text("\(aspect.count) photo\(aspect.count == 1 ? "" : "s") with aspect different from canvas (padding expected)")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    ForEach(aspect, id: \.stableID) { photo in
                        Button("Check Photo \(photo.sortOrder + 1)") {
                            photoForCheck = photo
                        }
                        .foregroundStyle(DarkroomTheme.accent)
                    }
                }
            }
        } header: {
            Text("Export Canvas Notes")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Compares source file pixels to the project listing export preset. Local facts only — not marketplace compliance. Does not change queue readiness.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private func attachPhotoSheet(goal: PhotoPlanGoal) -> some View {
        NavigationStack {
            List {
                ForEach(project.sortedPhotos, id: \.stableID) { photo in
                    Button {
                        do {
                            try PhotoPlanSupport.attach(photo: photo, to: goal, project: project)
                            try? modelContext.save()
                            goalToAttach = nil
                            statusIsError = false
                            statusMessage = "Attached Photo \(photo.sortOrder + 1) to \(goal.name)."
                        } catch {
                            statusIsError = true
                            statusMessage = (error as? LocalizedError)?.errorDescription ?? "Could not attach photo."
                            goalToAttach = nil
                        }
                    } label: {
                        HStack {
                            Text("Photo \(photo.sortOrder + 1)")
                            Spacer()
                            if PhotoPlanSupport.goal(attachedTo: photo, in: project) != nil {
                                Text("Already attached")
                                    .font(.caption)
                                    .foregroundStyle(DarkroomTheme.textTertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Attach Photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { goalToAttach = nil }
                }
            }
        }
    }

    private func importPhotos(from items: [PhotosPickerItem]) async {
        isImporting = true
        defer {
            isImporting = false
            pickerItems = []
        }
        do {
            var nextOrder = (project.photos.map(\.sortOrder).max() ?? -1) + 1
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
            statusIsError = false
            statusMessage = "Imported photos appended to this project."
        } catch {
            statusIsError = true
            statusMessage = (error as? LocalizedError)?.errorDescription ?? "Import failed."
        }
    }
}

extension PhotoPlanGoal: Hashable {
    static func == (lhs: PhotoPlanGoal, rhs: PhotoPlanGoal) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }
}

extension ItemProjectPhoto: Hashable {
    static func == (lhs: ItemProjectPhoto, rhs: ItemProjectPhoto) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }
}

struct PhotoCheckView: View {
    @Bindable var project: ItemProject
    @Bindable var photo: ItemProjectPhoto

    var body: some View {
        let facts = PhotoTechnicalCheck.facts(for: photo, project: project)
        List {
            Section {
                labeled("Pixel size", facts.pixelWidth.flatMap { w in facts.pixelHeight.map { "\(w) × \($0)" } } ?? "Unavailable")
                labeled("Orientation", facts.orientationDescription)
                labeled("File present", facts.filePresent ? "Yes" : "No")
                labeled("File readable", facts.fileReadable ? "Yes" : "No")
                labeled("Saved edit", facts.hasSavedEdit ? "Yes" : "No")
                labeled("Alt text", {
                    switch facts.altTextStatus {
                    case .present: return "Present"
                    case .notApplicable: return "Not Applicable"
                    case .missing: return "Missing"
                    }
                }())
                labeled("Photo-plan goal", facts.attachedGoalName ?? "None")
            } header: {
                Text("Photo Check (Local Facts)")
            } footer: {
                Text("These are measurable local facts only. This screen does not claim quality, Etsy compliance, or publish readiness.")
            }

            Section {
                labeled("Export canvas", facts.exportCanvasPreset.pickerLabel)
                labeled("Fit mode", "\(facts.exportFitMode.displayTitle) — \(facts.exportFitMode.sellerExplanation)")
                labeled(
                    "Source vs canvas size",
                    {
                        switch facts.sourceSmallerThanExportCanvas {
                        case true: return "Source file is smaller than canvas on at least one side"
                        case false: return "Source file meets or exceeds canvas on both sides"
                        case nil: return "Unavailable"
                        }
                    }()
                )
                labeled(
                    "Aspect vs canvas",
                    {
                        switch facts.sourceAspectDiffersFromCanvas {
                        case true: return "Differs"
                        case false: return "Matches (within tolerance)"
                        case nil: return "Unavailable"
                        }
                    }()
                )
                labeled("Framing expectation", facts.framingExpectation ?? "Unavailable")
                if facts.exportFitMode == .fillCrop {
                    labeled(
                        "Crop position",
                        {
                            switch facts.fillCropPositionAdjusted {
                            case true: return "Adjusted"
                            case false: return "Centered"
                            case nil: return "Unavailable"
                            }
                        }()
                    )
                }
            } header: {
                Text("Export Canvas (Local)")
            } footer: {
                Text("Compares source file pixels to this project’s listing export preset (\(facts.exportCanvasPreset.pixelSizeLabel)) and fit mode. Local facts only — not marketplace compliance. Does not change queue readiness.")
            }

            Section {
                Toggle("Product is clearly visible", isOn: $photo.reviewProductClearlyVisible)
                Toggle("Background is acceptable", isOn: $photo.reviewBackgroundAcceptable)
                Toggle("Color is accurate", isOn: $photo.reviewColorAccurate)
                Toggle("No private information is visible", isOn: $photo.reviewNoPrivateInfoVisible)
            } header: {
                Text("Seller Review")
            } footer: {
                Text("Local seller review only. Does not change Phase 25 queue readiness.")
            }

            Section {
                if LocalEditStore.projectFileExists(fileName: photo.localFileName) {
                    NavigationLink {
                        ProjectPhotoEditDestination(photo: photo)
                    } label: {
                        Text("Open Edit")
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                } else {
                    Text("Edit unavailable — file missing.")
                        .foregroundStyle(DarkroomTheme.danger)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .darkroomScreen()
        .navigationTitle("Photo \(photo.sortOrder + 1)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photo.reviewProductClearlyVisible) { _, _ in project.touchModified() }
        .onChange(of: photo.reviewBackgroundAcceptable) { _, _ in project.touchModified() }
        .onChange(of: photo.reviewColorAccurate) { _, _ in project.touchModified() }
        .onChange(of: photo.reviewNoPrivateInfoVisible) { _, _ in project.touchModified() }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
            Text(value)
                .foregroundStyle(DarkroomTheme.textPrimary)
        }
        .padding(.vertical, 2)
    }
}
