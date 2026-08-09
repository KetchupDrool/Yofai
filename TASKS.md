# Tasks

## Status
Product pivot documented (2026-08-09). No new feature coding until an explicit next phase is approved.
App Store upload remains paused.

## Product direction
Local-first marketplace product photo preparation for online sellers.
Core functionality is local-first/on-device.
Marketplaces (Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, similar) are **local export targets only**.

## Current Phase
Phase 32 — Product Intake + Guided Photo Capture. Complete (last technical phase before pivot docs).

## Done
- MVP + Phases 4–31
- Phase 32: Product Intake, photo plan, system camera capture, Photo Check, seller review checkboxes, tests
- Build + unit tests succeeded on iPhone 16e (92 tests)
- Direction docs updated for product pivot (no feature coding)

## Remaining Polish
- Edit tools may scroll with Export + watermark

## Next (docs-aligned planning only — not coding yet)
- When approved: multi-marketplace **local** export presets (eBay, Facebook Marketplace, Poshmark, Mercari, similar)
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
