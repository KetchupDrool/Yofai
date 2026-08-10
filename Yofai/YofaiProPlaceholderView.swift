import SwiftUI

/// Phase 49 — factual Pro placeholder. No pricing, no StoreKit purchase, no fake unlock.
struct YofaiProPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(FreemiumCopy.proTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(FreemiumCopy.proNotAvailableYet)
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(FreemiumCopy.proNotAvailableYet)
                    Text(FreemiumCopy.proPlannedSummary)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    ForEach(proPreviewFeatures, id: \.self) { title in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(FreemiumCopy.plannedProFeature)
                                    .font(.caption2)
                                    .foregroundStyle(DarkroomTheme.textTertiary)
                            }
                        } icon: {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(DarkroomTheme.textTertiary)
                        }
                        .accessibilityLabel("\(title). \(FreemiumCopy.plannedProFeature)")
                    }
                } header: {
                    Text("Planned Pro extras")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text("Free keeps the core local export workflow. Pro features are additive. Direct Upload Mode is not implemented.")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
            }
            .navigationTitle(FreemiumCopy.proTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(FreemiumCopy.keepUsingFree) { dismiss() }
                        .accessibilityLabel(FreemiumCopy.keepUsingFree)
                }
            }
        }
    }

    private var proPreviewFeatures: [String] {
        [
            FreemiumFeature.unlimitedProducts.displayTitle,
            FreemiumFeature.advancedHistoryTools.displayTitle,
            FreemiumFeature.advancedMultiMarketTools.displayTitle,
            FreemiumFeature.cloudBackupSync.displayTitle,
            FreemiumFeature.directUploadMode.displayTitle
        ]
    }
}

/// Settings section: current Free plan + planned Pro preview.
struct YofaiProSettingsSection: View {
    @State private var showPlaceholder = false
    private var state: EntitlementState { EntitlementStore.shared.state }

    var body: some View {
        Section {
            LabeledContent("Plan", value: state.plan.displayTitle)
                .accessibilityLabel("\(FreemiumCopy.currentPlanFree)")

            Text(FreemiumCopy.proPlannedSummary)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Free product limit: \(state.limits.freeActiveProductLimit). Existing products stay available if you are over the limit.")
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showPlaceholder = true
            } label: {
                Text("Preview \(FreemiumCopy.proTitle)")
                    .foregroundStyle(DarkroomTheme.accent)
            }
            .accessibilityLabel("Preview \(FreemiumCopy.proTitle). \(FreemiumCopy.proNotAvailableYet)")
        } header: {
            Text(FreemiumCopy.proTitle)
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text("No purchase is available in this version. StoreKit will be required before Pro can charge.")
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .sheet(isPresented: $showPlaceholder) {
            YofaiProPlaceholderSheet()
        }
    }
}
