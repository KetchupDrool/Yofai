import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedEdit.savedAt, order: .reverse) private var savedEdits: [SavedEdit]

    var body: some View {
        NavigationStack {
            Group {
                if savedEdits.isEmpty {
                    ScrollView {
                        DarkroomEmptyPanel(
                            title: "No Saved Edits Yet",
                            systemImage: "clock",
                            message: "Tap Save Listing Copy on Edit to add history. App files only — Photos stays untouched."
                        )
                        .padding(.top, 40)
                    }
                } else {
                    List {
                        ForEach(savedEdits) { edit in
                            NavigationLink {
                                HistoryDetailView(edit: edit)
                            } label: {
                                DarkroomThumbRow(
                                    thumbnail: edit.thumbnailImage,
                                    title: edit.savedAt.formatted(.dateTime.month().day().year().hour().minute()),
                                    subtitle: edit.listingSummary
                                        ?? "\(edit.filterName) · \(edit.rotationDegrees)° · Crop \(edit.didCrop ? "Yes" : "No")",
                                    detail: edit.listingSummary == nil
                                        ? (edit.adjustmentSummary == "None" ? nil : edit.adjustmentSummary)
                                        : "\(edit.filterName) · \(edit.rotationDegrees)°",
                                    showsChevron: true,
                                    isCompact: true
                                )
                            }
                            .buttonStyle(.plain)
                            .navigationLinkIndicatorVisibility(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteEdits)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .darkroomScreen()
            .navigationTitle("History")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

#Preview {
    HistoryView()
        .modelContainer(for: SavedEdit.self, inMemory: true)
}
