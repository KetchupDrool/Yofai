# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Current date
2026-08-09

## 4. Current app status
- iPhone-only SwiftUI + SwiftData
- **Product purpose:** local-first marketplace product photo preparation for online sellers
- Core functionality is local-first/on-device
- Phases 1–39 complete
- Phase 39: Marketplace target vs export canvas; export readiness; preview; no invented FB/Mercari sizes
- Last build/tests: succeeded on iPhone 16e (172 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–39
1–38. Local listing prep, fit modes, Fill + Crop reposition, verified eBay/Poshmark canvases
39. Marketplace export expansion (target/canvas split; guidance for unverified markets)

## 6. Phase 39 result
**Marketplace Export Expansion complete.** Marketplace destination is separate from pixel export size. Etsy/eBay/Poshmark can recommend existing verified canvases. Facebook Marketplace and Mercari intentionally have **no** named pixel presets (no defensible exact first-party canvas as of 2026-08-09). Export readiness + shared preview use local facts / same render path. Build + 172 unit tests passed on iPhone 16e.

## 7. Current models/files
**Export:** `ListingExport.swift` (7 presets), `MarketplaceExportSupport.swift`, `ExportPreviewCard.swift`

**Tests:** Phase22–39

## 8. Working features
- Seller-first path, marketplace target switching, export readiness, export preview, Contain+Pad / Fill+Crop + reposition, verified eBay/Poshmark/Etsy canvases, guidance for FB Marketplace/Mercari without fake sizes, listing prep, bulk edit, packages, defaults, queue, batch export

## 9. Rules/constraints
- Core photo preparation: local-first/on-device
- Do not invent marketplace pixel sizes or compliance claims
- Do not implement abandoned-roadmap items (paid AI, OAuth publish, direct marketplace upload) unless re-approved
- Keep share architecture stable
- Prefer `/Volumes/CombatMedic/Yofai` on main

## 10. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, and SESSION_HANDOFF.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Purpose: local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Status: Phases 1–39 done. Marketplace target separate from export canvas. No FB Marketplace/Mercari named pixel presets. Last build/tests succeeded on iPhone 16e (172 tests). App Store upload paused.
Marketplaces are local export targets only. Do not invent new preset pixel sizes.
Abandoned from active roadmap: paid/live AI APIs; OAuth marketplace publishing; direct marketplace uploads.
Future capability (not next work): backend, accounts, cloud sync, subscriptions, ads.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not add paid AI APIs, OAuth marketplace publishing, or direct marketplace uploads unless newly re-approved.
Do not invent fake AI listing copy, fake camera captures, marketplace category trees, IDs, scopes, sizes, or compliance limits.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: only an explicitly approved local photo-prep phase. Not live AI / OAuth / upload by default.
If blocked, report why and the safest alternative.
```
