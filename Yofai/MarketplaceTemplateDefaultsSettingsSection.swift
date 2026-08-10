import SwiftUI

/// Phase 63 — compact Settings note for Pro marketplace templates.
/// Does not replace Free Seller Defaults. Templates are edited from marketplace drafts.
struct MarketplaceTemplateDefaultsSettingsSection: View {
    private var entitlementState: EntitlementState {
        EntitlementStore.shared.state
    }

    private var canUseTemplates: Bool {
        MarketplaceTemplateDefaultsSupport.canUseMarketplaceTemplates(state: entitlementState)
    }

    private let store = MarketplaceTemplateDefaultsStore()

    var body: some View {
        Section {
            if canUseTemplates {
                let templates = store.allTemplates()
                if templates.isEmpty {
                    Text(MarketplaceTemplateDefaultsCopy.noTemplateSaved)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(templates, id: \.marketplaceTargetRaw) { template in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.displayName)
                                .foregroundStyle(DarkroomTheme.textPrimary)
                            Text("Prepared for \(template.marketplaceTarget.displayTitle)")
                                .font(.caption2)
                                .foregroundStyle(DarkroomTheme.textTertiary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                Text("Open a marketplace draft to save, apply to blank fields, or clear a default.")
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(MarketplaceTemplateDefaultsCopy.lockedDetail)
                    .font(.caption)
                    .foregroundStyle(DarkroomTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink {
                    YofaiProPaywallView()
                } label: {
                    Text("View \(FreemiumCopy.proTitle)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                }
                .accessibilityLabel("View \(FreemiumCopy.proTitle)")
            }
        } header: {
            Text(MarketplaceTemplateDefaultsCopy.sectionTitle)
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text(MarketplaceTemplateDefaultsCopy.settingsFooter)
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
    }
}
