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

/// Testable entitlement snapshot. Default shipping state is Free. No StoreKit / network.
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
                message: "Free includes up to \(limit) products. Existing products stay available. Yofai Pro (planned) would unlock unlimited products."
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
    static let plannedProFeature = "Planned Pro Feature"
    static let plannedFutureProFeature = "Coming soon — planned Pro Feature"
    static let keepUsingFree = "Keep using Free"
    static let proNotAvailableYet = "Yofai Pro is not available yet. No purchase is charged."
    static let currentPlanFree = "Current plan: Free"
    static let proPlannedSummary = "Pro will add unlimited products and future extras. Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export."
}

/// In-memory / UserDefaults plan override for tests and future StoreKit. Never fakes a successful purchase.
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

    /// Test / future StoreKit hook only. Does not charge users.
    func setPlanForTesting(_ plan: EntitlementPlan?) {
        overridePlan = plan
    }

    /// Persists plan for future StoreKit restore. Shipping app should only write `.pro` after a real purchase.
    func persistPlan(_ plan: EntitlementPlan) {
        UserDefaults.standard.set(plan.rawValue, forKey: planKey)
        overridePlan = nil
    }

    func resetToLaunchFree() {
        UserDefaults.standard.removeObject(forKey: planKey)
        overridePlan = nil
        limits = .launch
    }
}
