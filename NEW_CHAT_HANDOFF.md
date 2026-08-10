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
- Phases 1–37 complete
- Phase 37: Cover/Crop Export Fit Mode (Contain + Pad default + Fill + Crop center)
- Last build/tests: succeeded on iPhone 16e (138 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–37
1–36. Local listing prep, seller-first nav, export clarity, canvas check, eBay/Poshmark presets
37. Seller-selectable export fit: Contain + Pad / Fill + Crop (center)

## 6. Phase 37 result
**Cover/Crop Export Fit Mode complete.** Phase 37 supersedes Phase 20 contain+pad-only. Sellers choose Contain + Pad (default, backward compatible) or Fill + Crop (center crop). Exact preset canvases unchanged. Photo Check reports padding vs cropping expected. Build + 138 unit tests passed on iPhone 16e.

## 7. Current models/files
**Export:** `ListingExport.swift` (7 presets + `ListingExportFitMode`)

**Tests:** Phase22–37

## 8. Working features
- Seller-first Home/Products path, product intake/capture, export canvas Photo Check, Contain+Pad / Fill+Crop fit, eBay/Poshmark/Etsy/etc. local export presets, disconnected AI foundation, listing information, bulk edit, packages, defaults, duplicate, workspace, queue, batch export, Etsy connection stub (no live OAuth)

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
Status: Phases 1–37 done. Export fit modes: Contain + Pad (default) + Fill + Crop (center). Last build/tests succeeded on iPhone 16e (138 tests). App Store upload paused.
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
