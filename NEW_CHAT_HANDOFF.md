# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Current date
2026-08-08

## 4. Current app status
- iPhone-only SwiftUI + SwiftData
- Local-first listing / photo-prep tool
- Phases 1–32 complete
- Phase 32: Product Intake + Guided Photo Capture
- Last build/tests: succeeded on iPhone 16e (92 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–32
1–31. Prior local listing prep + AI assistant foundation
32. Product Intake + guided photo plan + system camera capture + Photo Check

## 6. Phase 32 result
**Product Intake complete.** Project Detail and Listing Workspace open Product Intake / Capture Photos. Editable local photo-plan goals (starter set optional), one-photo-per-goal attachment, system camera capture with permission/unavailable handling, confirm/retake, append-only project photos, Photo Check with measurable facts + seller review checkboxes. Duplicate copies goal names/order only. Build + 92 unit tests passed on iPhone 16e.

## 7. Current models/files
**Intake:** `PhotoPlanSupport.swift` (`PhotoPlanGoal`), `ProductIntakeView.swift`, `ProjectCameraCaptureView.swift`; review fields on `ItemProjectPhoto`

**Tests:** Phase22–32

## 8. Working features
- Product intake/capture, AI preparation/review (disconnected), listing information, bulk edit, packages, defaults, duplicate, workspace, queue, batch export, Etsy foundation (no live OAuth)

## 9. Rules/constraints
- No live AI / Etsy HTTP / OAuth / backend / publishing / uploads
- Do not invent fake AI copy, fake camera captures, Etsy IDs, category trees, scopes, or marketplace limits
- Keep share architecture stable
- Prefer `/Volumes/CombatMedic/Yofai` on main

## 10. Required before live AI / OAuth / upload
- Approved live-AI provider plan + credentials/policy
- Backend for Etsy token exchange; client secret server-side only
- Real Etsy credentials, scopes, approval (do not invent)

## 11. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, and SESSION_HANDOFF.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Status: Phases 1–32 done. Product intake/capture + local AI assistant foundation + listing workspace/queue/export/packages. No live AI/OAuth/upload. Last build/tests succeeded on iPhone 16e (92 tests). App Store upload paused.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not add AI API keys or Etsy client secret to the iPhone app.
Do not make live AI or Etsy requests unless newly approved with real credentials + backend/provider plan.
Do not invent fake AI listing copy, fake camera captures, Etsy category trees, IDs, scopes, or marketplace limits.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: App Store upload prep, or approved live-AI / live-OAuth/backend/upload phase with credentials supplied.
If blocked, report why and the safest alternative.
```
