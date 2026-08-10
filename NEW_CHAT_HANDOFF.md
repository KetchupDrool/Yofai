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
- Phases 1–45 complete
- Phase 45: Local Export Mode vs future Direct Upload Mode documented; no upload implemented
- Last build/tests: succeeded on iPhone 16e (246 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/
- Roadmap: `MARKETPLACE_UPLOAD_ROADMAP.md`

## 5. Completed phases 1–45
1–44. Local listing prep through export batch notes
45. Upload feasibility audit + roadmap reset (documentation; Local Export Mode remains current)

## 6. Phase 45 result
**Roadmap reset complete.** Confirmed local-export-only code behavior. Documented Local Export Mode (permanent) and Direct Upload Mode (future, official API/OAuth only). Feasibility matrix favors Etsy as the only maybe-first candidate after manual verification. No upload/OAuth secrets/backend vendors/browser automation/AI added. Build + 246 unit tests passed on iPhone 16e.

## 7. Current models/files
**Modes:** `YofaiProductMode.swift`  
**Roadmap:** `MARKETPLACE_UPLOAD_ROADMAP.md`  
**Export:** history, notes, readiness, prep tips (local only)

**Tests:** Phase22–45

## 8. Working features
- Local export, batch notes, prep tips, readiness, history filters/compare, fit modes + reposition, verified canvases, FB/Mercari guidance, listing prep, bulk edit, packages, defaults, queue

## 9. Rules/constraints
- Core photo preparation: local-first/on-device
- Do not invent marketplace pixel sizes or compliance claims
- Do not implement Direct Upload Mode or paid/live AI unless re-approved
- No browser automation / unofficial APIs / marketplace passwords
- Keep share architecture stable
- Prefer `/Volumes/CombatMedic/Yofai` on main

## 10. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, SESSION_HANDOFF.md, and MARKETPLACE_UPLOAD_ROADMAP.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Purpose: local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Status: Phases 1–45 done. Local Export Mode is current. Direct Upload Mode is future-only and not implemented. App Store upload paused.
Marketplaces are local export targets today. Do not invent new preset pixel sizes.
Do not implement Direct Upload Mode, browser automation, unofficial APIs, marketplace passwords, or paid/live AI unless newly re-approved.
Future capability (not next work by default): backend, accounts, cloud sync, subscriptions, ads, verified Direct Upload Mode.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: only an explicitly approved phase. Prefer Local Export Mode polish unless a verified upload foundation phase is approved.
If blocked, report why and the safest alternative.
```
