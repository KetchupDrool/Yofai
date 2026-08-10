# Tasks

## Status
Phase 44 — Seller Export Batch Notes complete.
App Store upload remains paused.

## Product direction
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Marketplaces (Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, similar) are **local export targets only**.

## Current Phase
Phase 44 — Seller Export Batch Notes. Complete.

## Done
- MVP + Phases 4–43
- Phase 44: optional local `sellerNote` on ProjectExportBatch (240 char max); Phase44ExportBatchNotesTests (12); total 240
- Build + unit tests succeeded on iPhone 16e (240 tests)

## Remaining Polish
- Edit tools may scroll with Export + watermark

## Next (when explicitly approved)
- Named FB Marketplace / Mercari presets only if a first-party exact canvas is later verified
- Do not treat live AI, OAuth, or marketplace upload as the default next step

## Abandoned from the active roadmap
Inactive unless explicitly re-approved later:
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing
- Direct publishing to any marketplace

## Future capability (approved direction — not next work)
May be added later where they support the product; core photo prep stays local-first/on-device:
- Backend services, user accounts, cloud sync, subscriptions, ads

## Do Not Do (unless newly / re-approved)
- Paid/live AI networking or API keys in the app
- OAuth marketplace publishing or direct marketplace uploads
- Invent marketplace category trees, IDs, scopes, or compliance limits
- Fake AI-generated listing copy in production
- Fake camera captures in production
- Do not change ShareFileItem / ShareBatchItem sheet architecture
