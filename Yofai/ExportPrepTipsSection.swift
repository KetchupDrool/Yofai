import SwiftUI

/// Phase 43 — short local prep tips that point at existing controls (manual only).
struct ExportPrepTipsSection: View {
    @Bindable var project: ItemProject
    var style: Style = .full
    var onFocus: ((ExportPrepScrollAnchor) -> Void)? = nil
    /// When false (Listing Workspace), listing-details tip focuses readiness instead of pushing another workspace.
    var showWorkspaceLinkActions: Bool = true
    var showHeader: Bool = true

    enum Style {
        case full
        case compact
    }

    private var summary: ExportReadinessSummary {
        ExportReadiness.summary(for: project)
    }

    private var tips: [ExportPrepTip] {
        switch style {
        case .full:
            return ExportPrepTipSupport.tips(for: project, summary: summary)
        case .compact:
            if let tip = ExportPrepTipSupport.topTip(for: project, summary: summary) {
                return [tip]
            }
            return []
        }
    }

    var body: some View {
        Group {
            if tips.isEmpty {
                EmptyView()
            } else {
                Section {
                    ForEach(tips) { tip in
                        tipRow(tip)
                    }
                } header: {
                    if showHeader {
                        Text(style == .compact ? "Prep Tip" : "Prep Tips")
                            .foregroundStyle(DarkroomTheme.textTertiary)
                    }
                } footer: {
                    Text("Local tips only. They never change fit, crop, or export size for you.")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
                .id(ExportPrepScrollAnchor.prepTips.rawValue)
            }
        }
    }

    private func tipRow(_ tip: ExportPrepTip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tip.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(tip.detail)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            tipAction(tip)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tip.accessibilitySummary)
    }

    @ViewBuilder
    private func tipAction(_ tip: ExportPrepTip) -> some View {
        if let label = tip.actionLabel, tip.action != .none {
            switch tip.action {
            case .captureAndCheckPhotos, .openPhotoCheck:
                NavigationLink {
                    ProductIntakeView(project: project)
                } label: {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                }
                .accessibilityLabel(label)

            case .openListingWorkspace:
                if showWorkspaceLinkActions {
                    NavigationLink {
                        ListingWorkspaceView(project: project)
                    } label: {
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                    .accessibilityLabel(label)
                } else {
                    Button(label) {
                        onFocus?(.readiness)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.accent)
                    .accessibilityLabel(label)
                }

            case .focusExportSize:
                Button(label) {
                    onFocus?(.exportSize)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
                .accessibilityLabel(label)

            case .focusFit:
                Button(label) {
                    onFocus?(.fit)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
                .accessibilityLabel(label)

            case .focusPreview:
                Button(label) {
                    onFocus?(.preview)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.accent)
                .accessibilityLabel(label)

            case .openReposition:
                if let photo = ExportPrepTipSupport.repositionPhoto(in: project) {
                    NavigationLink {
                        ProjectPhotoEditDestination(photo: photo)
                    } label: {
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                    .accessibilityLabel(label)
                }

            case .none:
                EmptyView()
            }
        }
    }
}
