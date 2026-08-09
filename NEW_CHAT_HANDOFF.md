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
- Phases 1–32 complete (last technical phase: Product Intake + Guided Photo Capture)
- Product pivot documented 2026-08-09 — **no new feature coding until an explicit next phase is approved**
- Last build/tests: succeeded on iPhone 16e (92 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–32
1–31. Prior local listing prep + disconnected AI assistant foundation
32. Product Intake + guided photo plan + system camera capture + Photo Check

## 6. Product pivot (2026-08-09)
Yofai is no longer positioned as a general photo editor. Primary purpose is seller product photo prep: photograph, organize sets, quality check, edit, resize/crop, listing-ready **local** exports for Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar (**export targets only**).

**Abandoned from the active roadmap:** paid/live AI APIs; OAuth marketplace publishing; direct Etsy or any marketplace publishing.

**Future capability (not next work):** backend, accounts, cloud sync, subscriptions, ads — may be added later where they support the product; core photo prep stays local-first/on-device.

## 7. Current models/files
**Intake:** `PhotoPlanSupport.swift` (`PhotoPlanGoal`), `ProductIntakeView.swift`, `ProjectCameraCaptureView.swift`; review fields on `ItemProjectPhoto`

**Tests:** Phase22–32

## 8. Working features
- Product intake/capture, disconnected AI preparation/review (local foundation only), listing information, bulk edit, packages, defaults, duplicate, workspace, queue, batch export, Etsy connection stub (no live OAuth)

## 9. Rules/constraints
- Core photo preparation: local-first/on-device
- Do not implement abandoned-roadmap items (paid AI, OAuth publish, direct marketplace upload) unless re-approved
- Do not invent fake AI copy, fake camera captures, marketplace IDs, category trees, scopes, or compliance limits
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
Status: Phases 1–32 done. Product pivot documented 2026-08-09. No new feature coding until an explicit next phase is approved.
Marketplaces (Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, similar) are local export targets only.
Abandoned from active roadmap: paid/live AI APIs; OAuth marketplace publishing; direct marketplace uploads.
Future capability (not next work): backend, accounts, cloud sync, subscriptions, ads.
Last build/tests succeeded on iPhone 16e (92 tests). App Store upload paused.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not add paid AI APIs, OAuth marketplace publishing, or direct marketplace uploads unless newly re-approved.
Do not invent fake AI listing copy, fake camera captures, marketplace category trees, IDs, scopes, or compliance limits.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: only an explicitly approved local photo-prep phase (e.g. multi-marketplace local export presets when approved). Not live AI / OAuth / upload by default.
If blocked, report why and the safest alternative.
```
