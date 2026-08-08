import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \SavedEdit.savedAt, order: .reverse) private var savedEdits: [SavedEdit]
    @State private var showImport = false

    private var recentEdits: [SavedEdit] {
        Array(savedEdits.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yofai")
                            .font(.largeTitle.weight(.bold))
                        Text("Simple local photo edits. No account. No cloud.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        showImport = true
                    } label: {
                        Text("Start Editing")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Saves")
                            .font(.title3.weight(.semibold))

                        if recentEdits.isEmpty {
                            ContentUnavailableView(
                                "No saved edits yet",
                                systemImage: "photo.on.rectangle.angled",
                                description: Text("Import a photo, edit it, then tap Save Copy.")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            ForEach(recentEdits) { edit in
                                RecentEditCard(edit: edit)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showImport) {
                ImportView()
            }
        }
    }
}

private struct RecentEditCard: View {
    let edit: SavedEdit

    var body: some View {
        HStack(spacing: 12) {
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
                Text(edit.savedAt, format: .dateTime.month().day().hour().minute())
                    .font(.headline)
                Text("\(edit.filterName) · \(edit.rotationDegrees)°")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: SavedEdit.self, inMemory: true)
}
