# Yofai — Cursor New Chat Handoff

## Current date
2026-08-10

## Project
App: Yofai · Bundle ID: `com.shawnwright.yofai` · iPhone · SwiftUI + SwiftData  
Simulator: **iPhone 16e only** unless approved  
Repo: `/Volumes/CombatMedic/Yofai` · branch `main`

## Current baseline
Latest commit on `main`:

`09c39dc6d213b2ab527ebc672af6b604d9a06605` — *Phase 64 multi-market workflow polish*

Status:
- Phase 64 complete; APIs still later unless approved
- `origin/main` up to date · working tree clean (verify with `git status`)
- **354 tests passed** · build succeeded · iPhone 16e
- Version **1.0 (1)** — do not auto-bump

## Product direction
Freemium-first, **no-AI**, local-first marketplace photo-prep and listing-prep.

Core workflow: Capture → Organize → Photo Check → Edit → Prepare → Local Export

Marketplace direction: prepare **manual listing packages** for:
Etsy · eBay · Facebook Marketplace · Mercari · Poshmark · Other / custom

Current behavior: Local JPEG export only; seller uploads outside the app; local marketplace drafts; Pro draft copy/share; Pro marketplace templates/defaults; Pro multi-market workflow polish; **no** Direct Upload / publish / login / OAuth / API / backend / AI / ads / analytics SDK.

## Hard rules
Do **not** add: Direct Upload, publishing, login, OAuth, API integration, browser automation, marketplace passwords, scraping, unofficial APIs, backend, AI/OpenAI, ads, analytics SDK, compliance claims, invented marketplace dimensions, new fixed FB/Mercari sizes.

Preserve: user data, `ItemProject` listing fields, SellerDefaults key/behavior, marketplace templates, export preset raw values/dimensions, FB/Mercari `recommendedExportPreset == nil`, Free core local workflow, one simulator (iPhone 16e).

## Freemium rules
**Free keeps:** 12 active products; one primary listing workflow (`ItemProject` fields); Seller Defaults for new products; Capture → Organize → Photo Check → Edit/fit → Prepare → Local JPEG export → notes → view/re-share → copy/share manual package → manual upload outside app.

**Pro adds:** unlimited products; multiple marketplace drafts; draft status overview; draft-specific Copy/Share listing text; per-marketplace templates/defaults; apply to blank fields only. Multi-market maps to `advancedMultiMarketTools`.

Do **not** put Free primary workflow behind Pro.

## Completed recent phases

### Phase 61 — Marketplace Listing Drafts
`112859e` — `MarketplaceListingDraft` + support + UI; Pro gated by `advancedMultiMarketTools`.

### Phase 62 — Draft-Aware Listing Packages & Copy Tools
`af7879f` — draft listing-text copy/share; Free primary `ListingPackage` unchanged.

### Phase 63 — Marketplace Templates/Defaults
`db43a4d` — per-marketplace UserDefaults templates; apply blank fields only; Free SellerDefaults preserved.

### Phase 64 — Pro Multi-Market Workflow Polish
`09c39dc` — `MarketplaceDraftCompletionSupport` + overview/editor polish; Free lock clarifies local export stays available; 13 Phase 64 tests; 354 total.

### API-later docs
`4d31f8c` — locked why APIs wait; local order 61→64 complete before any official API.

## Why APIs are not being done yet
Local marketplace workflow first. APIs are marketplace-specific, need external setup/official access; do not assume FB/Mercari/Poshmark upload; no scraping/automation/passwords/unofficial APIs. When approved, walk Shawn step-by-step for **one** marketplace (likely Etsy or eBay first).

See `DECISIONS.md` — *Why marketplace APIs are not being done yet*.

## Recommended next (needs approval)
App Store release gates (`SHAWN_NEXT_RELEASE_STEPS.md`) **or** a later official API phase for one marketplace.

Still local-only until an API phase is explicitly approved.

## Start here
1. `DECISIONS.md` (Phase 61–64 + API-later)  
2. `SESSION_HANDOFF.md` / `TASKS.md`  
3. `SHAWN_NEXT_RELEASE_STEPS.md` (App Store gates still manual)

## First prompt

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, DECISIONS.md (Phase 64 + “Why marketplace APIs are not being done yet”), and SESSION_HANDOFF.md first.

Baseline: main after Phase 64. 354 tests. Local Export Mode only.
Free primary ItemProject workflow + SellerDefaults intact. Pro multi-draft / copy / templates / polish via advancedMultiMarketTools.
APIs / Direct Upload / OAuth / publish are not next unless explicitly approved.

Work in /Volumes/CombatMedic/Yofai on main. Unit tests on iPhone 16e only.

Do not start marketplace API work unless explicitly approved.
No scraping, browser automation, password storage, or unofficial APIs.
No invented FB/Mercari fixed presets. No AI.
```
