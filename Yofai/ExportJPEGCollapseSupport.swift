import SwiftUI

/// Phase 70 — collapsible groups on Export JPEGs / Product Detail export clusters.
enum ExportJPEGCollapseGroup: String, CaseIterable, Identifiable, Equatable {
    case listingInfo
    case photos
    case marketplace
    case exportSetup
    case exportReadiness
    case exportJPEGs
    case exportHistory
    case queue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .listingInfo: return "Listing Info"
        case .photos: return "Photos"
        case .marketplace: return "Marketplace"
        case .exportSetup: return "Export size & fit"
        case .exportReadiness: return "Export readiness"
        case .exportJPEGs: return "Export JPEGs"
        case .exportHistory: return "Export History"
        case .queue: return "Listing Queue"
        }
    }

    /// Groups that start expanded so the primary prepare path is visible.
    static let defaultExpanded: Set<ExportJPEGCollapseGroup> = [
        .listingInfo,
        .photos,
        .marketplace,
        .exportSetup,
        .exportReadiness,
        .exportJPEGs
    ]

    /// History + Queue start collapsed to shorten the first screenful.
    static let defaultCollapsed: Set<ExportJPEGCollapseGroup> = [
        .exportHistory,
        .queue
    ]

    static func group(forScrollAnchor anchor: ExportPrepScrollAnchor) -> ExportJPEGCollapseGroup {
        switch anchor {
        case .exportSize, .fit, .photoCheck, .preview:
            return .exportSetup
        case .readiness, .prepTips:
            return .exportReadiness
        }
    }
}

enum ExportJPEGCollapseSupport {
    static func binding(
        _ expanded: Binding<Set<ExportJPEGCollapseGroup>>,
        for group: ExportJPEGCollapseGroup
    ) -> Binding<Bool> {
        Binding(
            get: { expanded.wrappedValue.contains(group) },
            set: { isOn in
                if isOn {
                    expanded.wrappedValue.insert(group)
                } else {
                    expanded.wrappedValue.remove(group)
                }
            }
        )
    }

    static func ensureExpanded(
        _ expanded: inout Set<ExportJPEGCollapseGroup>,
        group: ExportJPEGCollapseGroup
    ) {
        expanded.insert(group)
    }
}

/// Tappable List header that expands/collapses a workspace group.
struct ExportJPEGCollapseHeader: View {
    let group: ExportJPEGCollapseGroup
    @Binding var expanded: Set<ExportJPEGCollapseGroup>

    private var isExpanded: Bool {
        expanded.contains(group)
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                if isExpanded {
                    expanded.remove(group)
                } else {
                    expanded.insert(group)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(group.title)
                    .font(.caption.weight(.bold))
                    .tracking(DarkroomReadability.sectionHeaderTracking)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .textCase(nil)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(group.title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Collapses this group" : "Expands this group")
        .accessibilityAddTraits(.isHeader)
    }
}
