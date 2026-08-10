# Session Handoff

## Status
Phase 39 complete — Marketplace Export Expansion. Build + unit tests succeeded on iPhone 16e (172 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 39: Marketplace target ≠ export canvas; no new named FB Marketplace / Mercari pixel presets (research 2026-08-09)
- Seven export preset raw values/sizes unchanged; Fill + Crop reposition preserved
- Not marketplace compliance claims
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `MarketplaceTarget`, `ExportReadiness`, `MarketplaceExportSettingsBlock`, `ExportPreviewCard`
- Phase39MarketplaceExportExpansionTests (19); total 172

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Only add FB Marketplace / Mercari named presets if first-party exact canvases appear. Otherwise continue local seller polish. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
