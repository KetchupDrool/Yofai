# Tasks

## Status
Phase 49 — Freemium Foundation & Entitlement Planning complete.
App Store upload remains paused. StoreKit purchases not implemented.

## Product direction
Local-first marketplace product photo preparation for online sellers.
**Local Export Mode** is current production behavior.
**Direct Upload Mode** is future-only (see `MARKETPLACE_UPLOAD_ROADMAP.md`).
**Freemium-first if monetized:** Free keeps core local export; Pro is additive.

## Current Phase
Phase 49 — Freemium Foundation & Entitlement Planning. Complete.

## Done
- MVP + Phases 4–48
- Phase 48: final Local Export Mode polish (post-export next step, DT/a11y)
- Phase 49: entitlement layer, Free product limit (12), Pro placeholder Settings UI; Phase49FreemiumFoundationTests (8); total 278
- Build + unit tests succeeded on iPhone 16e (278 tests)

## Remaining Polish
- Edit tools may scroll with Export + watermark (minor layout)

## Next (when explicitly approved)
- App Store prep for Local Export Mode Free launch, **or**
- StoreKit / Yofai Pro payments phase (product IDs, StoreKit 2, restore, legal), **or**
- Verified Etsy Direct Upload foundation after manual OAuth/API confirmation

## Abandoned from the active near-term roadmap
Inactive unless explicitly re-approved later:
- Paid/live AI APIs
- Browser automation / unofficial marketplace APIs / marketplace password storage

## Future capability (approved direction — not next work)
May be added later where they support the product; core photo prep stays local-first/on-device:
- Backend services, user accounts, cloud sync, subscriptions/ads, verified Direct Upload Mode

## Do Not Do (unless newly / re-approved)
- Lock core Free local-export workflow behind Pro later (bait-and-switch)
- Fake StoreKit purchase success without real StoreKit
- Paid/live AI networking or API keys in the app
- Direct marketplace upload without verified official API/OAuth + explicit phase approval
- Browser automation, unofficial APIs, marketplace password storage
- Invent marketplace category trees, IDs, scopes, or compliance limits
- Delete seller data to enforce Free limits
