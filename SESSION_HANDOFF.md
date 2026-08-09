# Session Handoff

## Status
Phase 33 complete — Seller Export Preset Clarity. Build + unit tests succeeded on iPhone 16e (100 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 33: display-only preset clarity; raw values + pixel sizes unchanged; Marketplace UI title “Square 1600”
- Fit mode remains contain + pad
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- ListingExport display metadata, grouped pickers, Home/Projects copy, export disclaimer
- Phase33SellerExportPresetClarityTests; Phases 22–32 still pass (100 total)

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Wait for verified marketplace pixel sizes before adding named eBay / FB Marketplace / Poshmark / Mercari presets. Optional later: cover/crop fit mode or seller-nav simplify. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
