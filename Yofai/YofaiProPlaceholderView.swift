import SwiftUI

/// Phase 53/54 — StoreKit-backed Yofai Pro paywall. Prices come from StoreKit when loaded.
struct YofaiProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchases = PurchaseManager.shared
    private var state: EntitlementState { EntitlementStore.shared.state }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(FreemiumCopy.proTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.textPrimary)
                    Text(state.isPro ? FreemiumCopy.currentPlanPro : FreemiumCopy.currentPlanFree)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DarkroomTheme.accent)
                    Text(FreemiumCopy.proBenefitsIntro)
                        .font(.subheadline)
                        .foregroundStyle(DarkroomTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(FreemiumCopy.proPlannedSummary)
                        .font(.caption)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    benefitRow(FreemiumFeature.unlimitedProducts.displayTitle, detail: "Available with Pro")
                    benefitRow(FreemiumFeature.advancedHistoryTools.displayTitle, detail: FreemiumCopy.plannedProFeature)
                    benefitRow(FreemiumFeature.advancedMultiMarketTools.displayTitle, detail: "Multiple marketplace drafts per product")
                    benefitRow(
                        FreemiumFeature.cloudBackupSync.displayTitle,
                        detail: FreemiumCopy.plannedFutureProFeature
                    )
                    benefitRow(
                        FreemiumFeature.directUploadMode.displayTitle,
                        detail: "Not implemented — only if verified later"
                    )
                } header: {
                    Text("Pro benefits")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text("Direct Upload Mode and cloud backup are not available in this version. No AI features.")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }

                Section {
                    if purchases.productsLoadState == .loading || purchases.isBusy {
                        ProgressView("Loading…")
                    }

                    if purchases.productsLoadState == .unavailable {
                        Text(FreemiumCopy.purchasesUnavailable)
                            .font(.subheadline)
                            .foregroundStyle(DarkroomTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(FreemiumCopy.purchasesUnavailable)
                    }

                    ForEach(purchases.products) { product in
                        Button {
                            Task { _ = await purchases.purchase(productID: product.id) }
                        } label: {
                            Text(product.purchaseButtonTitle)
                                .foregroundStyle(DarkroomTheme.accent)
                        }
                        .disabled(purchases.isBusy || state.isPro)
                        .accessibilityLabel("Subscribe \(product.periodLabel) for \(product.displayPrice)")
                    }

                    Button {
                        Task { _ = await purchases.restorePurchases() }
                    } label: {
                        Text(YofaiProLegalLinks.restorePurchasesTitle)
                            .foregroundStyle(DarkroomTheme.accent)
                    }
                    .disabled(purchases.isBusy)
                    .accessibilityLabel(YofaiProLegalLinks.restorePurchasesTitle)

                    if let status = purchases.statusMessage, !status.isEmpty {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(DarkroomTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } header: {
                    Text("Subscribe")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text("Payment is charged to your Apple ID when a subscription product loads and you purchase. Live price comes from StoreKit. Intended App Store Connect tiers: \(YofaiProductIDs.intendedMonthlyPriceNote), \(YofaiProductIDs.intendedYearlyPriceNote).")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }

                // Always visible — including when StoreKit products are unavailable.
                Section {
                    Link(YofaiProLegalLinks.termsOfUseTitle, destination: YofaiProLegalLinks.termsOfUseURL)
                        .foregroundStyle(DarkroomTheme.accent)
                        .accessibilityLabel(YofaiProLegalLinks.termsOfUseTitle)
                    Link(YofaiProLegalLinks.privacyStatementTitle, destination: YofaiProLegalLinks.privacyStatementURL)
                        .foregroundStyle(DarkroomTheme.accent)
                        .accessibilityLabel(YofaiProLegalLinks.privacyStatementTitle)
                } header: {
                    Text("Legal")
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text(FreemiumCopy.subscriptionTermsFooter)
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
            .task {
                purchases.startListeningForTransactionsIfNeeded()
                await purchases.refreshEntitlementsAndProducts()
            }
        }
    }

    private func benefitRow(_ title: String, detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(DarkroomTheme.textTertiary)
            }
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DarkroomTheme.accent)
        }
        .accessibilityLabel("\(title). \(detail)")
    }
}

/// Settings → Yofai Pro
struct YofaiProSettingsSection: View {
    @State private var showPaywall = false
    @ObservedObject private var purchases = PurchaseManager.shared
    private var state: EntitlementState { EntitlementStore.shared.state }

    var body: some View {
        Section {
            LabeledContent("Plan", value: state.plan.displayTitle)
                .accessibilityLabel(state.isPro ? FreemiumCopy.currentPlanPro : FreemiumCopy.currentPlanFree)

            Text(FreemiumCopy.proPlannedSummary)
                .font(.caption)
                .foregroundStyle(DarkroomTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Free product limit: \(state.limits.freeActiveProductLimit). Existing products stay available if you are over the limit.")
                .font(.caption2)
                .foregroundStyle(DarkroomTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showPaywall = true
            } label: {
                Text(state.isPro ? "Manage \(FreemiumCopy.proTitle)" : "Upgrade to \(FreemiumCopy.proTitle)")
                    .foregroundStyle(DarkroomTheme.accent)
            }
            .accessibilityLabel(state.isPro ? "Manage Yofai Pro" : "Upgrade to Yofai Pro")

            Button {
                Task { _ = await purchases.restorePurchases() }
            } label: {
                Text(YofaiProLegalLinks.restorePurchasesTitle)
                    .foregroundStyle(DarkroomTheme.accent)
            }
            .disabled(purchases.isBusy)
            .accessibilityLabel(YofaiProLegalLinks.restorePurchasesTitle)

            if purchases.productsLoadState == .unavailable {
                Text(FreemiumCopy.purchasesUnavailable)
                    .font(.caption2)
                    .foregroundStyle(DarkroomTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text(FreemiumCopy.proTitle)
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(DarkroomTheme.textTertiary)
        } footer: {
            Text(FreemiumCopy.subscriptionTermsFooter)
                .foregroundStyle(DarkroomTheme.textTertiary)
        }
        .sheet(isPresented: $showPaywall) {
            YofaiProPaywallView()
        }
        .task {
            await purchases.refreshEntitlementsAndProducts()
        }
    }
}

/// Compatibility alias for older call sites.
typealias YofaiProPlaceholderSheet = YofaiProPaywallView
