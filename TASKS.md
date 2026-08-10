# Tasks

## Status
Phase 52 — App Store Submit Path complete (docs + review-safe helpers only).
App Store archive/upload still paused until you run `RELEASE_CHECKLIST.md` and submit manually.
StoreKit purchases not implemented.
Yofai is a no-AI app. Local Export Mode only.

## Product direction
Local-first marketplace product photo preparation for online sellers.
**Local Export Mode** is current production behavior.
**Freemium-first if monetized.** Pro planned/additive only; no purchase charged yet.
Photo Check / Export Readiness / Prep Tips remain deterministic/local.

## Current Phase
Phase 52 — App Store submit path. Complete.

## Done
- MVP + Phases 4–51
- Phase 52: metadata package, App Review notes, privacy answers, screenshot plan, TestFlight smoke script, release checklist; Phase52AppStoreSubmitPathTests (4); total 279
- Build + unit tests succeeded on iPhone 16e (279 tests)
- No new product features; no StoreKit; no Direct Upload; no AI

## Next (when explicitly approved)
- Capture screenshots + bump version/build if needed + Xcode archive → App Store Connect → TestFlight → submit
- StoreKit / Yofai Pro payments phase
- Verified Etsy Direct Upload foundation after manual OAuth/API confirmation

## Do Not Do (unless newly / re-approved)
- Fake StoreKit purchase success
- Lock core Free local-export workflow behind Pro later
- Direct marketplace upload without verified official API/OAuth + explicit phase approval
- Browser automation, unofficial APIs, marketplace password storage
- Ads / analytics SDKs
- Any AI APIs, AI listing assistant, AI photo analysis, or “future AI” roadmap language
- Renumber Phases 50–51
