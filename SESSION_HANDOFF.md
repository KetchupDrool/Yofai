# Session Handoff

## Status
Product pivot documented (2026-08-09). Phase 32 remains the last completed technical phase. No new feature coding until an explicit next phase is approved. Last build + unit tests succeeded on iPhone 16e (92 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Product Intake reuses Item Project photos; photo-plan goals are local guidance only
- System camera via UIImagePickerController; simulator unavailable is safe
- Seller review checkboxes do not affect Phase 25 readiness
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Photo plan, capture flow, Photo Check, intake UI entry points
- Phase32ProductIntakeTests; Phases 22–31 still pass
- Direction docs updated for product pivot (PROJECT, DECISIONS, TASKS, handoffs, project rules)

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Wait for an explicit approved local photo-prep phase (e.g. multi-marketplace local export presets). Do not default to live AI, OAuth, or marketplace upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not fake AI copy or camera captures in production
- Do not invent marketplace category trees, IDs, scopes, or compliance limits
- Keep share architecture stable
