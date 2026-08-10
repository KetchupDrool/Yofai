# Session Handoff

## Status
Phase 42 complete — Seller Export Readiness Checklist. Build + unit tests succeeded on iPhone 16e (213 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 42: computed Export Readiness checklist (Photos, Marketplace, Export size, Fit, Photo Check, Watermark); not persisted
- Watermark optional; guidance-only markets can still be Ready with a valid canvas; no compliance claims
- Seven export preset raw values/sizes unchanged; Phases 37–41 preserved
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Expanded `ExportReadiness` + `ExportReadinessChecklistSection`; Phase42ExportReadinessChecklistTests (15); total 213

## Abandoned from the active roadmap
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing / direct publishing to any marketplace

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads may be added later where they support the product; core photo prep stays local-first/on-device.

## Next Recommended
Continue local seller polish only when explicitly approved. Do not default to live AI, OAuth, or upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not fake AI copy or camera captures in production
- Keep share architecture stable
