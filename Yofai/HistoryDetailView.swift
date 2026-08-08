import SwiftUI
import SwiftData
import UIKit

struct HistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let edit: SavedEdit

    @State private var fullImage: UIImage?
    @State private var loadFailed = false
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false
    @State private var showEditAgain = false

    var body: some View {
        VStack(spacing: 16) {
            Group {
                if let fullImage {
                    Image(uiImage: fullImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if loadFailed {
                    ContentUnavailableView(
                        "Image Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(PhotoSaveError.missingLocalFile.localizedDescription)
                    )
                } else {
                    ProgressView("Loading saved image…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(edit.savedAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.headline)
                Text("Filter: \(edit.filterName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Rotation: \(edit.rotationDegrees)° · Crop: \(edit.didCrop ? "Yes" : "No")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Adjust: \(edit.adjustmentSummary)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if loadFailed {
                    Text("Edit Again needs the full local image file.")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                Button {
                    showEditAgain = true
                } label: {
                    Label("Edit Again", systemImage: "slider.horizontal.3")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(fullImage == nil)

                Button {
                    shareSavedImage()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .disabled(fullImage == nil)

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete History")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .navigationTitle("Saved Edit")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadImage()
        }
        .navigationDestination(isPresented: $showEditAgain) {
            if let fullImage {
                EditView(sourceImage: fullImage)
            }
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            shareImage = nil
        }) {
            if let shareImage {
                ActivityShareView(items: [shareImage])
                    .presentationDetents([.medium, .large])
            }
        }
        .confirmationDialog(
            "Delete this History item?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete History", role: .destructive) {
                deleteHistoryItem()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes the app History entry and local file. Your Photos library copy stays.")
        }
    }

    private func loadImage() {
        if let image = edit.fullLocalImage {
            fullImage = image
            loadFailed = false
        } else {
            fullImage = nil
            loadFailed = true
        }
    }

    private func shareSavedImage() {
        guard let fullImage else {
            loadFailed = true
            return
        }
        shareImage = fullImage
        showShareSheet = true
    }

    private func deleteHistoryItem() {
        LocalEditStore.deleteFile(fileName: edit.localFileName)
        modelContext.delete(edit)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        HistoryDetailView(
            edit: SavedEdit(filterName: "Original", quarterTurns: 0)
        )
    }
    .modelContainer(for: SavedEdit.self, inMemory: true)
}
