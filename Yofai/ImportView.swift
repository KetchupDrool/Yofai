import SwiftUI
import PhotosUI
import SwiftData
import UIKit

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    @State private var showEdit = false
    @State private var loadError: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 14) {
            DarkroomCanvas {
                if isLoading {
                    ProgressView("Loading photo…")
                        .tint(DarkroomTheme.accent)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                } else if let selectedUIImage {
                    Image(uiImage: selectedUIImage)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                } else {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [DarkroomTheme.accent.opacity(0.35), Color.clear],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 44
                                    )
                                )
                                .frame(width: 88, height: 88)
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(DarkroomTheme.accent)
                        }
                        Text("Choose a Photo")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DarkroomTheme.textPrimary)
                        Text("Pick a photo to edit. Yofai keeps a local original on this device.")
                            .font(.subheadline)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                }
            }
            .padding(.horizontal, 12)

            if let loadError {
                Text(loadError)
                    .font(.subheadline)
                    .foregroundStyle(DarkroomTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            VStack(spacing: 10) {
                let chooseTitle = selectedUIImage == nil ? "Choose Photo" : "Choose Different Photo"
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    DarkroomPrimaryButtonLabel(
                        title: chooseTitle,
                        systemImage: "photo.on.rectangle"
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                if selectedUIImage != nil {
                    Button {
                        showEdit = true
                    } label: {
                        DarkroomSecondaryButtonLabel(title: "Edit Photo", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .darkroomScreen()
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $showEdit) {
            if let selectedUIImage {
                EditView(sourceImage: selectedUIImage)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadImage(from: newItem)
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else {
            selectedUIImage = nil
            loadError = nil
            return
        }

        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                selectedUIImage = nil
                loadError = PhotoSaveError.loadFailed.localizedDescription
                return
            }
            selectedUIImage = uiImage
            try saveImportedOriginal(uiImage)
        } catch let error as PhotoSaveError {
            // Still allow editing this session if local library save fails.
            loadError = error.localizedDescription
        } catch {
            selectedUIImage = nil
            loadError = PhotoSaveError.loadFailed.localizedDescription
        }
    }

    private func saveImportedOriginal(_ image: UIImage) throws {
        let fileName = try LocalEditStore.saveOriginalImage(image)
        let record = ImportedOriginal(
            localFileName: fileName,
            thumbnailData: SavedEdit.makeThumbnailData(from: image)
        )
        modelContext.insert(record)
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
    .modelContainer(importPreviewContainer)
}

@MainActor
private let importPreviewContainer: ModelContainer = {
    let schema = YofaiModelSchema.schema
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()
