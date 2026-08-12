# Yofai — Cursor New Chat Handoff

## Current date
2026-08-11

## Project
App: Yofai · Bundle ID: `com.shawnwright.yofai` · iPhone · SwiftUI + SwiftData  
Simulator: **iPhone 16e only** unless approved  
Repo: `/Volumes/CombatMedic/Yofai` · branch `main`

## Current baseline
Latest commit on `main`:

`4fcbfb5786103869907a7a268d3e64f5b7ad5656`

Message: `Point handoff at tip after Phase 68–71 work.`

Prior product tip:

`7af774cb66db4efd79447c4f3ce573afcb7ae77a` — LaunchMark 160pt sizing.

Status:
- Working tree clean; `main` = `origin/main`
- Phases 68–71 complete on tip
- **~397 tests** (Phase 71 LaunchMark sizing added; full suite last green through Phase 70 at 394)
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
- **Phase 68:** paywall prices + Free/Pro lists; remove Cloud backup / Direct Upload from main paywall; slower first-run mini tutorial  
- **Phase 69:** regroup Export JPEGs section order (Listing → Photos → Marketplace → size/fit → readiness → export → history → queue)  
- **Phase 70:** collapsible Export JPEGs groups (History/Queue start collapsed)  
- **Phase 71 / launch:** LaunchMark resized to **160pt** 1x/2x/3x (`LaunchMark.png` / `@2x` / `@3x`) so UILaunchScreen shows the full logo  
  - **Note:** iOS caches launch screens — delete app + reinstall to verify splash  
  - **Do not** drop a 1024px PNG into LaunchMark as 1x again (that crops the splash)

## Recommended next
Continue Connect §B in `SHAWN_NEXT_RELEASE_STEPS.md` (IAP products), then screenshots → bump → archive when Shawn approves.

Optional: confirm splash on device after delete/reinstall; any remaining UI polish Shawn requests.

## First prompt

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, SESSION_HANDOFF.md, and SHAWN_NEXT_RELEASE_STEPS.md first.

Baseline tip on main: 4fcbfb5 (handoff). Product tip 7af774c (LaunchMark 160pt). Phases 68–71 done.
~397 tests. Version 1.0 (1). Working tree clean. Local Export Mode only. Not archived.

Next: Shawn manual release gates (Connect IAP §B) unless Shawn asks for more polish.
Do not archive/upload/submit unless approved.
No Direct Upload / OAuth / API / AI. StoreKit IDs unchanged. iPhone 16e only.
Keep LaunchMark as 160pt 1x/2x/3x — do not restore oversized 1024@1x splash assets.

Work in /Volumes/CombatMedic/Yofai on main.
```
