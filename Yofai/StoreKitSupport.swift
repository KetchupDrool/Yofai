import Foundation
import StoreKit
import Combine

// MARK: - Product IDs (Phase 53)

/// Central StoreKit product identifiers. Create matching products in App Store Connect before launch.
enum YofaiProductIDs {
    static let monthly = "com.shawnwright.yofai.pro.monthly"
    static let yearly = "com.shawnwright.yofai.pro.yearly"

    static let allProSubscriptions: [String] = [monthly, yearly]

    /// Docs / App Store Connect setup notes only — never use as live UI price when StoreKit loads.
    static let intendedMonthlyPriceNote = "$4.99/month"
    static let intendedYearlyPriceNote = "$39.99/year"

    static func isProSubscription(_ productID: String) -> Bool {
        allProSubscriptions.contains(productID)
    }
}

// MARK: - Models

struct YofaiStoreProduct: Identifiable, Equatable, Hashable {
    var id: String
    var displayName: String
    var displayPrice: String
    var periodLabel: String

    var purchaseButtonTitle: String {
        "\(periodLabel) — \(displayPrice)"
    }

    /// Yearly is the Best value plan on the paywall.
    var isBestValue: Bool {
        id == YofaiProductIDs.yearly
    }
}

enum PurchaseOutcome: Equatable {
    case success
    case cancelled
    case pending
    case failed(message: String)
}

enum ProductsLoadState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable
}

enum StoreEntitlementResolver {
    /// Maps verified active Pro subscription product IDs to a plan. Failed verification → Free.
    static func plan(
        fromVerifiedProductIDs productIDs: Set<String>,
        failedVerification: Bool = false
    ) -> EntitlementPlan {
        if failedVerification { return .free }
        let ownsPro = productIDs.contains { YofaiProductIDs.isProSubscription($0) }
        return ownsPro ? .pro : .free
    }
}

// MARK: - Service protocol

protocol PurchaseServicing: AnyObject {
    func loadProducts() async throws -> [YofaiStoreProduct]
    func purchase(productID: String) async -> PurchaseOutcome
    func restorePurchases() async -> PurchaseOutcome
    func resolvedPlan() async -> EntitlementPlan
}

// MARK: - Mock (tests / previews)

@MainActor
final class MockPurchaseService: PurchaseServicing {
    var products: [YofaiStoreProduct] = []
    var resolvedPlan: EntitlementPlan
    var ownedProductIDs: Set<String>
    var loadShouldFail = false
    var nextPurchaseResult: PurchaseOutcome = .success
    var nextRestoreResult: PurchaseOutcome = .success
    var resolvedPlanAfterPurchase: EntitlementPlan?
    var resolvedPlanAfterRestore: EntitlementPlan?

    static let sampleProducts: [YofaiStoreProduct] = [
        YofaiStoreProduct(
            id: YofaiProductIDs.monthly,
            displayName: "Yofai Pro Monthly",
            displayPrice: "$4.99",
            periodLabel: "Monthly"
        ),
        YofaiStoreProduct(
            id: YofaiProductIDs.yearly,
            displayName: "Yofai Pro Yearly",
            displayPrice: "$39.99",
            periodLabel: "Yearly"
        )
    ]

    init(
        resolvedPlan: EntitlementPlan = .free,
        ownedProductIDs: Set<String> = [],
        products: [YofaiStoreProduct]? = nil
    ) {
        self.resolvedPlan = resolvedPlan
        self.ownedProductIDs = ownedProductIDs
        if let products {
            self.products = products
        }
    }

    func loadProducts() async throws -> [YofaiStoreProduct] {
        if loadShouldFail {
            throw NSError(domain: "MockPurchaseService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Products unavailable"
            ])
        }
        return products
    }

    func purchase(productID: String) async -> PurchaseOutcome {
        let result = nextPurchaseResult
        if case .success = result {
            ownedProductIDs.insert(productID)
            if let resolvedPlanAfterPurchase {
                resolvedPlan = resolvedPlanAfterPurchase
            }
        }
        return result
    }

    func restorePurchases() async -> PurchaseOutcome {
        let result = nextRestoreResult
        if case .success = result, let resolvedPlanAfterRestore {
            resolvedPlan = resolvedPlanAfterRestore
        }
        return result
    }

    func resolvedPlan() async -> EntitlementPlan {
        resolvedPlan
    }
}

// MARK: - StoreKit 2 service

@MainActor
final class StoreKitPurchaseService: PurchaseServicing {
    func loadProducts() async throws -> [YofaiStoreProduct] {
        let storeProducts = try await Product.products(for: YofaiProductIDs.allProSubscriptions)
        return storeProducts
            .sorted { lhs, rhs in
                periodRank(lhs) < periodRank(rhs)
            }
            .map { product in
                YofaiStoreProduct(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    periodLabel: periodLabel(for: product)
                )
            }
    }

    func purchase(productID: String) async -> PurchaseOutcome {
        do {
            let storeProducts = try await Product.products(for: [productID])
            guard let product = storeProducts.first else {
                return .failed(message: FreemiumCopy.purchasesUnavailable)
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    return .success
                case .unverified:
                    return .failed(message: FreemiumCopy.purchaseVerificationFailed)
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(message: FreemiumCopy.purchasesUnavailable)
            }
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    func restorePurchases() async -> PurchaseOutcome {
        do {
            try await AppStore.sync()
            return .success
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }

    func resolvedPlan() async -> EntitlementPlan {
        var verifiedIDs = Set<String>()
        var sawUnverified = false
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if YofaiProductIDs.isProSubscription(transaction.productID) {
                    verifiedIDs.insert(transaction.productID)
                }
            case .unverified:
                sawUnverified = true
            }
        }
        if verifiedIDs.isEmpty && sawUnverified {
            return StoreEntitlementResolver.plan(fromVerifiedProductIDs: [], failedVerification: true)
        }
        return StoreEntitlementResolver.plan(fromVerifiedProductIDs: verifiedIDs)
    }

    private func periodLabel(for product: Product) -> String {
        guard let subscription = product.subscription else { return "Subscription" }
        switch subscription.subscriptionPeriod.unit {
        case .month:
            return subscription.subscriptionPeriod.value == 1 ? "Monthly" : "Every \(subscription.subscriptionPeriod.value) months"
        case .year:
            return subscription.subscriptionPeriod.value == 1 ? "Yearly" : "Every \(subscription.subscriptionPeriod.value) years"
        case .week:
            return "Weekly"
        case .day:
            return "Daily"
        @unknown default:
            return "Subscription"
        }
    }

    private func periodRank(_ product: Product) -> Int {
        switch product.subscription?.subscriptionPeriod.unit {
        case .month: return 0
        case .year: return 1
        default: return 2
        }
    }
}

// MARK: - Purchase manager (views use this; not StoreKit directly)

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published private(set) var products: [YofaiStoreProduct] = []
    @Published private(set) var productsLoadState: ProductsLoadState = .idle
    @Published private(set) var isBusy = false
    @Published var statusMessage: String?

    private var service: PurchaseServicing
    private var updatesTask: Task<Void, Never>?

    init(service: PurchaseServicing? = nil) {
        self.service = service ?? StoreKitPurchaseService()
    }

    /// Production singleton wiring. Tests construct `PurchaseManager(service:)`.
    func useStoreKitService() {
        service = StoreKitPurchaseService()
    }

    func resetForTesting() {
        products = []
        productsLoadState = .idle
        isBusy = false
        statusMessage = nil
        updatesTask?.cancel()
        updatesTask = nil
        service = MockPurchaseService()
    }

    func startListeningForTransactionsIfNeeded() {
        guard updatesTask == nil else { return }
        guard service is StoreKitPurchaseService else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self.refreshEntitlementsAndProducts()
            }
        }
    }

    func refreshEntitlementsAndProducts() async {
        let plan = await service.resolvedPlan()
        EntitlementStore.shared.applyVerifiedStoreKitPlan(plan)

        productsLoadState = .loading
        do {
            let loaded = try await service.loadProducts()
            products = loaded
            if loaded.isEmpty {
                productsLoadState = .unavailable
                statusMessage = FreemiumCopy.purchasesUnavailable
            } else {
                productsLoadState = .loaded
                if statusMessage == FreemiumCopy.purchasesUnavailable {
                    statusMessage = nil
                }
            }
        } catch {
            products = []
            productsLoadState = .unavailable
            statusMessage = FreemiumCopy.purchasesUnavailable
        }
    }

    func purchase(productID: String) async -> PurchaseOutcome {
        isBusy = true
        defer { isBusy = false }
        let outcome = await service.purchase(productID: productID)
        switch outcome {
        case .success:
            let plan = await service.resolvedPlan()
            EntitlementStore.shared.applyVerifiedStoreKitPlan(plan)
            statusMessage = plan == .pro ? FreemiumCopy.purchaseSuccessPro : FreemiumCopy.restoreNoPurchases
        case .cancelled:
            statusMessage = FreemiumCopy.purchaseCancelled
        case .pending:
            statusMessage = FreemiumCopy.purchasePending
        case .failed(let message):
            statusMessage = message
        }
        return outcome
    }

    func restorePurchases() async -> PurchaseOutcome {
        isBusy = true
        defer { isBusy = false }
        let outcome = await service.restorePurchases()
        let plan = await service.resolvedPlan()
        EntitlementStore.shared.applyVerifiedStoreKitPlan(plan)
        switch outcome {
        case .success:
            statusMessage = plan == .pro ? FreemiumCopy.purchaseSuccessPro : FreemiumCopy.restoreNoPurchases
        case .cancelled:
            statusMessage = FreemiumCopy.purchaseCancelled
        case .pending:
            statusMessage = FreemiumCopy.purchasePending
        case .failed(let message):
            statusMessage = message
        }
        return outcome
    }
}
