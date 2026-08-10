import SwiftUI
import UIKit

/// Phase 47 — read-only preview of one export batch’s local JPEGs. No editing or file management.
struct ExportedFilesViewer: View {
    let batch: ProjectExportBatch
    var onShare: ((Bool) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var previewFile: ExportBatchFileAccessSupport.ResolvedFile?
    @State private var noteCopiedMessage: String?

    private var files: [ExportBatchFileAccessSupport.ResolvedFile] {
        ExportBatchFileAccessSupport.resolvedFiles(for: batch)
    }

    private var canShare: Bool {
        ExportBatchFileAccessSupport.canShare(batch)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(LocalExportShareSupport.packageSummaryLine(for: batch))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("\(batch.exportedForLine). \(LocalExportShareSupport.packageSummaryLine(for: batch))")

                    Text(batch.historySecondaryLine)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let noteLine = batch.historyNoteLine {
                        Text(noteLine)
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(LocalExportShareSupport.manualUploadLabel)
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }

                Section {
                    if files.isEmpty {
                        Text(ExportBatchFileAccessSupport.filesUnavailableMessage)
                            .font(.subheadline)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(ExportBatchFileAccessSupport.filesUnavailableMessage)
                    } else {
                        ForEach(files) { file in
                            Button {
                                guard file.isAvailable else { return }
                                previewFile = file
                            } label: {
                                fileRow(file)
                            }
                            .disabled(!file.isAvailable)
                            .accessibilityLabel(
                                ExportBatchFileAccessSupport.accessibilityLabel(
                                    for: file,
                                    canvasLabel: batch.pixelSizeLabel
                                )
                            )
                        }

                        if let message = ExportBatchFileAccessSupport.availabilityMessage(for: batch) {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(DarkroomTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if case .partial(let available, let expected) = ExportBatchFileAccessSupport.availability(for: batch) {
                            Text("\(available) of \(expected) local JPEGs available")
                                .font(.caption)
                                .foregroundStyle(DarkroomTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } header: {
                    Text(ExportBatchFileAccessSupport.exportedFilesTitle)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }

                if canShare || batch.hasSellerNote {
                    Section {
                        if canShare, let onShare {
                            Button(LocalExportShareSupport.shareExportedPhotosTitle) {
                                onShare(false)
                            }
                            .accessibilityLabel(LocalExportShareSupport.shareExportedPhotosTitle)

                            if ExportBatchFileAccessSupport.canOfferShareWithNote(batch) {
                                Button(LocalExportShareSupport.shareWithNoteTitle) {
                                    onShare(true)
                                }
                                .accessibilityLabel(LocalExportShareSupport.shareWithNoteTitle)
                            }
                        }

                        if ExportBatchFileAccessSupport.canOfferCopyNote(batch) {
                            Button(LocalExportShareSupport.copyExportNoteTitle) {
                                if let text = LocalExportShareSupport.copyableNoteText(for: batch) {
                                    UIPasteboard.general.string = text
                                    noteCopiedMessage = "Export note copied."
                                }
                            }
                            .accessibilityLabel(LocalExportShareSupport.copyExportNoteTitle)
                        }

                        if let noteCopiedMessage {
                            Text(noteCopiedMessage)
                                .font(.caption2)
                                .foregroundStyle(DarkroomTheme.accent)
                                .accessibilityLabel(noteCopiedMessage)
                        }
                    }
                }
            }
            .navigationTitle(ExportBatchFileAccessSupport.exportedFilesTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $previewFile) { file in
                ExportedFilePreviewSheet(file: file, canvasLabel: batch.pixelSizeLabel)
            }
        }
    }

    private func fileRow(_ file: ExportBatchFileAccessSupport.ResolvedFile) -> some View {
        HStack(spacing: 12) {
            thumbnail(for: file)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(file.fileName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if file.isAvailable {
                    Text("\(batch.pixelSizeLabel) · \(LocalExportShareSupport.localJPEGsLabel)")
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(ExportBatchFileAccessSupport.fileUnavailableShort)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
            }
            Spacer(minLength: 0)
            if file.isAvailable {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func thumbnail(for file: ExportBatchFileAccessSupport.ResolvedFile) -> some View {
        if let url = file.url,
           let image = ExportBatchFileAccessSupport.loadPreviewImage(at: url) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                DarkroomTheme.surfaceRaised
                Image(systemName: "photo")
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
        }
    }
}

private struct ExportedFilePreviewSheet: View {
    let file: ExportBatchFileAccessSupport.ResolvedFile
    let canvasLabel: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let url = file.url,
                   let image = ExportBatchFileAccessSupport.loadPreviewImage(at: url) {
                    ScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .accessibilityLabel("\(file.fileName), \(canvasLabel), Local JPEG preview")
                } else {
                    ContentUnavailableView(
                        ExportBatchFileAccessSupport.cantPreviewMessage,
                        systemImage: "photo",
                        description: Text(ExportBatchFileAccessSupport.fileUnavailableShort)
                    )
                }
            }
            .navigationTitle(file.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
