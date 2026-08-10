# Session Handoff

## Status
Phase 41 complete — Export History Filters & Compare Polish. Build + unit tests succeeded on iPhone 16e (198 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 41: transient marketplace filters + metadata-only compare of newest two exports; Export Again applies settings only (no auto-export)
- Filter uses stored `marketplaceTargetRaw` only; legacy empty → Earlier export; never infer from canvas/folder/JPEG
- Seven export preset raw values/sizes unchanged; Phases 37–40 preserved
- Not marketplace compliance claims; not pixel comparison
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `ExportHistorySupport.swift`; filters/compare in `ExportHistorySection`; Phase41ExportHistoryFiltersCompareTests (13); total 198

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
