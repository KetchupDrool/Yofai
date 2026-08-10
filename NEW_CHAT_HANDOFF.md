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
- Phases 1–46 complete
- Phase 46: local export/share polish; optional note as share caption / Copy Export Note
- Local Export Mode is current. Direct Upload Mode is future-only and not implemented
- Last build/tests: succeeded on iPhone 16e (254 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/
- Roadmap: `MARKETPLACE_UPLOAD_ROADMAP.md`

## 5. Completed phases 1–46
1–45. Local listing prep through upload feasibility roadmap
46. Local export share polish (labels, summary, optional note share/copy)

## 6. Phase 46 result
**Local share polish complete.** Clearer local JPEG / manual upload / exported-for wording. Cleaner post-export summary. History rows distinguish marketplace, canvas, local result, and optional note. Share Exported Photos (default, no caption); Share with Note / Copy Export Note when a note exists. No Direct Upload, OAuth upload, publish status, or note embedding in pixels.

## 7. Current models/files
**Modes:** `YofaiProductMode.swift`  
**Share polish:** `LocalExportShareSupport.swift`  
**Share payload:** `ShareBatchItem` optional `caption` → `activityItems`  
**Roadmap:** `MARKETPLACE_UPLOAD_ROADMAP.md`

**Tests:** Phase22–46

## 8. Working features
- Local export, share polish, batch notes, prep tips, readiness, history filters/compare, fit modes + reposition, verified canvases, FB/Mercari guidance, listing prep, bulk edit, packages, defaults, queue

## 9. Rules/constraints
- Core photo preparation: local-first/on-device
- Do not invent marketplace pixel sizes or compliance claims
- Do not implement Direct Upload Mode or paid/live AI unless re-approved
- No browser automation / unofficial APIs / marketplace passwords
- Keep share architecture stable (optional caption only)
- Prefer `/Volumes/CombatMedic/Yofai` on main

## 10. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, SESSION_HANDOFF.md, and MARKETPLACE_UPLOAD_ROADMAP.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Purpose: local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Status: Phases 1–46 done. Local Export Mode is current. Direct Upload Mode is future-only and not implemented. App Store upload paused.
Marketplaces are local export targets today. Do not invent new preset pixel sizes.
Do not implement Direct Upload Mode, browser automation, unofficial APIs, marketplace passwords, or paid/live AI unless newly re-approved.
Future capability (not next work by default): backend, accounts, cloud sync, subscriptions, ads, verified Direct Upload Mode.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not change Share sheet architecture unless fixing a proven bug (optional caption already allowed).
Build once on iPhone 16e when you change code.

Next: only an explicitly approved phase. Prefer Local Export Mode polish unless a verified upload foundation phase is approved.
If blocked, report why and the safest alternative.
```
