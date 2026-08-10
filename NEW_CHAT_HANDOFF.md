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
- Phases 1–49 complete
- Phase 48: final Local Export Mode polish
- Phase 49: freemium foundation (entitlements, Free product limit, Pro placeholder; no StoreKit charges)
- Local Export Mode is current. Direct Upload Mode is future-only and not implemented
- Freemium-first if monetized
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- Roadmap: `MARKETPLACE_UPLOAD_ROADMAP.md`

## 5. Completed phases 1–49
1–48. Local listing prep through final Local Export Mode polish
49. Freemium foundation & entitlement planning

## 6. Phase 49 result
**Freemium foundation complete.** Centralized Free/Pro policy with default Free. Free active-product limit 12 (no deletion of existing products). Core local export / Photo Check / edit / notes / view-share / history remain Free. Settings shows Yofai Pro planned placeholder with no purchase. StoreKit not implemented.

## 7. Current models/files
**Entitlements:** `EntitlementSupport.swift`, `YofaiProPlaceholderView.swift`  
**Modes:** `YofaiProductMode.swift`  
**Local export polish:** Phase 46–48 share/file/next-step helpers  
**Roadmap:** `MARKETPLACE_UPLOAD_ROADMAP.md`

**Tests:** Phase22–49

## 8. Working features
- Full Local Export Mode Free workflow + freemium gates for extra product creation
- Pro preview only (coming soon)

## 9. Rules/constraints
- Freemium-first if monetized; Pro additive; no bait-and-switch
- Do not invent marketplace pixel sizes or compliance claims
- Do not implement Direct Upload Mode, StoreKit charges, or paid/live AI unless re-approved
- No browser automation / unofficial APIs / marketplace passwords
- Prefer `/Volumes/CombatMedic/Yofai` on main

## 10. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, SESSION_HANDOFF.md, and MARKETPLACE_UPLOAD_ROADMAP.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Purpose: local-first marketplace product photo preparation for online sellers.
Status: Phases 1–49 done. Local Export Mode is current. Freemium foundation is in place (Free default; Pro planned; no StoreKit charges yet). Direct Upload Mode is future-only. App Store upload paused.
Do not lock core Free local-export features behind Pro later.
Do not implement Direct Upload Mode, browser automation, unofficial APIs, marketplace passwords, fake purchases, or paid/live AI unless newly re-approved.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Build once on iPhone 16e when you change code.

Next: only an explicitly approved phase. Prefer App Store prep, or StoreKit Pro payments, or verified upload foundation.
If blocked, report why and the safest alternative.
```
