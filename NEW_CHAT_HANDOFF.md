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
- Phases 1–33 complete
- Phase 33: Seller Export Preset Clarity
- Last build/tests: succeeded on iPhone 16e (100 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–33
1–32. Local listing prep, intake/capture, disconnected AI foundation
33. Seller export preset clarity (display titles, Listing vs Other canvas groups, pixel labels, Home copy)

## 6. Phase 33 result
**Seller Export Preset Clarity complete.** Stored raw values and pixel sizes unchanged. Marketplace displays as “Square 1600”; presets grouped Listing vs Other canvas; pickers show W×H; local-export disclaimer on Edit / Project Detail / Seller Defaults; Home + Projects empty copy match north star. Build + 100 unit tests passed on iPhone 16e.

## 7. Current models/files
**Export clarity:** `ListingExport.swift` (`displayTitle`, `pickerLabel`, `sellerGroup`, `localExportDisclaimer`)

**Tests:** Phase22–33

## 8. Working features
- Product intake/capture, disconnected AI preparation/review (local foundation only), listing information, bulk edit, packages, defaults, duplicate, workspace, queue, batch export, clarified seller export presets, Etsy connection stub (no live OAuth)

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
Status: Phases 1–33 done. Seller export preset clarity complete. Last build/tests succeeded on iPhone 16e (100 tests). App Store upload paused.
Marketplaces are local export targets only. Do not invent new preset pixel sizes.
Abandoned from active roadmap: paid/live AI APIs; OAuth marketplace publishing; direct marketplace uploads.
Future capability (not next work): backend, accounts, cloud sync, subscriptions, ads.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not add paid AI APIs, OAuth marketplace publishing, or direct marketplace uploads unless newly re-approved.
Do not invent fake AI listing copy, fake camera captures, marketplace category trees, IDs, scopes, sizes, or compliance limits.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: only an explicitly approved local photo-prep phase (e.g. verified multi-marketplace local export sizes, or cover/crop fit when approved). Not live AI / OAuth / upload by default.
If blocked, report why and the safest alternative.
```
