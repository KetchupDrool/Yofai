# Session Handoff

## Status
Phase 44 complete — Seller Export Batch Notes. Build + unit tests succeeded on iPhone 16e (240 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 44: optional `sellerNote` on `ProjectExportBatch` (max 240 chars); local reminder only — not publish status
- Notes never required for export; edits isolated from export settings/files/offsets
- Seven export preset raw values/sizes unchanged; Phases 37–43 preserved
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `ExportBatchNoteSupport.swift`, `ExportBatchNoteEditor.swift`; Phase44ExportBatchNotesTests (12); total 240

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
