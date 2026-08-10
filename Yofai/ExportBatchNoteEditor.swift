import SwiftUI

/// Phase 44 — add/edit/remove optional local export-batch note.
struct ExportBatchNoteEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var batch: ProjectExportBatch

    @State private var draft: String = ""
    @FocusState private var isFocused: Bool

    private var normalizedDraft: String {
        ExportBatchNoteSupport.normalized(draft)
    }

    private var canSave: Bool {
        normalizedDraft != ExportBatchNoteSupport.normalized(batch.sellerNote)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Export note",
                        text: Binding(
                            get: { draft },
                            set: { draft = String($0.prefix(ExportBatchNoteSupport.maxLength)) }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .focused($isFocused)
                    .foregroundStyle(DarkroomTheme.textPrimary)

                    Text("\(normalizedDraft.count)/\(ExportBatchNoteSupport.maxLength)")
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } header: {
                    Text("Export Note")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text("Local reminder only — not publish status and not a marketplace claim.")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }

                if batch.hasSellerNote || !normalizedDraft.isEmpty {
                    Section {
                        Button("Remove Note", role: .destructive) {
                            batch.setSellerNote("")
                            batch.project?.touchModified()
                            dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .darkroomScreen()
            .navigationTitle(batch.hasSellerNote ? "Edit Note" : "Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        batch.setSellerNote(draft)
                        batch.project?.touchModified()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFocused = false }
                }
            }
            .onAppear {
                draft = batch.sellerNote
                isFocused = true
            }
        }
    }
}
