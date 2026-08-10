# Session Handoff

## Status
Phase 43 complete — Seller One-Tap Prep Tips. Build + unit tests succeeded on iPhone 16e (228 tests). App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Export targets only: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Phase 43: computed prep tips (max 3) guide sellers to existing controls; manual only; not persisted
- No auto-fit/crop/size/export; no guidance-only false warnings; watermark off creates no tip
- Seven export preset raw values/sizes unchanged; Phases 37–42 preserved
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- `ExportPrepTipSupport.swift`, `ExportPrepTipsSection.swift`; Phase43ExportPrepTipsTests (15); total 228

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
