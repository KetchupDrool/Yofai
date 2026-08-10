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
- Phases 1–41 complete
- Phase 41: export-history marketplace filters + metadata compare + Export Again
- Last build/tests: succeeded on iPhone 16e (198 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–41
1–40. Local listing prep, fit modes, reposition, marketplace target vs canvas, export history labels
41. Export history filters (transient), metadata-only compare of newest two, Export Again (settings only)

## 6. Phase 41 result
**Export History Filters & Compare Polish complete.** Sellers can filter history by stored marketplace target, compare the two newest completed exports (metadata only), and use Export Again to restore export-level settings without auto-exporting or changing photo edits. Build + 198 unit tests passed on iPhone 16e.

## 7. Current models/files
**Export:** `ProjectExportBatch`, `ExportHistorySupport.swift`, `ExportHistorySection.swift`

**Tests:** Phase22–41

## 8. Working features
- Marketplace filters on export history, recent-export metadata compare, Export Again / Use These Export Settings, marketplace target switching, Contain+Pad / Fill+Crop + reposition, verified eBay/Poshmark/Etsy canvases, FB Marketplace/Mercari guidance without fake sizes, listing prep, bulk edit, packages, defaults, queue, batch export

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
Status: Phases 1–41 done. Export history has marketplace filters and metadata compare. Last build/tests succeeded on iPhone 16e (198 tests). App Store upload paused.
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
