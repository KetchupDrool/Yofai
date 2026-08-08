import SwiftUI
import SwiftData
import UIKit

struct EditView: View {
    let sourceImage: UIImage

    @Environment(\.modelContext) private var modelContext
    @State private var selectedFilter: PhotoFilter = .original
    @State private var quarterTurns = 0
    @State private var previewImage: UIImage?
    @State private var isSaving = false
    @State private var statusMessage: String?
    @State private var statusIsError = false

    private var hasEdits: Bool {
        selectedFilter != .original || (((quarterTurns % 4) + 4) % 4) != 0
    }

    var body: some View {
        VStack(spacing: 16) {
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

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        quarterTurns -= 1
                        clearStatus()
                        refreshPreview()
                    } label: {
                        Label("Left", systemImage: "rotate.left")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        quarterTurns += 1
                        clearStatus()
                        refreshPreview()
                    } label: {
                        Label("Right", systemImage: "rotate.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(PhotoFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedFilter) { _, _ in
                    clearStatus()
                    refreshPreview()
                }

                Button {
                    resetEdits()
                } label: {
                    Label("Reset to Original", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .disabled(!hasEdits)

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
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshPreview()
        }
    }

    private func clearStatus() {
        statusMessage = nil
        statusIsError = false
    }

    private func resetEdits() {
        selectedFilter = .original
        quarterTurns = 0
        clearStatus()
        refreshPreview()
    }

    private func refreshPreview() {
        previewImage = ImageEditing.render(
            source: sourceImage,
            filter: selectedFilter,
            quarterTurns: quarterTurns
        )
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
            let record = SavedEdit(
                filterName: selectedFilter.rawValue,
                quarterTurns: quarterTurns,
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
