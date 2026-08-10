# Tasks

## Status
Phase 48 — Final Local Export Mode Polish complete.
App Store upload remains paused.

## Product direction
Local-first marketplace product photo preparation for online sellers.
**Local Export Mode** is current production behavior.
**Direct Upload Mode** is future-only (see `MARKETPLACE_UPLOAD_ROADMAP.md`).

## Current Phase
Phase 48 — Final Local Export Mode Polish. Complete.

## Done
- MVP + Phases 4–47
- Phase 48: post-export View Exported Files next step, history action order, DT/a11y wording pass; Phase48FinalLocalExportPolishTests (6); total 270
- Build + unit tests succeeded on iPhone 16e (270 tests)

## Remaining Polish
- Edit tools may scroll with Export + watermark (minor layout)

## Next (when explicitly approved)
- App Store prep / release checklist for Local Export Mode, **or**
- Verified Etsy Direct Upload foundation only after manual OAuth/API confirmation
- Do not treat unpaid browser automation or guessed APIs as next work

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
- Do not change ShareFileItem / ShareBatchItem sheet architecture beyond optional caption text for local share
