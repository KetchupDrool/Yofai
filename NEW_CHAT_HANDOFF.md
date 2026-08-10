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
- Phases 1–42 complete
- Phase 42: seller export readiness checklist (computed from local state)
- Last build/tests: succeeded on iPhone 16e (213 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–42
1–41. Local listing prep, fit modes, reposition, marketplace vs canvas, export history filters/compare
42. Export Readiness checklist on Project Detail (compact) and Listing Workspace (full)

## 6. Phase 42 result
**Seller Export Readiness Checklist complete.** Sellers see Ready to export / Review before export / Needs attention from Photos, Marketplace, Export size, Fit, Photo Check, and optional Watermark. Reuses Photo Check facts; not persisted; no compliance claims. Build + 213 unit tests passed on iPhone 16e.

## 7. Current models/files
**Export:** `ExportReadiness` (+ checklist items), `ExportReadinessChecklistSection.swift`, `MarketplaceExportSettingsBlock`, `ExportHistorySupport.swift`

**Tests:** Phase22–42

## 8. Working features
- Export readiness checklist, marketplace filters/compare, Export Again, marketplace target switching, Contain+Pad / Fill+Crop + reposition, verified eBay/Poshmark/Etsy canvases, FB Marketplace/Mercari guidance without fake sizes, listing prep, bulk edit, packages, defaults, queue, batch export

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
Status: Phases 1–42 done. Export readiness checklist is computed locally. Last build/tests succeeded on iPhone 16e (213 tests). App Store upload paused.
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
