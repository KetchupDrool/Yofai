# Yofai — Cursor New Chat Handoff

## Current date
2026-08-11

## Project
App: Yofai · Bundle ID: `com.shawnwright.yofai` · iPhone · SwiftUI + SwiftData  
Simulator: **iPhone 16e only** unless approved  
Repo: `/Volumes/CombatMedic/Yofai` · branch `main`

## Current baseline
Latest commit on `main`:

`134a962445e451a32140236830301fdf5bc02b38`

Message: `Update App Icon and Launch Mark artwork.`

Prior Phase 67 (post-readability UI QA):

`4522461c6636ffada52115f693b9520814997a80`

Status:
- Working tree clean; `main` = `origin/main`
- Phase 66 readability cleanup + Phase 67 post-readability UI QA polish complete
- App Icon / Launch Mark artwork updated (`134a962`)
- **370 tests** last verified after Phase 67 QA polish; re-run if starting new code work
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

## Recommended next (approved direction — not started)
**Pre-archive Paywall & Walkthrough Clarity** (call it **Phase 68** to avoid colliding with Phase 67 QA):

1. Clarify Yofai Pro paywall:
   - Show **Monthly — $4.99**, **Yearly — $39.99**, **Best value**
   - Short Free vs Pro copy
   - Remove/hide coming-soon items from main paywall (especially Cloud backup, Direct Upload Mode)
   - Keep “Keep using Free”; no fake purchase success; product IDs unchanged
2. Upgrade first-run walkthrough into premium animated mini tutorial (Reduce Motion respected; slow enough to read)
   - Explain Photo Check, Crop, Contain + Pad, Fill + Crop, Reposition, Export size, Marketplace target, Local JPEG export, Export history
3. Simplify seller-facing labels where safe: Product, Photos, Listing Info, Photo Check, Export JPEGs, Marketplace Drafts, Copy Listing Text
4. Do **not** archive/upload/submit

Or continue Connect §B in `SHAWN_NEXT_RELEASE_STEPS.md` if Shawn prefers release gates first.

## First prompt

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, SESSION_HANDOFF.md, and SHAWN_NEXT_RELEASE_STEPS.md first.

Baseline tip on main: 134a962 (App Icon / Launch Mark update).
Prior Phase 67 QA polish: 4522461. 370 tests last verified. Version 1.0 (1).
Working tree was clean. Local Export Mode only. Not archived.

Next approved work: Phase 68 — Pre-Archive Paywall & Walkthrough Clarity.
- Show paywall prices Monthly $4.99 / Yearly $39.99 / Best value
- Remove Cloud backup + Direct Upload Mode from main paywall benefits
- Upgrade first-run walkthrough with slower premium animations + clear photo option explanations
- Simplify seller wording where safe
- Do not archive/upload/submit
- No Direct Upload / OAuth / API / AI
- StoreKit IDs unchanged
- iPhone 16e only

Work in /Volumes/CombatMedic/Yofai on main.
```
