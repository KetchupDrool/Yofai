import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ItemProject.modifiedAt, order: .reverse) private var projects: [ItemProject]
    @State private var showCreate = false
    @State private var showProPlaceholder = false
    @Binding var presentNewProduct: Bool

    init(presentNewProduct: Binding<Bool> = .constant(false)) {
        _presentNewProduct = presentNewProduct
    }

    private var canCreateMoreProducts: Bool {
        EntitlementPolicy.canCreateProduct(
            activeProductCount: projects.count,
            state: EntitlementStore.shared.state
        )
    }

    private var productLimitMessage: String? {
        let access = EntitlementPolicy.access(
            for: .createProduct,
            state: EntitlementStore.shared.state,
            activeProductCount: projects.count
        )
        if case .limited(_, _, let message) = access {
            return message
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            DarkroomEmptyPanel(
                                title: "No Products Yet",
                                systemImage: "shippingbox",
                                message: "Start a product to photograph, organize, check, edit, and export listing-ready photos on this device."
                            )
                            Button {
                                beginCreateProduct()
                            } label: {
                                DarkroomPrimaryButtonLabel(
                                    title: SellerNavigationSupport.startProductTitle,
                                    systemImage: "plus"
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            .accessibilityLabel(SellerNavigationSupport.startProductTitle)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, DarkroomReadability.listBottomClearance)
                    }
                } else {
                    List {
                        if let productLimitMessage {
                            Text(productLimitMessage)
                                .font(.caption)
                                .foregroundStyle(DarkroomTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .listRowBackground(Color.clear)
                                .accessibilityLabel(productLimitMessage)
                        }
                        ForEach(projects) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                ProjectCardRow(project: project)
                            }
                            .buttonStyle(.plain)
                            .navigationLinkIndicatorVisibility(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accessibilityLabel(project.name)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.bottom, DarkroomReadability.listBottomClearance, for: .scrollContent)
                }
            }
            .darkroomScreen()
            .navigationTitle(SellerNavigationSupport.productsListTitle)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ListingQueueView()
                    } label: {
                        Label("Listing Queue", systemImage: "list.bullet.rectangle")
                    }
                    .accessibilityLabel(SellerNavigationSupport.listingQueueAccessibilityLabel)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        beginCreateProduct()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(SellerNavigationSupport.newProductAccessibilityLabel)
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateProjectView()
            }
            .sheet(isPresented: $showProPlaceholder) {
                YofaiProPlaceholderSheet()
            }
            .onChange(of: presentNewProduct) { _, shouldPresent in
                guard shouldPresent else { return }
                beginCreateProduct()
                presentNewProduct = false
            }
            .onAppear {
                if presentNewProduct {
                    beginCreateProduct()
                    presentNewProduct = false
                }
            }
        }
    }

    private func beginCreateProduct() {
        if canCreateMoreProducts {
            showCreate = true
        } else {
            showProPlaceholder = true
        }
    }
}

private struct ProjectCardRow: View {
    let project: ItemProject

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let cover = project.coverThumbnail {
                    Image(uiImage: cover)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
            }
            .frame(width: 72, height: 72)
            .background(DarkroomTheme.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DarkroomTheme.strokeBright.opacity(0.55), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                    .lineLimit(1)
                Text("\(project.photoCount) photo\(project.photoCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                Text("Updated \(project.modifiedAt.formatted(.dateTime.month().day().hour().minute()))")
                    .font(.caption2)
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(DarkroomTheme.accent.opacity(0.8))
                .frame(width: 28, height: 44, alignment: .trailing)
        }
        .padding(12)
        .glassPanel()
        .contentShape(RoundedRectangle(cornerRadius: DarkroomTheme.cornerRadius, style: .continuous))
    }
}

struct CreateProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ItemProject.modifiedAt, order: .reverse) private var projects: [ItemProject]

    enum StartMode: String, CaseIterable, Identifiable {
        case blank = "Start Blank"
        case useDefaults = "Use Seller Defaults"

        var id: String { rawValue }
    }

    @State private var name = ""
    @State private var startMode: StartMode = .blank
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let sellerDefaultsStore = SellerDefaultsStore()

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var withinProductLimit: Bool {
        EntitlementPolicy.canCreateProduct(
            activeProductCount: projects.count,
            state: EntitlementStore.shared.state
        )
    }

    private var canCreate: Bool {
        !trimmedName.isEmpty && !pickerItems.isEmpty && !isSaving && withinProductLimit
    }

    private var savedDefaults: SellerDefaults {
        sellerDefaultsStore.load()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEM NAME")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                    TextField("e.g. Vintage lamp", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(DarkroomTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(DarkroomTheme.stroke, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("LISTING START")
                        .font(.caption2.weight(.bold))
                        .tracking(1.0)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                    Picker("Listing start", selection: $startMode) {
                        ForEach(StartMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if startMode == .useDefaults {
                        Text(defaultsPreviewText)
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Blank project — seller defaults are not applied.")
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                    }
                }

                let selectedCount = pickerItems.count
                let chooseTitle = selectedCount == 0
                    ? "Choose Photos"
                    : "\(selectedCount) photo\(selectedCount == 1 ? "" : "s") selected"
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    DarkroomSecondaryButtonLabel(
                        title: chooseTitle,
                        systemImage: "photo.on.rectangle"
                    )
                }
                .buttonStyle(.plain)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !withinProductLimit {
                    Text(
                        EntitlementPolicy.access(
                            for: .createProduct,
                            state: EntitlementStore.shared.state,
                            activeProductCount: projects.count
                        ).limitedMessage ?? FreemiumCopy.plannedProFeature
                    )
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await createProject() }
                } label: {
                    DarkroomPrimaryButtonLabel(title: "Create Product", isLoading: isSaving)
                }
                .buttonStyle(.plain)
                .disabled(!canCreate)
                .opacity(canCreate ? 1 : 0.5)
            }
            .padding(20)
            .darkroomScreen()
            .navigationTitle("New Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var defaultsPreviewText: String {
        let d = savedDefaults
        if d.isEmpty && !sellerDefaultsStore.hasSavedDefaults {
            return "No seller defaults saved yet. You can set them in Settings — this product will still be created with empty listing fields."
        }
        return "Will prefill category, materials, shipping, processing time, export preset/background, and watermark text. You can edit everything after create."
    }

    private func createProject() async {
        guard canCreate else { return }
        guard EntitlementPolicy.canCreateProduct(
            activeProductCount: projects.count,
            state: EntitlementStore.shared.state
        ) else {
            errorMessage = EntitlementPolicy.access(
                for: .createProduct,
                state: EntitlementStore.shared.state,
                activeProductCount: projects.count
            ).limitedMessage
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            var photos: [ItemProjectPhoto] = []
            photos.reserveCapacity(pickerItems.count)
            for (index, item) in pickerItems.enumerated() {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    throw PhotoSaveError.loadFailed
                }
                let fileName = try LocalEditStore.saveProjectImage(uiImage)
                let photo = ItemProjectPhoto(
                    localFileName: fileName,
                    thumbnailData: SavedEdit.makeThumbnailData(from: ImageEditing.normalizedOrientation(uiImage)),
                    sortOrder: index
                )
                photos.append(photo)
            }

            let project = ItemProject(name: trimmedName, photos: photos)
            if startMode == .useDefaults {
                savedDefaults.apply(to: project)
            }
            modelContext.insert(project)
            dismiss()
        } catch let error as PhotoSaveError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = PhotoSaveError.loadFailed.localizedDescription
        }
    }
}

#Preview {
    ProjectsView()
        .modelContainer(projectsPreviewContainer)
}

@MainActor
private let projectsPreviewContainer: ModelContainer = {
    let schema = YofaiModelSchema.schema
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()
