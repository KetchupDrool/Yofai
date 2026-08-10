# Session Handoff

## Status
Phase 62 complete — draft-aware listing packages & copy tools.  
**Full suite Passed; build Passed on iPhone 16e.**  
**Marketplace APIs are not next** — finish local prep workflow first (see `DECISIONS.md`).

## Behavior
- Free: Primary Draft = `ItemProject` listing fields + Prepare Listing & Export + primary package/share
- Pro: additional local drafts + draft-specific Copy/Share listing text via `advancedMultiMarketTools`
- Still Local Export Mode only — seller uploads manually outside the app
- No Direct Upload / login / OAuth / publish / API
- Draft JPEG package-folder generation deferred (text copy/share only this phase)

## Why no APIs yet (short)
Local listing prep must be stable first. APIs are marketplace-specific, need external setup and official access, and some markets may not offer third-party upload. Wrong shortcuts (automation/scraping/passwords) are banned.

## Suggested local order (approval required each time)
63 templates/defaults → 64 Pro polish → later one official API

## Version / build (do not auto-bump)
- Marketing: **1.0** · Build: **1** · Bundle: `com.shawnwright.yofai`

## Owner next steps
Release: **`SHAWN_NEXT_RELEASE_STEPS.md`**.  
Product: approve **Phase 63 — Marketplace Templates/Defaults** before coding; do not start API work.

## Rules
- Freemium-first; Free keeps core local export; no AI / Direct Upload  
- Unit tests: iPhone 16e  
