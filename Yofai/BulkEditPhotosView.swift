import SwiftUI
import SwiftData

struct BulkEditPhotosView: View {
    @Bindable var project: ItemProject

    @State private var sourcePhotoID: PersistentIdentifier?
    @State private var selectedTargetIDs: Set<PersistentIdentifier> = []
    @State private var includedSettings: Set<BulkEditSetting> = BulkEditSetting.allSelectable
    @State private var statusMessage: String?
    @State private var statusIsError = false

    private var photos: [ItemProjectPhoto] {
        project.sortedPhotos
    }

    private var sourcePhoto: ItemProjectPhoto? {
        photos.first { $0.persistentModelID == sourcePhotoID }
    }

    private var targetPhotos: [ItemProjectPhoto] {
        photos.filter { selectedTargetIDs.contains($0.persistentModelID) && $0.persistentModelID != sourcePhotoID }
    }

    private var sourceState: PhotoEditState {
        sourcePhoto?.savedEditState ?? PhotoEditState()
    }

    var body: some View {
        List {
            Section {
                Text("Copy edit settings from one photo to others. Source image files are never overwritten. History is not updated.")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
            }
            .listRowBackground(sectionBackground)

            Section {
                ForEach(photos) { photo in
                    Button {
                        sourcePhotoID = photo.persistentModelID
                        selectedTargetIDs.remove(photo.persistentModelID)
                    } label: {
                        photoRow(photo, trailing: sourcePhotoID == photo.persistentModelID ? "Source" : nil)
                    }
                }
            } header: {
                Text("Source Photo")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            .listRowBackground(sectionBackground)

            Section {
                ForEach(photos.filter { $0.persistentModelID != sourcePhotoID }) { photo in
                    Button {
                        toggleTarget(photo.persistentModelID)
                    } label: {
                        photoRow(
                            photo,
                            trailing: selectedTargetIDs.contains(photo.persistentModelID) ? "Selected" : "Tap to select"
                        )
                    }
                }
            } header: {
                Text("Target Photos")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            .listRowBackground(sectionBackground)

            Section {
                ForEach(BulkEditSetting.allCases) { setting in
                    Toggle(setting.displayName, isOn: Binding(
                        get: { includedSettings.contains(setting) },
                        set: { enabled in
                            if enabled {
                                includedSettings.insert(setting)
                            } else {
                                includedSettings.remove(setting)
                            }
                        }
                    ))
                    .tint(DarkroomTheme.accent)
                }
            } header: {
                Text("Settings to Copy")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            } footer: {
                Text("Turn off any setting to leave it unchanged on target photos.")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            .listRowBackground(sectionBackground)

            Section {
                if let sourcePhoto {
                    Text("Source: Photo \(sourcePhoto.sortOrder + 1)")
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Text("Targets: \(targetPhotos.count)")
                        .foregroundStyle(DarkroomTheme.textSecondary)
                    ForEach(BulkEditSupport.recipeSummary(state: sourceState, including: includedSettings), id: \.self) { line in
                        Text("• \(line)")
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                    }
                } else {
                    Text("Select a source photo to preview the recipe.")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                }

                Button("Apply Bulk Edit") {
                    applyBulkEdit()
                }
                .disabled(sourcePhoto == nil || targetPhotos.isEmpty || includedSettings.isEmpty)
                .foregroundStyle(DarkroomTheme.accent)

                Button("Undo Last Bulk Edit") {
                    undoBulkEdit()
                }
                .disabled(!BulkEditSupport.canUndo(project: project))
                .foregroundStyle(DarkroomTheme.danger)

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusIsError ? DarkroomTheme.danger : DarkroomTheme.accent)
                }
            } header: {
                Text("Confirm")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            .listRowBackground(sectionBackground)
        }
        .darkroomFormList()
        .darkroomScreen()
        .navigationTitle("Bulk Edit Photos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if sourcePhotoID == nil {
                sourcePhotoID = photos.first?.persistentModelID
            }
        }
    }

    private var sectionBackground: some View {
        DarkroomListRowBackground()
    }

    private func photoRow(_ photo: ItemProjectPhoto, trailing: String?) -> some View {
        HStack(spacing: 10) {
            if let thumb = photo.thumbnailImage {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .frame(width: 44, height: 44)
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Photo \(photo.sortOrder + 1)")
                    .foregroundStyle(DarkroomTheme.textPrimary)
                Text(photo.savedEditState == nil ? "No saved edits" : "Has saved edits")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
            }
        }
    }

    private func toggleTarget(_ id: PersistentIdentifier) {
        if selectedTargetIDs.contains(id) {
            selectedTargetIDs.remove(id)
        } else {
            selectedTargetIDs.insert(id)
        }
    }

    private func applyBulkEdit() {
        guard let sourcePhoto else { return }
        let count = BulkEditSupport.apply(
            sourcePhoto: sourcePhoto,
            targetPhotos: targetPhotos,
            including: includedSettings,
            on: project
        )
        statusIsError = false
        statusMessage = "Applied to \(count) photo\(count == 1 ? "" : "s"). No History entries created."
    }

    private func undoBulkEdit() {
        let count = BulkEditSupport.undoLastBulkEdit(on: project)
        statusIsError = count == 0
        statusMessage = count == 0
            ? "Nothing to undo."
            : "Restored previous edits on \(count) photo\(count == 1 ? "" : "s")."
    }
}
