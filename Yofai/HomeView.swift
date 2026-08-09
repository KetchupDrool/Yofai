import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \SavedEdit.savedAt, order: .reverse) private var savedEdits: [SavedEdit]
    @Query(sort: \ImportedOriginal.importedAt, order: .reverse) private var importedOriginals: [ImportedOriginal]
    @State private var showImport = false

    private var recentEdits: [SavedEdit] {
        Array(savedEdits.prefix(5))
    }

    private var recentOriginals: [ImportedOriginal] {
        Array(importedOriginals.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOFAI")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, DarkroomTheme.accent.opacity(0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
        Text("Local photo edits. No account. No cloud.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Prep listing-ready exports for Etsy, Instagram, Facebook, and Marketplace.")
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .glassPanel(cornerRadius: 20)

                    Button {
                        showImport = true
                    } label: {
                        DarkroomPrimaryButtonLabel(title: "Start Editing", systemImage: "plus.rectangle.on.rectangle")
                    }
                    .buttonStyle(.plain)

                    homeSection(title: "Recent Originals") {
                        if recentOriginals.isEmpty {
                            compactEmptyHint("Imported photos appear here for quick re-edit.")
                        } else {
                            ForEach(recentOriginals) { original in
                                NavigationLink {
                                    OriginalDetailView(original: original)
                                } label: {
                                    DarkroomThumbRow(
                                        thumbnail: original.thumbnailImage,
                                        title: original.importedAt.formatted(.dateTime.month().day().hour().minute()),
                                        subtitle: "Imported original"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    homeSection(title: "Recent Saves") {
                        if recentEdits.isEmpty {
                            compactEmptyHint("Saved listing exports appear here after you tap Save Listing Copy.")
                        } else {
                            ForEach(recentEdits) { edit in
                                NavigationLink {
                                    HistoryDetailView(edit: edit)
                                } label: {
                                    DarkroomThumbRow(
                                        thumbnail: edit.thumbnailImage,
                                        title: edit.savedAt.formatted(.dateTime.month().day().hour().minute()),
                                        subtitle: edit.listingSummary
                                            ?? "\(edit.filterName) · \(edit.rotationDegrees)° · Crop \(edit.didCrop ? "Yes" : "No")",
                                        detail: {
                                            if let listing = edit.listingSummary {
                                                let wm = edit.watermarkSummary.map { " · \($0)" } ?? ""
                                                return "\(edit.filterName) · \(edit.rotationDegrees)°\(wm)"
                                            }
                                            if let wm = edit.watermarkSummary {
                                                return edit.adjustmentSummary == "None" ? wm : "\(edit.adjustmentSummary) · \(wm)"
                                            }
                                            return edit.adjustmentSummary == "None" ? nil : edit.adjustmentSummary
                                        }()
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .darkroomScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $showImport) {
                ImportView()
            }
        }
    }

    @ViewBuilder
    private func homeSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(DarkroomTheme.textTertiary)
            content()
        }
    }

    private func compactEmptyHint(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(DarkroomTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassPanel()
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    HomeView()
        .modelContainer(homePreviewContainer)
}

@MainActor
private let homePreviewContainer: ModelContainer = {
    let schema = YofaiModelSchema.schema
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()
