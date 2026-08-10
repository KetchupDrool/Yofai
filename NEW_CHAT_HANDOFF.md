# Yofai — Cursor New Chat Handoff

## Current date
2026-08-10

## Project
App: Yofai · Bundle ID: `com.shawnwright.yofai` · iPhone · SwiftUI + SwiftData  
Simulator: **iPhone 16e only** unless approved  
Repo: `/Volumes/CombatMedic/Yofai` · branch `main`

## Current baseline
Latest commit on `main`:

`4346b1546529a5bd71963d87fd8714fcd38c78ac` — *Phase 65 app store release gate prep*

Status:
- Phase 65 complete (release docs/verification)
- Local multi-market arc Phases 61–64 complete
- `origin/main` up to date · working tree clean (verify with `git status`)
- **354 tests passed** · build succeeded · iPhone 16e
- Version **1.0** · Build **1** — **not bumped** (bump before archive)
- Manual App Store gates still open

## Product direction
Freemium-first, **no-AI**, local-first marketplace photo-prep and listing-prep.

Core workflow: Capture → Organize → Photo Check → Edit → Prepare → Local Export

Current behavior: Local JPEG export only; seller uploads outside the app; local marketplace drafts/templates/copy tools; **no** Direct Upload / publish / login / OAuth / API / backend / AI / ads / analytics SDK.

## Hard rules
Do **not** add: Direct Upload, publishing, login, OAuth, API integration, browser automation, marketplace passwords, scraping, unofficial APIs, backend, AI/OpenAI, ads, analytics SDK, compliance claims, invented marketplace dimensions, new fixed FB/Mercari sizes.

Preserve: user data, Free core local workflow, SellerDefaults, marketplace templates, export preset raw values/dimensions, FB/Mercari `recommendedExportPreset == nil`, one simulator (iPhone 16e).

Do **not** archive/upload/submit or mark Connect/TestFlight gates Passed without Shawn evidence/approval.

## StoreKit / release
Product IDs (unchanged):
- `com.shawnwright.yofai.pro.monthly` (intended $4.99/month)
- `com.shawnwright.yofai.pro.yearly` (intended $39.99/year)

Legal:
- Terms: Apple Standard EULA  
- Privacy: https://ketchupdrool.github.io/Yofai/privacy-policy.html

Owner guide: **`SHAWN_NEXT_RELEASE_STEPS.md`** · Gates: **`APP_STORE_SUBMIT_GATES.md`**

## Completed recent phases
- Phase 61–64: local multi-market drafts / packages / templates / polish  
- Phase 65: App Store release gate prep (docs; build left at 1)

## Why APIs are not being done yet
Local marketplace workflow first. See `DECISIONS.md` — *Why marketplace APIs are not being done yet*.

## Recommended next (Shawn)
1. Create Connect Yofai Pro products (§B in `SHAWN_NEXT_RELEASE_STEPS.md`)  
2. Capture screenshots  
3. Approve build bump → archive/upload  
4. TestFlight purchase verification → metadata → submit when gates Pass  

## Start here
1. `SHAWN_NEXT_RELEASE_STEPS.md`  
2. `APP_STORE_SUBMIT_GATES.md`  
3. `SESSION_HANDOFF.md` / `TASKS.md`

## First prompt

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, SHAWN_NEXT_RELEASE_STEPS.md, and APP_STORE_SUBMIT_GATES.md first.

Baseline: main @ 4346b15 (Phase 65). 354 tests. Version 1.0 (1) not bumped.
Local multi-market complete. App Store Connect / screenshots / TestFlight / archive still manual.
Local Export Mode only. No API / Direct Upload unless explicitly approved.

Work in /Volumes/CombatMedic/Yofai on main. Unit tests on iPhone 16e only.

Do not archive, upload, or submit without explicit approval.
Do not mark manual gates Passed without Shawn evidence.
No invented FB/Mercari fixed presets. No AI.
```
