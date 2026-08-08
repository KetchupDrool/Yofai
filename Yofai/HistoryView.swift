import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedEdit.savedAt, order: .reverse) private var savedEdits: [SavedEdit]

    var body: some View {
        NavigationStack {
            Group {
                if savedEdits.isEmpty {
                    ContentUnavailableView(
                        "No saved edits yet.",
                        systemImage: "clock",
                        description: Text("Save a copy from Edit to see it here. Photos stay in your library; this list is only app history.")
                    )
                    .padding(.horizontal, 20)
                } else {
                    List {
                        ForEach(savedEdits) { edit in
                            NavigationLink {
                                HistoryDetailView(edit: edit)
                            } label: {
                                HistoryRow(edit: edit)
                            }
                        }
                        .onDelete(perform: deleteEdits)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !savedEdits.isEmpty {
                    EditButton()
                }
            }
        }
    }

    private func deleteEdits(at offsets: IndexSet) {
        for index in offsets {
            let edit = savedEdits[index]
            LocalEditStore.deleteFile(fileName: edit.localFileName)
            modelContext.delete(edit)
        }
    }
}

private struct HistoryRow: View {
    let edit: SavedEdit

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let thumbnail = edit.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 64, height: 64)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
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
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: SavedEdit.self, inMemory: true)
}
