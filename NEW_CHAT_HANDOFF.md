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
- Phases 1–38 complete
- Phase 38: Fill + Crop Reposition (per-photo drag within fill bounds)
- Last build/tests: succeeded on iPhone 16e (153 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–38
1–37. Local listing prep, seller-first nav, export presets, Contain+Pad / Fill+Crop
38. Fill + Crop manual reposition (centered default)

## 6. Phase 38 result
**Fill + Crop Reposition complete.** Extends Phase 37 center-only Fill + Crop with per-photo normalized offsets (-1…1), Edit Reposition / Reset to Center, constrained drag so the canvas stays filled. Contain + Pad unchanged. Build + 153 unit tests passed on iPhone 16e.

## 7. Current models/files
**Export:** `ListingExport.swift` (7 presets + fit modes + `ListingExportFillCropPosition`)
**UI:** `FillCropRepositionView.swift`

**Tests:** Phase22–38

## 8. Working features
- Seller-first Home/Products path, product intake/capture, export canvas Photo Check, Contain+Pad / Fill+Crop with reposition, eBay/Poshmark/Etsy/etc. local export presets, disconnected AI foundation, listing information, bulk edit, packages, defaults, duplicate, workspace, queue, batch export, Etsy connection stub (no live OAuth)

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
Status: Phases 1–38 done. Fill + Crop supports per-photo reposition. Last build/tests succeeded on iPhone 16e (153 tests). App Store upload paused.
Marketplaces are local export targets only. Do not invent new preset pixel sizes.
Abandoned from active roadmap: paid/live AI APIs; OAuth marketplace publishing; direct marketplace uploads.
Future capability (not next work): backend, accounts, cloud sync, subscriptions, ads.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not add paid AI APIs, OAuth marketplace publishing, or direct marketplace uploads unless newly re-approved.
Do not invent fake AI listing copy, fake camera captures, marketplace category trees, IDs, scopes, sizes, or compliance limits.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: only an explicitly approved local photo-prep phase (e.g. FB Marketplace/Mercari presets with verified canvases). Not live AI / OAuth / upload by default.
If blocked, report why and the safest alternative.
```
