import SwiftUI

/// Phase 53/54/68 — StoreKit-backed Yofai Pro paywall. Live prices from StoreKit when loaded;
/// intended Monthly $4.99 / Yearly $39.99 shown as fallback when unavailable.
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
                    ForEach(FreemiumCopy.freeIncludesItems, id: \.self) { item in
                        benefitRow(item, detail: nil)
                    }
                } header: {
                    Text(FreemiumCopy.freeIncludesTitle)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }

                Section {
                    ForEach(FreemiumCopy.proAddsItems, id: \.self) { item in
                        benefitRow(item, detail: nil)
                    }
                } header: {
                    Text(FreemiumCopy.proAddsTitle)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                } footer: {
                    Text("No AI features. Free keeps the core local export workflow.")
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

                        priceFallbackRow(
                            title: FreemiumCopy.intendedMonthlyPriceLabel,
                            showBestValue: false
                        )
                        priceFallbackRow(
                            title: FreemiumCopy.intendedYearlyPriceLabel,
                            showBestValue: true
                        )
                    }

                    ForEach(purchases.products) { product in
                        Button {
                            Task { _ = await purchases.purchase(productID: product.id) }
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(product.purchaseButtonTitle)
                                    .foregroundStyle(DarkroomTheme.accent)
                                if product.isBestValue {
                                    Text(FreemiumCopy.bestValueLabel)
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(DarkroomTheme.textPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(DarkroomTheme.accent.opacity(0.28), in: Capsule())
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .disabled(purchases.isBusy || state.isPro)
                        .accessibilityLabel(
                            product.isBestValue
                                ? "Subscribe \(product.periodLabel) for \(product.displayPrice). \(FreemiumCopy.bestValueLabel)"
                                : "Subscribe \(product.periodLabel) for \(product.displayPrice)"
                        )
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
                    Text("Payment is charged to your Apple ID when a subscription product loads and you purchase. Live price comes from StoreKit when available. Intended App Store Connect tiers: \(YofaiProductIDs.intendedMonthlyPriceNote), \(YofaiProductIDs.intendedYearlyPriceNote).")
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

    private func benefitRow(_ title: String, detail: String?) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(DarkroomTheme.textTertiary)
                }
            }
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DarkroomTheme.accent)
        }
        .accessibilityLabel(detail.map { "\(title). \($0)" } ?? title)
    }

    private func priceFallbackRow(title: String, showBestValue: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(DarkroomTheme.textPrimary)
            if showBestValue {
                Text(FreemiumCopy.bestValueLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DarkroomTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DarkroomTheme.accent.opacity(0.28), in: Capsule())
            }
            Spacer(minLength: 0)
        }
        .accessibilityLabel(
            showBestValue ? "\(title). \(FreemiumCopy.bestValueLabel)" : title
        )
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
