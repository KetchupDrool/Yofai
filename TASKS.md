# Tasks

## Status
Phase 51 — Remove AI References & Final No-AI Positioning Cleanup complete.
App Store upload remains paused until you run the release checklist and submit.
StoreKit purchases not implemented.
Yofai is a no-AI app.

## Product direction
Local-first marketplace product photo preparation for online sellers.
**Local Export Mode** is current production behavior.
**Freemium-first if monetized.** Pro planned/additive only; no purchase charged yet.
Photo Check / Export Readiness / Prep Tips remain deterministic/local.

## Current Phase
Phase 51 — No-AI cleanup. Complete.

## Done
- MVP + Phases 4–50
- Phase 51: removed AI Listing Assistant UI/providers; neutralized docs/rules/App Store AI language; dormant `AIPreparationRecord` shell retained for store compatibility; Phase51NoAICleanupTests (4); total 275
- Build + unit tests succeeded on iPhone 16e (275 tests)

## Next (when explicitly approved)
- Capture screenshots + App Store Connect submit / TestFlight
- StoreKit / Yofai Pro payments phase
- Verified Etsy Direct Upload foundation after manual OAuth/API confirmation

## Do Not Do (unless newly / re-approved)
- Fake StoreKit purchase success
- Lock core Free local-export workflow behind Pro later
- Direct marketplace upload without verified official API/OAuth + explicit phase approval
- Browser automation, unofficial APIs, marketplace password storage
- Ads / analytics SDKs
- Any AI APIs, AI listing assistant, AI photo analysis, or “future AI” roadmap language
