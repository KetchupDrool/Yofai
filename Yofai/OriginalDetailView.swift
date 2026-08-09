import SwiftUI
import SwiftData
import UIKit

struct OriginalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let original: ImportedOriginal

    @State private var fullImage: UIImage?
    @State private var loadFailed = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

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
                    ProgressView("Loading original…")
                        .tint(DarkroomTheme.accent)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text("IMPORTED")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                Text(original.importedAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textPrimary)

                if loadFailed {
                    Text("Editing needs the local image file.")
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
                    showEdit = true
                } label: {
                    DarkroomPrimaryButtonLabel(title: "Edit Photo", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
                .disabled(fullImage == nil)
                .opacity(fullImage == nil ? 0.5 : 1)

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    DarkroomSecondaryButtonLabel(title: "Delete Original", isDestructive: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .darkroomScreen()
        .navigationTitle("Original")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            loadImage()
        }
        .navigationDestination(isPresented: $showEdit) {
            if let fullImage {
                EditView(sourceImage: fullImage)
            }
        }
        .confirmationDialog(
            "Delete this original from Yofai?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Original", role: .destructive) {
                deleteOriginal()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes the local original from Yofai only. Photos library copies stay.")
        }
    }

    private func loadImage() {
        if let image = original.fullLocalImage {
            fullImage = image
            loadFailed = false
        } else {
            fullImage = nil
            loadFailed = true
        }
    }

    private func deleteOriginal() {
        LocalEditStore.deleteOriginalFile(fileName: original.localFileName)
        modelContext.delete(original)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        OriginalDetailView(original: ImportedOriginal())
    }
    .modelContainer(originalPreviewContainer)
}

@MainActor
private let originalPreviewContainer: ModelContainer = {
    let schema = YofaiModelSchema.schema
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()
