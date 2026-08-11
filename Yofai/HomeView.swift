import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \ItemProject.modifiedAt, order: .reverse) private var projects: [ItemProject]
    @Query(sort: \SavedEdit.savedAt, order: .reverse) private var savedEdits: [SavedEdit]
    @Query(sort: \ImportedOriginal.importedAt, order: .reverse) private var importedOriginals: [ImportedOriginal]

    var onStartProduct: () -> Void = {}
    var onOpenProducts: () -> Void = {}
    var onOpenOriginals: () -> Void = {}
    var onOpenHistory: () -> Void = {}

    @State private var showImport = false

    private var recentProducts: [ItemProject] {
        SellerNavigationSupport.recentProducts(projects)
    }

    private var recentEdits: [SavedEdit] {
        Array(savedEdits.prefix(3))
    }

    private var recentOriginals: [ImportedOriginal] {
        Array(importedOriginals.prefix(3))
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
                        Text("Local-first product photo prep for online sellers.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(SellerNavigationSupport.homeWorkflowHint)
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .glassPanel(cornerRadius: 20)

                    Button(action: onStartProduct) {
                        DarkroomPrimaryButtonLabel(
                            title: SellerNavigationSupport.startProductTitle,
                            systemImage: "shippingbox.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(SellerNavigationSupport.startProductTitle)
                    .accessibilityHint("Creates a new product listing project")

                    if !recentProducts.isEmpty {
                        Button(action: onOpenProducts) {
                            DarkroomSecondaryButtonLabel(
                                title: "All Products",
                                systemImage: "shippingbox"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("All Products")
                    }

                    homeSection(title: SellerNavigationSupport.continueProductsSectionTitle) {
                        if recentProducts.isEmpty {
                            compactEmptyHint("No products yet. Tap Start Product to create your first item project.")
                        } else {
                            ForEach(recentProducts) { project in
                                NavigationLink {
                                    ProjectDetailView(project: project)
                                } label: {
                                    DarkroomThumbRow(
                                        thumbnail: project.coverThumbnail,
                                        title: project.name,
                                        subtitle: "\(project.photoCount) photo\(project.photoCount == 1 ? "" : "s") · Updated \(project.modifiedAt.formatted(.dateTime.month().day().hour().minute()))"
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Continue \(project.name)")
                            }
                        }
                    }

                    homeSection(title: SellerNavigationSupport.secondaryToolsSectionTitle) {
                        Button {
                            showImport = true
                        } label: {
                            DarkroomSecondaryButtonLabel(
                                title: SellerNavigationSupport.quickImportTitle,
                                systemImage: "plus.rectangle.on.rectangle"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(SellerNavigationSupport.quickImportTitle)
                        .accessibilityHint("Opens the single-photo import editor. Prefer Start Product for listing sets.")

                        Button(action: onOpenOriginals) {
                            DarkroomSecondaryButtonLabel(
                                title: SellerNavigationSupport.browseOriginalsTitle,
                                systemImage: "photo.on.rectangle"
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: onOpenHistory) {
                            DarkroomSecondaryButtonLabel(
                                title: SellerNavigationSupport.browseHistoryTitle,
                                systemImage: "clock"
                            )
                        }
                        .buttonStyle(.plain)

                        if !recentOriginals.isEmpty {
                            Text("Recent originals")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(DarkroomTheme.textTertiary)
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

                        if !recentEdits.isEmpty {
                            Text("Recent saves")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(DarkroomTheme.textTertiary)
                            ForEach(recentEdits) { edit in
                                NavigationLink {
                                    HistoryDetailView(edit: edit)
                                } label: {
                                    DarkroomThumbRow(
                                        thumbnail: edit.thumbnailImage,
                                        title: edit.savedAt.formatted(.dateTime.month().day().hour().minute()),
                                        subtitle: edit.listingSummary
                                            ?? "\(edit.filterName) · \(edit.rotationDegrees)° · Crop \(edit.didCrop ? "Yes" : "No")"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, DarkroomReadability.listBottomClearance + DarkroomReadability.tabBarSafeAreaBoost)
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
                .font(.caption.weight(.bold))
                .tracking(DarkroomReadability.sectionHeaderTracking)
                .foregroundStyle(DarkroomTheme.textSecondary)
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
