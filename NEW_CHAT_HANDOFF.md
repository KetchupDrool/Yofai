# Yofai — Cursor New Chat Handoff

## Current date
2026-08-11

## Project
App: Yofai · Bundle ID: `com.shawnwright.yofai` · iPhone · SwiftUI + SwiftData  
Simulator: **iPhone 16e only** unless approved  
Repo: `/Volumes/CombatMedic/Yofai` · branch `main`

## Current baseline
Latest commit on `main`:

`5c0a462e6de908bce31efa013c41d9aa9d422145`

Message: `Phase 68 paywall and walkthrough clarity.`

Status:
- Working tree clean after Phase 68; `main` = `origin/main` after push
- Phase 68 paywall & walkthrough clarity complete
- **382 tests** last verified on iPhone 16e
- Version **1.0** · Build **1** — not bumped
- **Not archived / not uploaded / not submitted**

## Product direction
Freemium-first, **no-AI**, local-first marketplace photo-prep and listing-prep.  
Local Export Mode only. No Direct Upload / OAuth / API unless newly approved.

## Hard rules
Do **not** add Direct Upload, publishing, login, OAuth, API, scraping, AI, invented FB/Mercari sizes.  
Do **not** archive/upload/submit or mark Connect/TestFlight Passed without Shawn evidence.  
Do **not** change StoreKit product IDs:
- `com.shawnwright.yofai.pro.monthly`
- `com.shawnwright.yofai.pro.yearly`

## Completed recent
- Phase 61–64: local multi-market  
- Phase 65: release gate docs  
- Phase 66: Darkroom readability + form/tab clearance  
- Phase 67: post-readability UI QA polish  
- Icon/Launch Mark artwork update  
- **Phase 68:** paywall prices + Free/Pro lists; remove Cloud backup / Direct Upload from main paywall; slower first-run mini tutorial; focused seller CTAs  

## Recommended next
Continue Connect §B in `SHAWN_NEXT_RELEASE_STEPS.md` (IAP products), then screenshots → bump → archive when Shawn approves.

Or optional polish Shawn requests before archive.

## First prompt

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, SESSION_HANDOFF.md, and SHAWN_NEXT_RELEASE_STEPS.md first.

Baseline: Phase 68 paywall/walkthrough clarity on main. 382 tests. Version 1.0 (1).
Working tree was clean. Local Export Mode only. Not archived.

Next: Shawn manual release gates (Connect IAP §B) — do not archive/upload/submit unless approved.
No Direct Upload / OAuth / API / AI. StoreKit IDs unchanged. iPhone 16e only.

Work in /Volumes/CombatMedic/Yofai on main.
```
