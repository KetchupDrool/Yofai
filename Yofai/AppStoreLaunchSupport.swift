import Foundation

/// Phase 50/51 — App Store launch positioning and review-safe claim checks.
/// Yofai is a no-AI, local-first marketplace photo-prep app.
enum AppStoreLaunchSupport {
    static let displayName = "Yofai"
    static let bundleID = "com.shawnwright.yofai"
    static let subtitlePrimary = "Marketplace photo prep"
    static let oneLinePositioning =
        "Marketplace product photo prep that exports local JPEGs for manual upload."

    static let privacySummary =
        "Photos, projects, edits, export history, and notes stay on your device. No account, no backend, no ads, no analytics SDK, no marketplace upload, and no AI service."

    static let freemiumLaunchNote =
        "Free keeps the core local export workflow. Yofai Pro is planned and not available yet. No purchase is charged."

    static let whatItDoesNotDo: [String] = [
        "Does not upload or publish to marketplaces",
        "Does not claim marketplace compliance or approval",
        "Does not require an account or network for local export",
        "Does not charge for Pro in this version",
        "Does not use AI"
    ]

    /// Seller-facing Etsy connection label while live OAuth remains disabled.
    static let etsyConnectionUnavailableTitle = "Etsy connection not available"
    static let etsyConnectionUnavailableDetail =
        "Live Etsy OAuth is not enabled. Yofai prepares local JPEGs for manual upload only."

    static func containsRiskyAppStoreClaim(_ text: String) -> Bool {
        let lower = text.lowercased()
        let banned = [
            "upload to etsy",
            "publish to ebay",
            "send to marketplace",
            "marketplace compliant",
            "marketplace approved",
            "approved by etsy",
            "approved by ebay",
            "ai-powered",
            "ai listing",
            "openai",
            "gpt-",
            "guaranteed sales",
            "free forever",
            "subscribe now",
            "buy pro",
            "restore purchases"
        ]
        return banned.contains { lower.contains($0) }
    }

    /// True when copy still implies an AI product feature (should be absent from UI).
    static func containsActiveAIProductClaim(_ text: String) -> Bool {
        let lower = text.lowercased()
        let banned = [
            "ai listing assistant",
            "ai-powered",
            "openai",
            "request ai",
            "ready for ai",
            "ai is not connected",
            "live ai",
            "paid ai"
        ]
        return banned.contains { lower.contains($0) }
    }
}
