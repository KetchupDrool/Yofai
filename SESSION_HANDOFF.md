# Session Handoff

## Status
Phase 40 complete — Local Export Batch History & Marketplace Labeling. Build + unit tests succeeded on iPhone 16e (185 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 40: `ProjectExportBatch` stores marketplace/size/fit history; “exported for” only — never publish status
- Seven export preset raw values/sizes unchanged; Phases 37–39 preserved
- Not marketplace compliance claims
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Export history metadata on `ProjectExportBatch`; `ExportHistorySection`; Phase40ExportBatchHistoryTests (13); total 185

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
