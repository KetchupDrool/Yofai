import SwiftUI
import SwiftData

struct ListingQueueView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ListingQueueEntry.sortOrder, order: .forward) private var entries: [ListingQueueEntry]
    @Query(sort: \ItemProject.modifiedAt, order: .reverse) private var projects: [ItemProject]

    @State private var showAddSheet = false
    @State private var prepareMessage: String?

    private var queuedProjectIDs: Set<PersistentIdentifier> {
        Set(entries.compactMap { $0.project?.persistentModelID })
    }

    private var projectsAvailableToAdd: [ItemProject] {
        projects.filter { !queuedProjectIDs.contains($0.persistentModelID) }
    }

    var body: some View {
        List {
            if entries.isEmpty {
                Section {
                    Text("No projects in the listing queue yet. Add item projects to prepare them for local export.")
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .listRowBackground(sectionBackground)
            } else {
                Section {
                    ForEach(entries) { entry in
                        queueRow(entry)
                    }
                    .onMove(perform: moveEntries)
                    .onDelete(perform: deleteEntries)
                } header: {
                    Text("Queued")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text("Drag to reorder. Prepare Ready Listings validates on device only — Ready entries are processed, Needs Details are skipped. Nothing is uploaded.")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
                .listRowBackground(sectionBackground)
            }

            if let prepareMessage {
                Section {
                    Text(prepareMessage)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.accent)
                }
                .listRowBackground(sectionBackground)
            }
        }
        .darkroomFormList()
        .darkroomScreen()
        .navigationTitle("Listing Queue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                    showAddSheet = true
                }
                .font(.body.weight(.semibold))
                .accessibilityLabel("Add to Queue")
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Prepare Ready Listings") {
                    prepareReadyListings()
                }
                .disabled(entries.isEmpty)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Prepare Queue") {
                    prepareQueue()
                }
                .disabled(entries.isEmpty)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textSecondary)
            }
        }
        .onAppear {
            refreshAllReadiness()
        }
        .sheet(isPresented: $showAddSheet) {
            addProjectsSheet
        }
    }

    private var sectionBackground: some View {
        DarkroomListRowBackground()
    }

    @ViewBuilder
    private func queueRow(_ entry: ListingQueueEntry) -> some View {
        if let project = entry.project {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    cover(for: project)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayTitle(for: project))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.textPrimary)
                            .lineLimit(2)
                        Text("\(project.photoCount) photo\(project.photoCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                        Text(ListingQueueSupport.completenessSummary(for: project))
                            .font(.caption)
                            .foregroundStyle(
                                ListingQueueSupport.isReady(project)
                                    ? DarkroomTheme.accent
                                    : DarkroomTheme.textSecondary
                            )
                        Text(entry.status.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor(entry.status))
                    }
                    Spacer(minLength: 0)
                }

                Text("Missing: \(ListingQueueSupport.missingRequiredSummary(for: project))")
                    .font(.caption2)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    ListingWorkspaceView(project: project)
                } label: {
                    Text("Open \(SellerNavigationSupport.projectWorkspaceLinkTitle)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                }

                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    Text("Review Draft")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                }
            }
            .padding(.vertical, 4)
        } else {
            Text("Missing project")
                .foregroundStyle(DarkroomTheme.danger)
        }
    }

    private func cover(for project: ItemProject) -> some View {
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
        .frame(width: 64, height: 64)
        .background(DarkroomTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func displayTitle(for project: ItemProject) -> String {
        let title = project.trimmedListingTitle
        return title.isEmpty ? project.name : title
    }

    private func statusColor(_ status: ListingQueueStatus) -> Color {
        switch status {
        case .ready:
            return DarkroomTheme.accent
        case .needsDetails, .failed:
            return DarkroomTheme.danger
        case .processing:
            return DarkroomTheme.textSecondary
        case .completed:
            return DarkroomTheme.accent
        }
    }

    private var addProjectsSheet: some View {
        NavigationStack {
            List {
                if projectsAvailableToAdd.isEmpty {
                    Text("All projects are already in the queue, or you have no projects yet.")
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                } else {
                    ForEach(projectsAvailableToAdd) { project in
                        Button {
                            add(project)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.name)
                                        .foregroundStyle(DarkroomTheme.textPrimary)
                                    Text(project.trimmedListingTitle.isEmpty ? "No listing title" : project.trimmedListingTitle)
                                        .font(.caption)
                                        .foregroundStyle(DarkroomTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(DarkroomTheme.accent)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .darkroomScreen()
            .navigationTitle("Add to Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showAddSheet = false }
                }
            }
        }
    }

    private func add(_ project: ItemProject) {
        if ListingQueueSupport.add(project: project, in: modelContext) == nil {
            prepareMessage = "That project is already in the queue."
        } else {
            prepareMessage = nil
        }
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        ListingQueueSupport.reorder(entries, from: source, to: destination)
    }

    private func deleteEntries(at offsets: IndexSet) {
        let ordered = entries
        for index in offsets {
            ListingQueueSupport.remove(ordered[index], in: modelContext)
        }
    }

    private func prepareQueue() {
        ListingQueueSupport.prepareQueue(entries)
        let readyCount = entries.filter { $0.status == .ready }.count
        let needsCount = entries.filter { $0.status == .needsDetails }.count
        let failedCount = entries.filter { $0.status == .failed }.count
        prepareMessage = "Validated locally: \(readyCount) Ready · \(needsCount) Needs Details · \(failedCount) Failed. Nothing was uploaded."
    }

    private func prepareReadyListings() {
        let summary = ListingQueueSupport.prepareReadyListings(entries)
        prepareMessage = summary.displayMessage
    }

    private func refreshAllReadiness() {
        for entry in entries {
            ListingQueueSupport.syncReadiness(for: entry)
        }
    }
}
