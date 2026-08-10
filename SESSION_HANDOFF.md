# Session Handoff

## Status
Phase 61 complete — local marketplace listing drafts.  
**320 tests Passed; build Passed on iPhone 16e.**  
**Marketplace APIs are not next** — finish local prep workflow first (see `DECISIONS.md`).

## Behavior
- Free: Primary Draft = `ItemProject` listing fields + Prepare Listing & Export
- Pro: additional local drafts via `advancedMultiMarketTools`
- Still Local Export Mode only — seller uploads manually outside the app
- No Direct Upload / login / OAuth / publish / API

## Why no APIs yet (short)
Local listing prep must be stable first. APIs are marketplace-specific, need external setup and official access, and some markets may not offer third-party upload. Wrong shortcuts (automation/scraping/passwords) are banned.

## Suggested local order (approval required each time)
62 packages/copy → 63 templates/defaults → 64 Pro polish → later one official API

## Version / build (do not auto-bump)
- Marketing: **1.0** · Build: **1** · Bundle: `com.shawnwright.yofai`

## Owner next steps
Release: **`SHAWN_NEXT_RELEASE_STEPS.md`**.  
Product: approve Phase 62 before any draft-package coding; do not start API work.

## Rules
- Freemium-first; Free keeps core local export; no AI / Direct Upload  
- Unit tests: iPhone 16e  
