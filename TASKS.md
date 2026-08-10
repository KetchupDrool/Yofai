# Tasks

## Status
Phase 45 — Direct Marketplace Upload Feasibility & Roadmap Reset complete.
App Store upload remains paused.

## Product direction
Local-first marketplace product photo preparation for online sellers.
**Local Export Mode** is current production behavior.
**Direct Upload Mode** is future-only (see `MARKETPLACE_UPLOAD_ROADMAP.md`).

## Current Phase
Phase 45 — Direct Marketplace Upload Feasibility & Roadmap Reset. Complete.

## Done
- MVP + Phases 4–44
- Phase 45: roadmap reset, feasibility matrix, Local vs Direct Upload modes documented; Phase45MarketplaceUploadRoadmapTests (6); total 246
- Build + unit tests succeeded on iPhone 16e (246 tests)

## Remaining Polish
- Edit tools may scroll with Export + watermark

## Next (when explicitly approved)
- Prefer Local Export Mode polish, or a verified Etsy Direct Upload foundation phase only after manual OAuth/API confirmation
- Do not treat unpaid browser automation or guessed APIs as next work
- Named FB Marketplace / Mercari presets only if a first-party exact canvas is later verified

## Abandoned from the active near-term roadmap
Inactive unless explicitly re-approved later:
- Paid/live AI APIs
- Browser automation / unofficial marketplace APIs / marketplace password storage

## Future capability (approved direction — not next work)
May be added later where they support the product; core photo prep stays local-first/on-device:
- Backend services, user accounts, cloud sync, subscriptions, ads
- Direct Upload Mode for verified marketplaces only

## Do Not Do (unless newly / re-approved)
- Paid/live AI networking or API keys in the app
- Direct marketplace upload without verified official API/OAuth + explicit phase approval
- Browser automation, unofficial APIs, marketplace password storage
- Invent marketplace category trees, IDs, scopes, or compliance limits
- Fake AI-generated listing copy in production
- Fake camera captures in production
- Do not change ShareFileItem / ShareBatchItem sheet architecture
