# Session Handoff

## Status
Phase 60 complete — **docs-only** marketplace workspace planning & freemium mapping.  
No Swift / SwiftData / UI / StoreKit / entitlement changes.  
Phase 59 remains closed on `main` (@ `b7a85ce` closeout lineage).

## Locked Phase 60 decisions
- Freemium-first; Local Export Mode only
- Free: 12 products; one primary listing workflow per product (`ItemProject` fields)
- Pro later: multi-market drafts via `advancedMultiMarketTools` (+ unlimited products)
- Future model: additive `MarketplaceListingDraft` owned by `ItemProject` — do not replace project listing fields
- FB/Mercari: no invented fixed presets
- Manual listing packages only — no Direct Upload / login / OAuth / publish

## Version / build (do not auto-bump)
- Marketing: **1.0**
- Build: **1**
- Bundle ID: `com.shawnwright.yofai`

## Owner next steps
Release: **`SHAWN_NEXT_RELEASE_STEPS.md`**.  
Implementation: wait for approval of **Phase 61 — Marketplace Listing Drafts**.

## Last Completed
- Phase 60 docs decision lock

## Rules
- No fake Passed manual gates  
- Freemium-first; Free keeps core local export; no AI / Direct Upload  
- Unit tests: iPhone 16e  
