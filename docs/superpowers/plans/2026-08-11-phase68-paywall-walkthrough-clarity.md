# Phase 68 Paywall & Walkthrough Clarity Implementation Plan

> **For agentic workers:** Inline execution in this session (user approved Approach 1 + implement/commit/push).

**Goal:** Clarify paywall prices/benefits and upgrade first-run walkthrough before archive.

**Architecture:** Extend existing `FreemiumCopy`, `YofaiProPaywallView`, `FirstLaunchGuide*` support/views/scenes, and focused `SellerNavigationSupport` labels. No new paywall/walkthrough frameworks.

**Tech Stack:** SwiftUI, StoreKit 2, XCTest, iPhone 16e.

## Global Constraints
- Product IDs: `com.shawnwright.yofai.pro.monthly`, `com.shawnwright.yofai.pro.yearly`
- No Direct Upload / OAuth / API / AI / archive / upload / submit / build bump
- Facebook Marketplace + Mercari recommended presets remain nil
- Phase number for tests/commit: **68** (avoid colliding with Phase 67 QA)

---

### Task 1: Paywall copy + pricing helpers

**Files:**
- Modify: `Yofai/EntitlementSupport.swift` (`FreemiumCopy`)
- Modify: `Yofai/StoreKitSupport.swift` (`YofaiStoreProduct` best-value helpers)
- Modify: `Yofai/YofaiProPlaceholderView.swift`
- Test: `YofaiTests/Phase68PaywallWalkthroughClarityTests.swift`

- [x] Centralize Free includes / Pro adds / Best value / intended price labels
- [x] Paywall UI: Free vs Pro lists; hide cloud/direct; Best value; fallback prices when unavailable
- [x] Tests for prices, Best value, benefit lists, IDs, banned marketing

### Task 2: Walkthrough pages + slower motion + scenes

**Files:**
- Modify: `Yofai/FirstLaunchGuideSupport.swift`
- Modify: `Yofai/FirstLaunchGuideView.swift`
- Modify: `Yofai/FirstLaunchGuideScenes.swift`
- Modify: `YofaiTests/Phase59FirstLaunchGuideTests.swift` (page order + slower timing bounds)
- Test: `YofaiTests/Phase68PaywallWalkthroughClarityTests.swift`

- [x] Expand pages + bullet copy for required topics
- [x] Slow motion timings; Reduce Motion stays nil
- [x] Demo scenes for new pages
- [x] Title + bullets UI

### Task 3: Focused seller wording

**Files:**
- Modify: `Yofai/SellerNavigationSupport.swift`
- Modify: `YofaiTests/Phase35SellerFirstNavigationTests.swift` (expected strings)
- Optionally: `Yofai/MarketplaceListingDraftSupport.swift` open-primary label if still “Prepare Listing…”

### Task 4: Verify, commit, push

- Full tests + iPhone 16e build
- Commit + push `main`
- Update handoff docs to tip

## Spec coverage
Paywall prices/fallback/Best value/Free-Pro lists/remove future marketing ✓  
Walkthrough topics + slower motion + Reduce Motion ✓  
Seller wording focused ✓  
IDs/presets/no archive ✓
