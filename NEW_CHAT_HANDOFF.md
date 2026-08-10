# Yofai — Cursor New Chat Handoff

## Current date
2026-08-10

## Project
App: Yofai · Bundle ID: `com.shawnwright.yofai` · iPhone · SwiftUI + SwiftData  
Simulator: **iPhone 16e only** unless approved  
Repo: `/Volumes/CombatMedic/Yofai` · branch `main`

## Current baseline
Latest commit on `main`:

`db43a4dec35a3f3f4d3672bb042807dcc40a8c3a` — *Phase 63 marketplace templates defaults*

Status:
- Phase 63 complete; APIs still later
- `origin/main` up to date · working tree clean (verify with `git status`)
- **341 tests passed** · build succeeded · iPhone 16e
- Version **1.0 (1)** — do not auto-bump

## Product direction
Freemium-first, **no-AI**, local-first marketplace photo-prep and listing-prep.

Core workflow: Capture → Organize → Photo Check → Edit → Prepare → Local Export

Marketplace direction: prepare **manual listing packages** for:
Etsy · eBay · Facebook Marketplace · Mercari · Poshmark · Other / custom

Current behavior: Local JPEG export only; seller uploads outside the app; local marketplace drafts; Pro draft-aware copy/share; Pro marketplace templates/defaults; **no** Direct Upload / publish / login / OAuth / API / backend / AI / ads / analytics SDK.

## Hard rules
Do **not** add: Direct Upload, publishing, login, OAuth, API integration, browser automation, marketplace passwords, scraping, unofficial APIs, backend, AI/OpenAI, ads, analytics SDK, compliance claims, invented marketplace dimensions, new fixed FB/Mercari sizes.

Preserve: user data, `ItemProject` listing fields, SellerDefaults key/behavior, export preset raw values/dimensions, FB/Mercari `recommendedExportPreset == nil`, Free core local workflow, one simulator (iPhone 16e).

## Freemium rules
**Free keeps:** 12 active products; one primary listing workflow (`ItemProject` fields); Seller Defaults for new products; Capture → Organize → Photo Check → Edit/fit → Prepare → Local JPEG export → notes → view/re-share → copy/share manual package → manual upload outside app.

**Pro adds:** unlimited products; multiple marketplace drafts; draft-specific Copy/Share listing text; per-marketplace templates/defaults (save / apply to blank fields / clear); reuse across markets; future advanced packages/checklists/bulk prep. Multi-market maps to `advancedMultiMarketTools`.

Do **not** put Free primary workflow behind Pro.

## Completed recent phases

### Phase 61 — Marketplace Listing Drafts
`112859e` — `MarketplaceListingDraft` + support + UI; Pro gated by `advancedMultiMarketTools`; Free primary intact.

### Phase 62 — Draft-Aware Listing Packages & Copy Tools
`af7879f` — draft listing-text copy/share; Free primary `ListingPackage` unchanged; 10 Phase 62 tests.

### Phase 63 — Marketplace Templates/Defaults
`db43a4d` — `MarketplaceTemplateDefaults` UserDefaults store + draft Save/Apply blank/Clear + Settings status; Free SellerDefaults preserved; 11 Phase 63 tests; 341 total.

### API-later docs
`4d31f8c` — locked why APIs wait; safe order 62→63→64→later one official API.

## Why APIs are not being done yet
Local marketplace workflow first. APIs are marketplace-specific, need external setup/official access; do not assume FB/Mercari/Poshmark upload; no scraping/automation/passwords/unofficial APIs. When approved, walk Shawn step-by-step for **one** marketplace (likely Etsy or eBay first).

See `DECISIONS.md` — *Why marketplace APIs are not being done yet*.

## Recommended next phase (not started — needs approval)
**Phase 64 — Pro Multi-Market Workflow Polish**

Still local-only. No API/upload/OAuth/publish.

## Start here
1. `DECISIONS.md` (Phase 61–63 + API-later)  
2. `SESSION_HANDOFF.md` / `TASKS.md`  
3. `SHAWN_NEXT_RELEASE_STEPS.md` (App Store gates still manual)

## First prompt

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, DECISIONS.md (Phase 63 + “Why marketplace APIs are not being done yet”), and SESSION_HANDOFF.md first.

Baseline: main @ db43a4d (Phase 63). 341 tests. Local Export Mode only.
Free primary ItemProject workflow + SellerDefaults intact. Pro multi-draft / copy / templates via advancedMultiMarketTools.
APIs / Direct Upload / OAuth / publish are not next.

Work in /Volumes/CombatMedic/Yofai on main. Unit tests on iPhone 16e only.

Do not start Phase 64 unless explicitly approved.
Do not start marketplace API work. No scraping, browser automation, password storage, or unofficial APIs.
No invented FB/Mercari fixed presets. No AI.
```
