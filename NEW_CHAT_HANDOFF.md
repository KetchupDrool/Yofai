# Yofai — Cursor New Chat Handoff

## Current date
2026-08-10

## Project
App: Yofai · Bundle ID: `com.shawnwright.yofai` · iPhone · SwiftUI + SwiftData  
Simulator: **iPhone 16e only** unless approved  
Repo: `/Volumes/CombatMedic/Yofai` · branch `main`

## Current baseline
Latest commit on `main`:

*(set after Phase 62 push — see `git log -1`)*

Phase 62 implementation commit message:

*Phase 62 draft-aware listing packages*

Status:
- Phase 62 complete; APIs still later
- **330 tests passed** · build succeeded · iPhone 16e
- Version **1.0 (1)** — do not auto-bump

## Product direction
Freemium-first, **no-AI**, local-first marketplace photo-prep and listing-prep.

Core workflow: Capture → Organize → Photo Check → Edit → Prepare → Local Export

Marketplace direction: prepare **manual listing packages** for:
Etsy · eBay · Facebook Marketplace · Mercari · Poshmark · Other / custom

Current behavior: Local JPEG export only; seller uploads outside the app; local marketplace drafts; Pro draft-aware copy/share listing text; **no** Direct Upload / publish / login / OAuth / API / backend / AI / ads / analytics SDK.

## Hard rules
Do **not** add: Direct Upload, publishing, login, OAuth, API integration, browser automation, marketplace passwords, scraping, unofficial APIs, backend, AI/OpenAI, ads, analytics SDK, compliance claims, invented marketplace dimensions, new fixed FB/Mercari sizes.

Preserve: user data, `ItemProject` listing fields, export preset raw values/dimensions, FB/Mercari `recommendedExportPreset == nil`, Free core local workflow, one simulator (iPhone 16e).

## Freemium rules
**Free keeps:** 12 active products; one primary listing workflow (`ItemProject` fields); Capture → Organize → Photo Check → Edit/fit → Prepare → Local JPEG export → notes → view/re-share → copy/share manual package → manual upload outside app.

**Pro adds:** unlimited products; multiple marketplace drafts; draft-specific Copy listing text / field copy / Share listing text; reuse across markets; future templates/defaults/advanced packages/checklists/bulk prep. Multi-market maps to `advancedMultiMarketTools`.

Do **not** put Free primary workflow behind Pro.

## Completed recent phases

### Phase 59 — Onboarding
`b7a85ced8a7fb92f789f1fe0c59d4f99b74ee824` (+ rich scenes). Simple `UILaunchScreen`; branded guide; Skip; UserDefaults `yofai.firstLaunchGuide.completed.v1`; Settings → Help → Replay; Reduce Motion / Dynamic Type / VoiceOver.

### Phase 60 — Planning (docs-only)
`c676b9d269e841b5245a00357ef6b6c85d7cbbf2` — Free primary vs Pro multi-draft; local/manual only; additive future model.

### Phase 61 — Marketplace Listing Drafts
`112859e` — `MarketplaceListingDraft` + support + UI section; Pro gated by `advancedMultiMarketTools`; Free primary intact; 10 Phase 61 tests.

### Phase 62 — Draft-Aware Listing Packages & Copy Tools
`MarketplaceDraftPackageSupport` + draft editor Copy/Share listing text; Free primary `ListingPackage` unchanged; no draft JPEG package folders this phase; 10 Phase 62 tests; 330 total.

### API-later docs
`4d31f8c` — locked why APIs wait; safe order 62→63→64→later one official API.

## Why APIs are not being done yet
Local marketplace workflow first. APIs are marketplace-specific, need external setup/official access; do not assume FB/Mercari/Poshmark upload; no scraping/automation/passwords/unofficial APIs. When approved, walk Shawn step-by-step for **one** marketplace (likely Etsy or eBay first).

See `DECISIONS.md` — *Why marketplace APIs are not being done yet*.

## Recommended next phase (not started — needs approval)
**Phase 63 — Marketplace Templates/Defaults**

Still local-only. No API/upload/OAuth/publish.

## Start here
1. `DECISIONS.md` (Phase 61–62 + API-later)  
2. `SESSION_HANDOFF.md` / `TASKS.md`  
3. `SHAWN_NEXT_RELEASE_STEPS.md` (App Store gates still manual)

## First prompt

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, DECISIONS.md (Phase 62 + “Why marketplace APIs are not being done yet”), and SESSION_HANDOFF.md first.

Baseline: main after Phase 62. 330 tests. Local Export Mode only.
Free primary ItemProject workflow intact. Pro multi-draft + draft copy/share via advancedMultiMarketTools.
APIs / Direct Upload / OAuth / publish are not next.

Work in /Volumes/CombatMedic/Yofai on main. Unit tests on iPhone 16e only.

Do not start Phase 63 unless explicitly approved.
Do not start marketplace API work. No scraping, browser automation, password storage, or unofficial APIs.
No invented FB/Mercari fixed presets. No AI.
```
