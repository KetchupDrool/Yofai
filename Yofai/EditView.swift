import SwiftUI
import SwiftData
import UIKit

struct EditView: View {
    let sourceImage: UIImage

    @Environment(\.modelContext) private var modelContext
    @State private var editState = PhotoEditState()
    @State private var undoStack: [PhotoEditState] = []
    @State private var previewImage: UIImage?
    @State private var isSaving = false
    @State private var statusMessage: String?
    @State private var statusIsError = false
    @State private var edgeCropAmount: Double = 0
    @State private var didPushSliderUndo = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 12) {
            Group {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ProgressView("Preparing photo…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Button {
                            pushUndo()
                            editState.quarterTurns -= 1
                            commitChange()
                        } label: {
                            Label("Left", systemImage: "rotate.left")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            pushUndo()
                            editState.quarterTurns += 1
                            commitChange()
                        } label: {
                            Label("Right", systemImage: "rotate.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Picker("Filter", selection: $editState.filter) {
                        ForEach(PhotoFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: editState.filter) { oldValue, newValue in
                        guard oldValue != newValue else { return }
                        var previous = editState
                        previous.filter = oldValue
                        undoStack.append(previous)
                        commitChange()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Crop")
                            .font(.subheadline.weight(.semibold))

                        HStack(spacing: 10) {
                            Button("Square") {
                                pushUndo()
                                editState.cropRect = PhotoEditState.centerSquareCrop()
                                edgeCropAmount = 0
                                commitChange()
                            }
                            .buttonStyle(.bordered)

                            Button("Clear") {
                                guard editState.didCrop else { return }
                                pushUndo()
                                editState.cropRect = nil
                                edgeCropAmount = 0
                                commitChange()
                            }
                            .buttonStyle(.bordered)
                            .disabled(!editState.didCrop)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edge crop")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $edgeCropAmount, in: 0...0.35, step: 0.01) { editing in
                                handleSliderEditing(editing) {
                                    applyEdgeCropFromSlider()
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Adjust")
                            .font(.subheadline.weight(.semibold))

                        labeledSlider("Brightness", value: $editState.brightness, range: -0.5...0.5)
                        labeledSlider("Contrast", value: $editState.contrast, range: 0.5...1.5)
                        labeledSlider("Saturation", value: $editState.saturation, range: 0...2)
                    }

                    HStack(spacing: 10) {
                        Button {
                            undo()
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(undoStack.isEmpty)

                        Button {
                            resetEdits()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!editState.hasEdits && undoStack.isEmpty)
                    }

                    Button {
                        Task { await saveCopy() }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save Copy")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving || previewImage == nil)

                    Button {
                        shareCurrentPreview()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundStyle(statusIsError ? Color.red : Color.green)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 360)
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshPreview()
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            shareImage = nil
        }) {
            if let shareImage {
                ActivityShareView(items: [shareImage])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func shareCurrentPreview() {
        guard let previewImage else {
            statusMessage = "Image is not ready to share yet. Wait for the preview, then try again."
            statusIsError = true
            return
        }
        shareImage = previewImage
        showShareSheet = true
        clearStatus()
    }

    private func labeledSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: value, in: range) { editing in
                handleSliderEditing(editing) {
                    commitChange()
                }
            }
            .onChange(of: value.wrappedValue) { _, _ in
                clearStatus()
                refreshPreview()
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
        commitChange()
    }

    private func refreshPreview() {
        previewImage = ImageEditing.render(source: sourceImage, state: editState)
        if previewImage == nil {
            statusMessage = PhotoSaveError.renderFailed.localizedDescription
            statusIsError = true
        }
    }

    private func saveCopy() async {
        guard let previewImage else {
            statusMessage = PhotoSaveError.renderFailed.localizedDescription
            statusIsError = true
            return
        }

        isSaving = true
        statusMessage = nil
        defer { isSaving = false }

        do {
            try await ImageEditing.saveToPhotos(previewImage)
            let localFileName = try LocalEditStore.saveFullImage(previewImage)
            let record = SavedEdit(
                filterName: editState.filter.rawValue,
                quarterTurns: editState.quarterTurns,
                didCrop: editState.didCrop,
                adjustmentSummary: editState.adjustmentSummary,
                localFileName: localFileName,
                thumbnailData: SavedEdit.makeThumbnailData(from: previewImage)
            )
            modelContext.insert(record)
            statusMessage = "Saved a copy to Photos. Added to History."
            statusIsError = false
        } catch let error as PhotoSaveError {
            statusMessage = error.localizedDescription
            statusIsError = true
        } catch {
            statusMessage = PhotoSaveError.saveFailed.localizedDescription
            statusIsError = true
        }
    }
}

#Preview {
    NavigationStack {
        EditView(sourceImage: UIImage(systemName: "photo") ?? UIImage())
    }
    .modelContainer(for: SavedEdit.self, inMemory: true)
}
