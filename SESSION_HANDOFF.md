# Session Handoff

## Status
Phase 37 complete — Cover/Crop Export Fit Mode. Build + unit tests succeeded on iPhone 16e (138 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 37 supersedes Phase 20 contain+pad-only: sellers choose **Contain + Pad** (default) or **Fill + Crop** (center only)
- Seven export preset raw values/sizes unchanged; no FB Marketplace or Mercari named pixel presets
- Not marketplace compliance claims
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `ListingExportFitMode`; ImageEditing fill+crop; Project/Defaults/Edit/Bulk fit pickers; Photo Check pad vs crop facts
- Phase37ExportFitModeTests; Phases 1–36 still pass (138 total)

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Facebook Marketplace / Mercari named presets only with verified canvases. Optional later: fill+crop reposition. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
