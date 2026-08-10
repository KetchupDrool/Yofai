# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Current date
2026-08-10

## 4. Current app status
- iPhone-only SwiftUI + SwiftData
- **Product purpose:** local-first marketplace product photo preparation for online sellers
- Core functionality is local-first/on-device
- Phases 1–48 complete
- Phase 48: final Local Export Mode polish (post-export next step, DT/a11y, wording)
- Local Export Mode is current. Direct Upload Mode is future-only and not implemented
- Last build/tests: succeeded on iPhone 16e (270 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/
- Roadmap: `MARKETPLACE_UPLOAD_ROADMAP.md`

## 5. Completed phases 1–48
1–47. Local listing prep through export file access
48. Final Local Export Mode polish before App Store prep

## 6. Phase 48 result
**Final Local Export Mode polish complete.** After export, sellers get a clear View Exported Files next step on the just-created batch. History actions ordered View/Share then More. Dynamic Type and accessibility improved on export/readiness surfaces. Wording stays local/manual/exported-for. No Direct Upload. Build + 270 unit tests passed on iPhone 16e.

## 7. Current models/files
**Modes:** `YofaiProductMode.swift`  
**Share polish:** `LocalExportShareSupport.swift`  
**File access:** `ExportBatchFileAccessSupport.swift`, `ExportedFilesViewer.swift`  
**Post-export:** `LocalExportPostExportSupport.swift`, `LocalExportNextStepActions.swift`  
**Roadmap:** `MARKETPLACE_UPLOAD_ROADMAP.md`

**Tests:** Phase22–48

## 8. Working features
- Local export end-to-end: prep → export → view/share files → notes → history filters/compare
- Fit modes + reposition, verified canvases, readiness, prep tips, packages, queue

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
Status: Phases 1–48 done. Local Export Mode is current and polished. Direct Upload Mode is future-only and not implemented. App Store upload paused.
Marketplaces are local export targets today. Do not invent new preset pixel sizes.
Do not implement Direct Upload Mode, browser automation, unofficial APIs, marketplace passwords, or paid/live AI unless newly re-approved.
Future capability (not next work by default): backend, accounts, cloud sync, subscriptions, ads, verified Direct Upload Mode.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not change Share sheet architecture unless fixing a proven bug (optional caption already allowed).
Build once on iPhone 16e when you change code.

Next: only an explicitly approved phase. Prefer App Store prep for Local Export Mode unless a verified upload foundation phase is approved.
If blocked, report why and the safest alternative.
```
