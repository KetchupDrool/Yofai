# Session Handoff

## Status
Phase 34 complete — Local Export Canvas Check. Build + unit tests succeeded on iPhone 16e (108 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 34: Photo Check compares source file pixels to project listing export preset; Intake/Workspace show local canvas notes
- Does not change Phase 25 readiness; no marketplace compliance claims
- Fit mode remains contain + pad
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Export canvas facts on `PhotoTechnicalFacts` / `PhotoTechnicalCheck`
- Photo Check section, Product Intake notes, Listing Workspace summary
- Phase34ExportCanvasCheckTests; Phases 22–33 still pass (108 total)

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Wait for verified marketplace pixel sizes before named eBay / FB Marketplace / Poshmark / Mercari presets. Optional later: cover/crop fit mode or seller-nav simplify. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
