import SwiftUI
import SwiftData

struct OriginalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImportedOriginal.importedAt, order: .reverse) private var originals: [ImportedOriginal]

    var body: some View {
        NavigationStack {
            Group {
                if originals.isEmpty {
                    ScrollView {
                        DarkroomEmptyPanel(
                            title: "No Originals Yet",
                            systemImage: "photo.on.rectangle",
                            message: "Originals are a secondary library for single-photo imports. Prefer Start Product on Home for listing photo sets. Photos library is not changed."
                        )
                        .padding(.top, 40)
                    }
                } else {
                    List {
                        ForEach(originals) { original in
                            NavigationLink {
                                OriginalDetailView(original: original)
                            } label: {
                                DarkroomThumbRow(
                                    thumbnail: original.thumbnailImage,
                                    title: original.importedAt.formatted(.dateTime.month().day().year().hour().minute()),
                                    subtitle: "Imported original",
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
                        .onDelete(perform: deleteOriginals)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.bottom, DarkroomReadability.listBottomClearance, for: .scrollContent)
                }
            }
            .darkroomScreen()
            .navigationTitle("Originals")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !originals.isEmpty {
                    EditButton()
                }
            }
        }
    }

    private func deleteOriginals(at offsets: IndexSet) {
        for index in offsets {
            let original = originals[index]
            LocalEditStore.deleteOriginalFile(fileName: original.localFileName)
            modelContext.delete(original)
        }
    }
}

#Preview {
    OriginalsView()
        .modelContainer(originalsPreviewContainer)
}

@MainActor
private let originalsPreviewContainer: ModelContainer = {
    let schema = YofaiModelSchema.schema
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()
