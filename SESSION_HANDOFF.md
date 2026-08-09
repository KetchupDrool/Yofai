# Session Handoff

## Status
Phase 36 complete — Verified Marketplace Local Export Presets. Build + unit tests succeeded on iPhone 16e (123 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 36: eBay 1600×1600 and Poshmark 1000×1000 recommended local canvases
- Legacy five preset raw values/sizes unchanged; no FB Marketplace or Mercari named pixel presets
- Not marketplace compliance claims
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `ListingExportPreset.ebay` / `.poshmark`; Phase36VerifiedMarketplaceExportPresetsTests
- Phase 33 tests adjusted for CaseIterable count 7; Phases 22–35 still pass (123 total)

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Facebook Marketplace / Mercari named presets only with verified canvases. Optional later: cover/crop fit mode. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
