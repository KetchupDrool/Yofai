import SwiftUI
import SwiftData
import UIKit

struct EditView: View {
    let sourceImage: UIImage
    /// When set, loads/saves edit settings on this project photo (batch export uses them).
    var projectPhoto: ItemProjectPhoto? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var editState = PhotoEditState()
    @State private var undoStack: [PhotoEditState] = []
    @State private var previewSource: UIImage?
    @State private var previewImage: UIImage?
    @State private var isSaving = false
    @State private var isPreparingShare = false
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var edgeCropAmount: Double = 0
    @State private var didPushSliderUndo = false
    @State private var didPushWatermarkTextUndo = false
    @State private var shareItem: ShareFileItem?
    @State private var shareFileURLToCleanup: URL?
    @State private var showFreeformCrop = false
    @State private var cropCanvasImage: UIImage?
    @State private var previewRefreshTask: Task<Void, Never>?
    @State private var didLoadProjectEditState = false

    var body: some View {
        VStack(spacing: 0) {
            DarkroomCanvas {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                } else {
                    ProgressView("Preparing photo…")
                        .tint(DarkroomTheme.accent)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 4)

            ScrollView {
                VStack(spacing: 6) {
                    DarkroomSection(title: "Rotate", isCompact: true) {
                        HStack(spacing: 6) {
                            toolButton("Left", systemImage: "rotate.left") {
                                pushUndo()
                                editState.quarterTurns -= 1
                                commitChange()
                            }
                            toolButton("Right", systemImage: "rotate.right") {
                                pushUndo()
                                editState.quarterTurns += 1
                                commitChange()
                            }
                            toolButton("Undo", systemImage: "arrow.uturn.backward") {
                                undo()
                            }
                            .disabled(undoStack.isEmpty)
                            .opacity(undoStack.isEmpty ? 0.45 : 1)

                            toolButton("Reset", systemImage: "arrow.counterclockwise") {
                                resetEdits()
                            }
                            .disabled(!editState.hasEdits && undoStack.isEmpty)
                            .opacity((!editState.hasEdits && undoStack.isEmpty) ? 0.45 : 1)
                        }
                    }

                    DarkroomSection(title: "Filter", isCompact: true) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(PhotoFilter.allCases) { filter in
                                    Button {
                                        guard editState.filter != filter else { return }
                                        undoStack.append(editState)
                                        editState.filter = filter
                                        commitChange()
                                    } label: {
                                        DarkroomSelectableChip(
                                            title: filter.rawValue,
                                            isSelected: editState.filter == filter,
                                            isCompact: true
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(filter.rawValue)
                                    .accessibilityAddTraits(editState.filter == filter ? .isSelected : [])
                                }
                            }
                        }
                    }

                    DarkroomSection(title: "Crop", isCompact: true) {
                        HStack(spacing: 6) {
                            toolButton("Freeform", systemImage: "crop") {
                                openFreeformCrop()
                            }
                            toolButton("Square", systemImage: "square") {
                                pushUndo()
                                editState.cropRect = PhotoEditState.centerSquareCrop()
                                edgeCropAmount = 0
                                commitChange()
                            }
                            toolButton("Clear", systemImage: "xmark") {
                                guard editState.didCrop else { return }
                                pushUndo()
                                editState.cropRect = nil
                                edgeCropAmount = 0
                                commitChange()
                            }
                            .disabled(!editState.didCrop)
                            .opacity(editState.didCrop ? 1 : 0.45)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Edge crop")
                                .font(.caption2)
                                .foregroundStyle(DarkroomTheme.textSecondary)
                            Slider(value: $edgeCropAmount, in: 0...0.35, step: 0.01) { editing in
                                handleSliderEditing(editing) {
                                    applyEdgeCropFromSlider()
                                }
                            }
                            .tint(DarkroomTheme.accent)
                        }
                    }

                    DarkroomSection(title: "Adjust", isCompact: true) {
                        labeledSlider("Brightness", value: $editState.brightness, range: -0.5...0.5)
                        labeledSlider("Contrast", value: $editState.contrast, range: 0.5...1.5)
                        labeledSlider("Saturation", value: $editState.saturation, range: 0...2)
                    }

                    DarkroomSection(title: "Export", isCompact: true) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(ListingExportPreset.allCases) { preset in
                                    Button {
                                        guard editState.exportPreset != preset else { return }
                                        undoStack.append(editState)
                                        editState.exportPreset = preset
                                        commitChange()
                                    } label: {
                                        DarkroomSelectableChip(
                                            title: preset.shortLabel,
                                            isSelected: editState.exportPreset == preset,
                                            isCompact: true
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(preset.accessibilityLabel)
                                    .accessibilityAddTraits(editState.exportPreset == preset ? .isSelected : [])
                                }
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(ListingExportBackground.allCases) { background in
                                    Button {
                                        guard editState.exportBackground != background else { return }
                                        undoStack.append(editState)
                                        editState.exportBackground = background
                                        commitChange()
                                    } label: {
                                        DarkroomSelectableChip(
                                            title: background.rawValue,
                                            isSelected: editState.exportBackground == background,
                                            isCompact: true
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(background.rawValue)
                                    .accessibilityAddTraits(editState.exportBackground == background ? .isSelected : [])
                                }
                            }
                        }

                        Text(editState.listingSummary)
                            .font(.caption2)
                            .foregroundStyle(DarkroomTheme.textTertiary)

                        Text(ListingExportPreset.localExportDisclaimer)
                            .font(.caption2)
                            .foregroundStyle(DarkroomTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)

                        Toggle(isOn: Binding(
                            get: { editState.watermarkEnabled },
                            set: { newValue in
                                guard editState.watermarkEnabled != newValue else { return }
                                undoStack.append(editState)
                                editState.watermarkEnabled = newValue
                                commitChange()
                            }
                        )) {
                            Text("Watermark")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DarkroomTheme.textSecondary)
                        }
                        .tint(DarkroomTheme.accent)

                        if editState.watermarkEnabled {
                            TextField(
                                "Shop name",
                                text: Binding(
                                    get: { editState.watermarkText },
                                    set: { newValue in
                                        let clipped = String(newValue.prefix(PhotoEditState.watermarkMaxLength))
                                        guard clipped != editState.watermarkText else { return }
                                        if !didPushWatermarkTextUndo {
                                            undoStack.append(editState)
                                            didPushWatermarkTextUndo = true
                                        }
                                        editState.watermarkText = clipped
                                        clearStatus()
                                        schedulePreviewRefresh()
                                    }
                                )
                            )
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(DarkroomTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(DarkroomTheme.stroke, lineWidth: 1)
                            )
                            .onSubmit {
                                didPushWatermarkTextUndo = false
                                commitChange()
                            }
                            .onChange(of: editState.watermarkEnabled) { _, enabled in
                                if !enabled {
                                    didPushWatermarkTextUndo = false
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
            }
            .frame(maxHeight: 320)

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Button {
                        Task { await saveListingCopy() }
                    } label: {
                        DarkroomPrimaryButtonLabel(title: "Save Listing Copy", isLoading: isSaving)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving || isPreparingShare || previewImage == nil)
                    .opacity((isSaving || isPreparingShare || previewImage == nil) ? 0.5 : 1)

                    Button {
                        Task { await shareCurrentEdit() }
                    } label: {
                        DarkroomSecondaryButtonLabel(
                            title: "Share",
                            systemImage: "square.and.arrow.up",
                            isLoading: isPreparingShare
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving || isPreparingShare || previewImage == nil)
                    .opacity((isSaving || isPreparingShare || previewImage == nil) ? 0.5 : 1)
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusIsError ? DarkroomTheme.danger : DarkroomTheme.success)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(DarkroomTheme.background.opacity(0.001))
        }
        .darkroomScreen()
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            loadProjectEditStateIfNeeded()
            preparePreviewSourceIfNeeded()
            refreshPreview()
        }
        .onDisappear {
            persistProjectEditStateIfNeeded()
            previewRefreshTask?.cancel()
            previewRefreshTask = nil
            ShareExport.removeTemporaryFile(at: shareFileURLToCleanup)
            shareFileURLToCleanup = nil
            shareItem = nil
        }
        .sheet(item: $shareItem, onDismiss: {
            ShareExport.removeTemporaryFile(at: shareFileURLToCleanup)
            shareFileURLToCleanup = nil
            shareItem = nil
        }) { item in
            ActivityShareView(items: [item.url])
        }
        .fullScreenCover(isPresented: $showFreeformCrop, onDismiss: {
            cropCanvasImage = nil
        }) {
            if let cropCanvasImage {
                FreeformCropView(
                    image: cropCanvasImage,
                    initialNormalizedCrop: editState.cropRect,
                    onApply: { normalized in
                        applyFreeformCrop(normalized)
                    },
                    onCancel: {
                        showFreeformCrop = false
                    }
                )
            } else {
                NavigationStack {
                    ContentUnavailableView(
                        "Crop Unavailable",
                        systemImage: "crop",
                        description: Text(PhotoSaveError.cropFailed.localizedDescription)
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showFreeformCrop = false }
                        }
                    }
                }
            }
        }
    }

    private func toolButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DarkroomChipButtonLabel(title: title, systemImage: systemImage, isCompact: true)
        }
        .buttonStyle(.plain)
    }

    private func openFreeformCrop() {
        guard let canvas = ImageEditing.imageForCropping(
            source: sourceImage,
            quarterTurns: editState.quarterTurns
        ) else {
            statusMessage = PhotoSaveError.cropFailed.localizedDescription
            statusIsError = true
            return
        }
        cropCanvasImage = canvas
        showFreeformCrop = true
        clearStatus()
    }

    private func applyFreeformCrop(_ normalized: CGRect) {
        var testState = editState
        testState.cropRect = normalized
        preparePreviewSourceIfNeeded()
        let validationSource = previewSource ?? sourceImage
        guard ImageEditing.render(source: validationSource, state: testState) != nil else {
            statusMessage = PhotoSaveError.cropFailed.localizedDescription
            statusIsError = true
            showFreeformCrop = false
            return
        }
        pushUndo()
        editState.cropRect = ImageEditing.clampNormalizedCrop(normalized)
        edgeCropAmount = 0
        showFreeformCrop = false
        commitChange()
    }

    private func shareCurrentEdit() async {
        guard previewImage != nil else {
            statusMessage = "Image is not ready to share yet. Wait for the preview, then try again."
            statusIsError = true
            return
        }

        isPreparingShare = true
        clearStatus()
        defer { isPreparingShare = false }

        guard let fullImage = ImageEditing.render(source: sourceImage, state: editState) else {
            statusMessage = PhotoSaveError.renderFailed.localizedDescription
            statusIsError = true
            return
        }

        do {
            // Clear any previous temp file before opening a new sheet.
            ShareExport.removeTemporaryFile(at: shareFileURLToCleanup)
            shareFileURLToCleanup = nil
            shareItem = nil

            let url = try ShareExport.writeTemporaryJPEG(fullImage)
            shareFileURLToCleanup = url
            shareItem = ShareFileItem(url: url)
        } catch let error as PhotoSaveError {
            statusMessage = error.localizedDescription
            statusIsError = true
        } catch {
            statusMessage = PhotoSaveError.renderFailed.localizedDescription
            statusIsError = true
        }
    }

    private func labeledSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textSecondary)
            Slider(value: value, in: range) { editing in
                handleSliderEditing(editing) {
                    previewRefreshTask?.cancel()
                    commitChange()
                }
            }
            .tint(DarkroomTheme.accent)
            .onChange(of: value.wrappedValue) { _, _ in
                clearStatus()
                schedulePreviewRefresh()
            }
        }
    }

    private func handleSliderEditing(_ editing: Bool, onEnd: () -> Void) {
        if editing {
            if !didPushSliderUndo {
                pushUndo()
                didPushSliderUndo = true
            }
        } else {
            didPushSliderUndo = false
            onEnd()
        }
    }

    private func applyEdgeCropFromSlider() {
        if edgeCropAmount <= 0.001 {
            editState.cropRect = nil
        } else {
            editState.cropRect = PhotoEditState.edgeInsetCrop(amount: edgeCropAmount)
        }
        commitChange()
    }

    private func pushUndo() {
        undoStack.append(editState)
    }

    private func commitChange() {
        clearStatus()
        refreshPreview()
    }

    private func clearStatus() {
        statusMessage = nil
        statusIsError = false
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        editState = previous
        syncEdgeCropAmount(from: previous)
        didPushWatermarkTextUndo = false
        commitChange()
    }

    private func syncEdgeCropAmount(from state: PhotoEditState) {
        guard let crop = state.cropRect else {
            edgeCropAmount = 0
            return
        }
        let inset = max(0, min(crop.minX, crop.minY))
        let expected = PhotoEditState.edgeInsetCrop(amount: inset)
        if abs(expected.minX - crop.minX) < 0.02,
           abs(expected.width - crop.width) < 0.02 {
            edgeCropAmount = inset
        } else {
            edgeCropAmount = 0
        }
    }

    private func resetEdits() {
        if editState.hasEdits {
            pushUndo()
        }
        editState = PhotoEditState()
        edgeCropAmount = 0
        didPushWatermarkTextUndo = false
        commitChange()
    }

    private func preparePreviewSourceIfNeeded() {
        guard previewSource == nil else { return }
        previewSource = ImageEditing.downscaled(
            sourceImage,
            maxDimension: ImageEditing.previewMaxDimension
        )
    }

    private func schedulePreviewRefresh() {
        previewRefreshTask?.cancel()
        previewRefreshTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(40))
            guard !Task.isCancelled else { return }
            refreshPreview()
        }
    }

    private func refreshPreview() {
        preparePreviewSourceIfNeeded()
        // Preview uses a once-downscaled source + capped listing canvas; Save/Share use full size.
        let source = previewSource ?? sourceImage
        previewImage = ImageEditing.renderPreview(source: source, state: editState)
        if previewImage == nil {
            statusMessage = PhotoSaveError.renderFailed.localizedDescription
            statusIsError = true
        }
    }

    private func saveListingCopy() async {
        guard previewImage != nil else {
            statusMessage = PhotoSaveError.renderFailed.localizedDescription
            statusIsError = true
            return
        }

        isSaving = true
        statusMessage = nil
        defer { isSaving = false }

        guard let finalImage = ImageEditing.render(source: sourceImage, state: editState) else {
            statusMessage = PhotoSaveError.renderFailed.localizedDescription
            statusIsError = true
            return
        }

        do {
            try await ImageEditing.saveToPhotos(finalImage)
            let localFileName = try LocalEditStore.saveFullImage(finalImage)
            let record = SavedEdit(
                filterName: editState.filter.rawValue,
                quarterTurns: editState.quarterTurns,
                didCrop: editState.didCrop,
                adjustmentSummary: editState.adjustmentSummary,
                exportPresetName: editState.exportPreset.rawValue,
                exportBackgroundName: editState.exportBackground.rawValue,
                didWatermark: editState.willDrawWatermark,
                localFileName: localFileName,
                thumbnailData: SavedEdit.makeThumbnailData(from: finalImage)
            )
            modelContext.insert(record)
            persistProjectEditStateIfNeeded()
            statusMessage = "Saved listing-ready copy to Photos. Added to History."
            statusIsError = false
        } catch let error as PhotoSaveError {
            statusMessage = error.localizedDescription
            statusIsError = true
        } catch {
            statusMessage = PhotoSaveError.saveFailed.localizedDescription
            statusIsError = true
        }
    }

    private func loadProjectEditStateIfNeeded() {
        guard !didLoadProjectEditState, let projectPhoto else { return }
        if let saved = projectPhoto.savedEditState {
            editState = saved
        } else if let project = projectPhoto.project {
            editState = PhotoEditState().applyingProjectExportSettings(from: project)
        }
        syncEdgeCropAmount(from: editState)
        didLoadProjectEditState = true
    }

    private func persistProjectEditStateIfNeeded() {
        guard let projectPhoto else { return }
        projectPhoto.savedEditState = editState
    }
}

#Preview {
    NavigationStack {
        EditView(sourceImage: UIImage(systemName: "photo") ?? UIImage())
    }
    .modelContainer(for: SavedEdit.self, inMemory: true)
}
