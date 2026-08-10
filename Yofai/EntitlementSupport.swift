import Foundation

/// Phase 49 — freemium plan. Free keeps core local export; Pro is additive only.
enum EntitlementPlan: String, Equatable, CaseIterable, Codable {
    case free = "Free"
    case pro = "Pro"

    var displayTitle: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Yofai Pro"
        }
    }
}

/// Central Free limits — change here only; do not scatter magic numbers in views.
struct FreemiumLimits: Equatable {
    /// Active Item Projects Free sellers may create. Existing over-limit projects stay fully usable.
    var freeActiveProductLimit: Int
    /// Soft cap used for Pro marketing / future history tools. Free still keeps and can open all local history.
    var freeExportHistoryHighlightLimit: Int

    static let launch = FreemiumLimits(
        freeActiveProductLimit: 12,
        freeExportHistoryHighlightLimit: 25
    )
}

/// Additive vs core features for Free / Pro policy checks.
enum FreemiumFeature: String, Equatable, CaseIterable, Identifiable {
    case coreLocalExport
    case photoCheck
    case basicEditAndFit
    case createProduct
    case exportNotes
    case viewAndReshareExportedFiles
    case exportHistory
    case unlimitedProducts
    case advancedHistoryTools
    case advancedMultiMarketTools
    case cloudBackupSync
    case directUploadMode

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .coreLocalExport: return "Local JPEG export"
        case .photoCheck: return "Photo Check"
        case .basicEditAndFit: return "Edit, crop, and fit modes"
        case .createProduct: return "Create products"
        case .exportNotes: return "Export notes"
        case .viewAndReshareExportedFiles: return "View and share exported files"
        case .exportHistory: return "Export history"
        case .unlimitedProducts: return "Unlimited products"
        case .advancedHistoryTools: return "Advanced export history tools"
        case .advancedMultiMarketTools: return "Advanced multi-market export tools"
        case .cloudBackupSync: return "Cloud backup and sync"
        case .directUploadMode: return "Direct Upload Mode"
        }
    }

    /// Core Free workflow — must never be locked behind Pro.
    var isCoreFreeWorkflow: Bool {
        switch self {
        case .coreLocalExport, .photoCheck, .basicEditAndFit, .createProduct,
             .exportNotes, .viewAndReshareExportedFiles, .exportHistory:
            return true
        case .unlimitedProducts, .advancedHistoryTools, .advancedMultiMarketTools,
             .cloudBackupSync, .directUploadMode:
            return false
        }
    }
}

enum FeatureAccess: Equatable {
    case available
    case limited(current: Int, limit: Int, message: String)
    case lockedPro(message: String)

    var allowsUse: Bool {
        switch self {
        case .available: return true
        case .limited, .lockedPro: return false
        }
    }

    var limitedMessage: String? {
        switch self {
        case .limited(_, _, let message): return message
        case .lockedPro(let message): return message
        case .available: return nil
        }
    }
}

/// Testable entitlement snapshot. Default shipping state is Free.
struct EntitlementState: Equatable {
    var plan: EntitlementPlan
    var limits: FreemiumLimits

    static let launchFree = EntitlementState(plan: .free, limits: .launch)

    var isPro: Bool { plan == .pro }
}

enum EntitlementPolicy {
    static func access(
        for feature: FreemiumFeature,
        state: EntitlementState,
        activeProductCount: Int = 0
    ) -> FeatureAccess {
        switch feature {
        case .coreLocalExport, .photoCheck, .basicEditAndFit,
             .exportNotes, .viewAndReshareExportedFiles, .exportHistory:
            return .available

        case .createProduct:
            if state.isPro { return .available }
            let limit = state.limits.freeActiveProductLimit
            if activeProductCount < limit {
                return .available
            }
            return .limited(
                current: activeProductCount,
                limit: limit,
                message: "Free includes up to \(limit) products. Existing products stay available. Yofai Pro unlocks unlimited products."
            )

        case .unlimitedProducts:
            if state.isPro { return .available }
            return .lockedPro(message: FreemiumCopy.plannedProFeature)

        case .advancedHistoryTools, .advancedMultiMarketTools:
            if state.isPro { return .available }
            return .lockedPro(message: FreemiumCopy.plannedProFeature)

        case .cloudBackupSync, .directUploadMode:
            // Not implemented for any plan yet — Pro placeholder only.
            return .lockedPro(message: FreemiumCopy.plannedFutureProFeature)
        }
    }

    static func canCreateProduct(activeProductCount: Int, state: EntitlementState) -> Bool {
        access(for: .createProduct, state: state, activeProductCount: activeProductCount).allowsUse
    }

    /// Free sellers always keep core local export — never gated by plan.
    static func freeKeepsCoreLocalExport(state: EntitlementState = .launchFree) -> Bool {
        access(for: .coreLocalExport, state: state).allowsUse
            && FreemiumFeature.coreLocalExport.isCoreFreeWorkflow
    }
}

enum FreemiumCopy {
    static let proTitle = "Yofai Pro"
    static let plannedProFeature = "Pro Feature"
    static let plannedFutureProFeature = "Coming soon — planned Pro Feature"
    static let keepUsingFree = "Keep using Free"
    /// Legacy placeholder string — do not show when live StoreKit purchase buttons are visible.
    static let proNotAvailableYet = "Yofai Pro is not available yet. No purchase is charged."
    static let purchasesUnavailable = "Purchases are not available right now."
    static let purchaseVerificationFailed = "Purchase could not be verified. You were not charged for Pro."
    static let purchaseCancelled = "Purchase cancelled."
    static let purchasePending = "Purchase is pending approval. Pro unlocks after it completes."
    static let purchaseSuccessPro = "Yofai Pro is active."
    static let restoreNoPurchases = "No active Pro subscription found."
    static let currentPlanFree = "Current plan: Free"
    static let currentPlanPro = "Current plan: Yofai Pro"
    static let proPlannedSummary = "Pro adds unlimited products and additive extras. Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export."
    static let proBenefitsIntro = "Yofai Pro is additive. Free keeps the core local export workflow."
    static let manageSubscriptionsHint = "Manage or cancel subscriptions in your Apple ID App Store settings."
    static let restorePurchases = "Restore Purchases"
    static let termsOfUseTitle = "Terms of Use"
    static let privacyStatementTitle = "Privacy Statement"
    static let subscriptionTermsFooter =
        "Subscription terms apply. Manage or cancel subscriptions in App Store settings."
}

/// Phase 54 — legal URLs required on the Pro paywall (Apple Standard EULA + hosted privacy).
enum YofaiProLegalLinks {
    static let termsOfUseTitle = FreemiumCopy.termsOfUseTitle
    static let privacyStatementTitle = FreemiumCopy.privacyStatementTitle
    static let termsOfUseURL = AppStoreLinks.termsOfUse
    static let privacyStatementURL = AppStoreLinks.privacyPolicy
    static let restorePurchasesTitle = FreemiumCopy.restorePurchases

    static var termsOfUseURLString: String { termsOfUseURL.absoluteString }
    static var privacyStatementURLString: String { privacyStatementURL.absoluteString }
}

/// Plan store. Shipping app writes `.pro` only after verified StoreKit entitlement.
@MainActor
final class EntitlementStore {
    static let shared = EntitlementStore()

    private let planKey = "yofai.entitlement.plan.v1"
    private var overridePlan: EntitlementPlan?

    var limits: FreemiumLimits = .launch

    var state: EntitlementState {
        EntitlementState(plan: effectivePlan, limits: limits)
    }

    var effectivePlan: EntitlementPlan {
        if let overridePlan { return overridePlan }
        if let raw = UserDefaults.standard.string(forKey: planKey),
           let plan = EntitlementPlan(rawValue: raw) {
            return plan
        }
        return .free
    }

    /// Test hook only.
    func setPlanForTesting(_ plan: EntitlementPlan?) {
        overridePlan = plan
    }

    /// Persists plan after verified StoreKit entitlement (or explicit Free when none).
    func persistPlan(_ plan: EntitlementPlan) {
        UserDefaults.standard.set(plan.rawValue, forKey: planKey)
        overridePlan = nil
    }

    /// Call only after `StoreEntitlementResolver` / StoreKit verification — never from a fake success path.
    func applyVerifiedStoreKitPlan(_ plan: EntitlementPlan) {
        persistPlan(plan)
    }

    func resetToLaunchFree() {
        UserDefaults.standard.removeObject(forKey: planKey)
        overridePlan = nil
        limits = .launch
    }
}
