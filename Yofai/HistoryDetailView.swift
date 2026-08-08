import SwiftUI
import SwiftData
import UIKit

struct HistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let edit: SavedEdit

    @State private var fullImage: UIImage?
    @State private var loadFailed = false
    @State private var shareItem: ShareFileItem?
    @State private var shareFileURLToCleanup: URL?
    @State private var showDeleteConfirm = false
    @State private var showEditAgain = false

    var body: some View {
        VStack(spacing: 12) {
            DarkroomCanvas {
                if let fullImage {
                    Image(uiImage: fullImage)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else if loadFailed {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(DarkroomTheme.danger)
                        Text("Image Unavailable")
                            .font(.headline)
                            .foregroundStyle(DarkroomTheme.textPrimary)
                        Text(PhotoSaveError.missingLocalFile.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                } else {
                    ProgressView("Loading saved image…")
                        .tint(DarkroomTheme.accent)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text("SAVED")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                Text(edit.savedAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                Text("\(edit.filterName) · \(edit.rotationDegrees)° · Crop \(edit.didCrop ? "Yes" : "No")")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                if let listingSummary = edit.listingSummary {
                    Text(listingSummary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent.opacity(0.9))
                }
                if let watermarkSummary = edit.watermarkSummary {
                    Text(watermarkSummary)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }
                if edit.adjustmentSummary != "None" {
                    Text(edit.adjustmentSummary)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }

                if loadFailed {
                    Text("Edit Again needs the local image file.")
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassPanel()
            .padding(.horizontal, 12)

            VStack(spacing: 10) {
                Button {
                    showEditAgain = true
                } label: {
                    DarkroomPrimaryButtonLabel(title: "Edit Again", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
                .disabled(fullImage == nil)
                .opacity(fullImage == nil ? 0.5 : 1)

                Button {
                    shareSavedImage()
                } label: {
                    DarkroomSecondaryButtonLabel(title: "Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .disabled(fullImage == nil)
                .opacity(fullImage == nil ? 0.5 : 1)

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    DarkroomSecondaryButtonLabel(title: "Delete History", isDestructive: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .darkroomScreen()
        .navigationTitle("Saved Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            loadImage()
        }
        .navigationDestination(isPresented: $showEditAgain) {
            if let fullImage {
                EditView(sourceImage: fullImage)
            }
        }
        .sheet(item: $shareItem, onDismiss: {
            ShareExport.removeTemporaryFile(at: shareFileURLToCleanup)
            shareFileURLToCleanup = nil
            shareItem = nil
        }) { item in
            ActivityShareView(items: [item.url])
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
            Text("Removes this History item and its local file. The Photos library copy stays.")
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
        do {
            ShareExport.removeTemporaryFile(at: shareFileURLToCleanup)
            shareFileURLToCleanup = nil
            shareItem = nil

            let url = try ShareExport.writeTemporaryJPEG(fullImage)
            shareFileURLToCleanup = url
            shareItem = ShareFileItem(url: url)
        } catch {
            loadFailed = true
        }
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
