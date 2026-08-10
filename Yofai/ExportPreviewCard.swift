import SwiftUI
import UIKit

/// Phase 39 — export preview using the same `ImageEditing.renderPreview` path as final export.
struct ExportPreviewCard: View {
    let sourceImage: UIImage
    let state: PhotoEditState

    @State private var preview: UIImage?
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Export preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textSecondary)

            ZStack {
                DarkroomTheme.canvas
                if let preview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else {
                    ProgressView()
                        .tint(DarkroomTheme.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DarkroomTheme.stroke, lineWidth: 1)
            )

            Text("\(state.exportPreset.pickerLabel) · \(state.exportFitMode.displayTitle)")
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .onAppear { scheduleRefresh() }
        .onChange(of: state) { _, _ in scheduleRefresh() }
        .onDisappear {
            refreshTask?.cancel()
            refreshTask = nil
        }
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(nanoseconds: 80_000_000)
            guard !Task.isCancelled else { return }
            let image = ImageEditing.renderPreview(source: sourceImage, state: state)
            await MainActor.run {
                preview = image
            }
        }
    }
}

/// Shared Phase 39/42/43 marketplace → canvas → fit controls for Project Detail / Listing Workspace.
struct MarketplaceExportSettingsBlock: View {
    @Bindable var project: ItemProject
    var showPreview: Bool = true
    /// Compact on Project Detail; full checklist on Listing Workspace.
    var readinessStyle: ExportReadinessChecklistSection.Style = .full
    var showWorkspaceLinkInReadiness: Bool = false
    /// Full prep tips on Listing Workspace; compact single tip on Project Detail.
    var prepTipsStyle: ExportPrepTipsSection.Style? = .full
    var showWorkspaceLinkInPrepTips: Bool = true
    var onFocusAnchor: ((ExportPrepScrollAnchor) -> Void)? = nil

    private var previewPhoto: ItemProjectPhoto? {
        project.sortedPhotos.first
    }

    private var previewState: PhotoEditState? {
        guard let previewPhoto else { return nil }
        return previewPhoto.exportEditState(project: project)
    }

    private var anyFillCropAdjusted: Bool {
        project.sortedPhotos.contains { photo in
            PhotoTechnicalCheck.facts(for: photo, project: project).fillCropPositionAdjusted == true
        }
    }

    var body: some View {
        Group {
            marketplaceSection
            canvasSection
            fitSection
            photoCheckSummarySection
            ExportReadinessChecklistSection(
                project: project,
                style: readinessStyle,
                showWorkspaceLink: showWorkspaceLinkInReadiness
            )
            .listRowBackground(sectionBackground)
            .id(ExportPrepScrollAnchor.readiness.rawValue)

            if let prepTipsStyle {
                ExportPrepTipsSection(
                    project: project,
                    style: prepTipsStyle,
                    onFocus: onFocusAnchor,
                    showWorkspaceLinkActions: showWorkspaceLinkInPrepTips
                )
                .listRowBackground(sectionBackground)
            }

            if showPreview, let photo = previewPhoto, let source = photo.fullLocalImage, let state = previewState {
                Section {
                    ExportPreviewCard(sourceImage: source, state: state)
                } header: {
                    Text("Preview")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text("Uses the same framing as Export Photos. First project photo shown.")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
                .listRowBackground(sectionBackground)
                .id(ExportPrepScrollAnchor.preview.rawValue)
            }
        }
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(0.45)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DarkroomTheme.surface)
            )
    }

    private var marketplaceSection: some View {
        Section {
            Picker("Marketplace", selection: Binding(
                get: { project.listingMarketplaceTarget },
                set: { newValue in
                    MarketplaceExportSupport.switchTarget(
                        on: project,
                        to: newValue,
                        applyRecommendedCanvas: newValue.hasVerifiedYofaiCanvas
                    )
                }
            )) {
                ForEach(MarketplaceTarget.allCases) { target in
                    Text(target.displayTitle).tag(target)
                }
            }

            Text(project.listingMarketplaceTarget.canvasGuidance)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if project.listingMarketplaceTarget.hasVerifiedYofaiCanvas,
               let recommended = project.listingMarketplaceTarget.recommendedExportPreset,
               project.listingExportPreset != recommended {
                Button("Use recommended size (\(recommended.pickerLabel))") {
                    project.listingExportPreset = recommended
                    project.touchModified()
                }
                .foregroundStyle(DarkroomTheme.accent)
            }
        } header: {
            Text("Marketplace")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Switching marketplace changes export settings only — photo edits and crop positions stay.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
    }

    private var canvasSection: some View {
        Section {
            Picker("Export size", selection: Binding(
                get: { project.listingExportPreset },
                set: {
                    project.listingExportPreset = $0
                    project.touchModified()
                }
            )) {
                ForEach(ListingExportPresetGroup.allCases) { group in
                    Section(group.rawValue) {
                        ForEach(ListingExportPreset.presets(in: group)) { preset in
                            Text(preset.pickerLabel).tag(preset)
                        }
                    }
                }
            }

            labeled("Size", project.listingExportPreset.pixelSizeLabel)
            labeled("Aspect", project.listingExportPreset.aspectRatioLabel)
            labeled("Canvas type", project.listingExportPreset.verificationLabel)
            Text(project.listingExportPreset.displaySubtitle)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Text("Export size")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text(ListingExportPreset.localExportDisclaimer)
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
        .id(ExportPrepScrollAnchor.exportSize.rawValue)
    }

    private var fitSection: some View {
        Section {
            Picker("Fit", selection: Binding(
                get: { project.listingExportFitMode },
                set: {
                    project.listingExportFitMode = $0
                    project.touchModified()
                }
            )) {
                ForEach(ListingExportFitMode.allCases) { mode in
                    Text(mode.displayTitle).tag(mode)
                }
            }

            Text(project.listingExportFitMode.sellerExplanation)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if project.listingExportFitMode == .fillCrop {
                labeled(
                    "Crop position",
                    anyFillCropAdjusted ? "Adjusted on one or more photos" : "Centered (default)"
                )
                Text("Open a photo in Edit → Reposition to adjust Fill + Crop.")
                    .font(.caption2)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Picker("Background", selection: Binding(
                get: { project.listingExportBackground },
                set: {
                    project.listingExportBackground = $0
                    project.touchModified()
                }
            )) {
                ForEach(ListingExportBackground.allCases) { background in
                    Text(background.rawValue).tag(background)
                }
            }

            Toggle("Watermark", isOn: Binding(
                get: { project.listingWatermarkEnabled },
                set: {
                    project.listingWatermarkEnabled = $0
                    project.touchModified()
                }
            ))
            .tint(DarkroomTheme.accent)

            if project.listingWatermarkEnabled {
                TextField("Watermark text", text: Binding(
                    get: { project.listingWatermarkText },
                    set: {
                        project.listingWatermarkText = String($0.prefix(PhotoEditState.watermarkMaxLength))
                        project.touchModified()
                    }
                ))
            }
        } header: {
            Text("Fit")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
        .id(ExportPrepScrollAnchor.fit.rawValue)
    }

    private var photoCheckSummarySection: some View {
        Section {
            let smaller = PhotoTechnicalCheck.photosWithSourceSmallerThanExportCanvas(in: project).count
            let aspect = PhotoTechnicalCheck.photosWithAspectDifferingFromExportCanvas(in: project).count
            labeled("Below export size", smaller == 0 ? "None" : "\(smaller) photo\(smaller == 1 ? "" : "s")")
            labeled(
                "Aspect mismatch",
                aspect == 0
                    ? "No meaningful mismatch"
                    : "\(aspect) photo\(aspect == 1 ? "" : "s") — \(project.listingExportFitMode == .containPad ? "padding expected" : "cropping expected")"
            )
            if project.listingExportFitMode == .fillCrop {
                labeled("Crop position", anyFillCropAdjusted ? "Adjusted" : "Centered")
            }
        } header: {
            Text("Photo check")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local facts only. Padding or cropping can be intentional.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .listRowBackground(sectionBackground)
        .id(ExportPrepScrollAnchor.photoCheck.rawValue)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textTertiary)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
