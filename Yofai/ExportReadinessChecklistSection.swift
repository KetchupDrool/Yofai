import SwiftUI

/// Phase 42 — compact or full seller export-readiness checklist (computed, not persisted).
struct ExportReadinessChecklistSection: View {
    @Bindable var project: ItemProject
    var style: Style = .full
    var showWorkspaceLink: Bool = false

    enum Style {
        case compact
        case full
    }

    private var summary: ExportReadinessSummary {
        ExportReadiness.summary(for: project)
    }

    var body: some View {
        Section {
            Text(summary.overallHeadline)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor(summary.status))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("\(summary.overallHeadline). Readiness status: \(summary.status.rawValue)")

            if style == .compact {
                Text(compactSummaryLine)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(summary.items) { row in
                    checklistRow(row)
                }
            }

            if showWorkspaceLink {
                NavigationLink {
                    ListingWorkspaceView(project: project)
                } label: {
                    Text(SellerNavigationSupport.projectWorkspaceLinkTitle)
                        .foregroundStyle(DarkroomTheme.accent)
                }
                .accessibilityLabel(SellerNavigationSupport.projectWorkspaceLinkTitle)
            }

            if project.sortedPhotos.isEmpty {
                NavigationLink {
                    ProductIntakeView(project: project)
                } label: {
                    Text(SellerNavigationSupport.projectIntakeLinkTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                }
            }
        } header: {
            Text("Export Readiness")
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("Local export checklist only. Does not block Export Photos and is not marketplace compliance.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
    }

    private var compactSummaryLine: String {
        switch summary.status {
        case .ready:
            return "Photos and export settings look set for a local export."
        case .review, .needsAttention:
            return summary.reasons.prefix(2).joined(separator: " · ")
        }
    }

    private func checklistRow(_ row: ExportReadinessItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
            Text(row.statusLine)
                .font(.caption)
                .foregroundStyle(rowLevelColor(row.level))
                .fixedSize(horizontal: false, vertical: true)
            if let explanation = row.explanation {
                Text(explanation)
                    .font(.caption2)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            [
                row.title,
                row.statusLine,
                row.explanation,
                "Level: \(row.level.rawValue)"
            ]
            .compactMap { $0 }
            .joined(separator: ". ")
        )
    }

    private func statusColor(_ status: ExportReadinessStatus) -> Color {
        switch status {
        case .ready: return DarkroomTheme.accent
        case .review: return DarkroomTheme.textSecondary
        case .needsAttention: return DarkroomTheme.danger
        }
    }

    private func rowLevelColor(_ level: ExportReadinessRowLevel) -> Color {
        switch level {
        case .ready, .optional: return DarkroomTheme.textSecondary
        case .review: return DarkroomTheme.textSecondary
        case .needsAttention: return DarkroomTheme.danger
        }
    }
}
