import SwiftUI
import PhotosUI
import UIKit

struct ImportView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    @State private var showEdit = false
    @State private var loadError: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Group {
                if isLoading {
                    ProgressView("Loading photo…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let selectedUIImage {
                    Image(uiImage: selectedUIImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ContentUnavailableView(
                        "Choose a Photo",
                        systemImage: "photo.on.rectangle",
                        description: Text("Pick an image from your library to rotate, filter, and save a copy.")
                    )
                }
            }
            .padding(.horizontal, 20)

            if let loadError {
                Text(loadError)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(
                        selectedUIImage == nil ? "Choose Photo" : "Choose Different Photo",
                        systemImage: "photo.on.rectangle"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                if selectedUIImage != nil {
                    Button {
                        showEdit = true
                    } label: {
                        Text("Edit Photo")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
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
        } catch {
            selectedUIImage = nil
            loadError = PhotoSaveError.loadFailed.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
}
