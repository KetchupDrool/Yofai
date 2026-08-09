# Session Handoff

## Status
Phase 35 complete — Seller-First Navigation Simplification. Build + unit tests succeeded on iPhone 16e (113 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 35: Home Start/Continue Product; Products tab; Import/Originals/History secondary
- Project Detail: Capture & Check Photos → Prepare Listing & Export
- No SwiftData migration; existing projects/originals/history preserved
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `SellerNavigationSupport`, ContentView tab selection, Home/Projects/ProjectDetail label updates
- Phase35SellerFirstNavigationTests; Phases 22–34 still pass (113 total)

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Wait for verified marketplace pixel sizes before named eBay / FB Marketplace / Poshmark / Mercari presets. Optional later: cover/crop fit mode. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
