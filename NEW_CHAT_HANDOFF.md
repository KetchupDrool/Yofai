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
- Phases 1–44 complete
- Phase 44: optional local notes on export history batches
- Last build/tests: succeeded on iPhone 16e (240 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–44
1–43. Local listing prep through prep tips
44. Optional seller notes on completed `ProjectExportBatch` rows

## 6. Phase 44 result
**Seller Export Batch Notes complete.** Sellers can optionally add/edit/remove a short local note on a completed export batch (e.g. “eBay draft”). Notes are not publish status and never required. Build + 240 unit tests passed on iPhone 16e.

## 7. Current models/files
**Export:** `ProjectExportBatch.sellerNote`, `ExportBatchNoteSupport.swift`, `ExportBatchNoteEditor.swift`, prep tips, readiness, history filters

**Tests:** Phase22–44

## 8. Working features
- Export batch notes, prep tips, readiness checklist, history filters/compare, Export Again, fit modes + reposition, verified canvases, FB/Mercari guidance, listing prep, bulk edit, packages, defaults, queue, batch export

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
Status: Phases 1–44 done. Export batches can carry optional local seller notes. Last build/tests succeeded on iPhone 16e (240 tests). App Store upload paused.
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
