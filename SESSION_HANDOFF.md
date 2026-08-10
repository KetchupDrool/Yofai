# Session Handoff

## Status
Phase 38 complete — Fill + Crop Reposition. Build + unit tests succeeded on iPhone 16e (153 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 38: Fill + Crop supports per-photo drag reposition; default centered; Contain + Pad unchanged
- Seven export preset raw values/sizes unchanged
- Not marketplace compliance claims
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `fillCropOffsetX` / `fillCropOffsetY` on PhotoEditState; `ListingExportFillCropPosition`; `FillCropRepositionView`
- Phase38FillCropRepositionTests; Phases 1–37 still pass (153 total)

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Facebook Marketplace / Mercari named presets only with verified canvases. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
