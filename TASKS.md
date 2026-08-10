# Tasks

## Status
Phase 53 — StoreKit / Yofai Pro Payments complete (in-app foundation).
App Store Connect subscription products still must be created manually before live charges.
App Store archive/upload still paused until you finish Connect IAP + `RELEASE_CHECKLIST.md`.
Yofai is freemium-first, no-AI, Local Export Mode only. Direct Upload not implemented.

## Product direction
Local-first marketplace product photo preparation for online sellers.
**Free** keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export.
**Yofai Pro** (StoreKit 2 monthly/yearly) is additive — unlimited products + planned extras.

## Current Phase
Phase 53 — StoreKit Pro payments. Complete (in-app).

## Done
- Phases 1–52
- Phase 53: StoreKit 2 purchase manager, paywall, entitlement wiring, `Yofai.storekit`, Connect subscriptions doc; Phase53StoreKitProPaymentsTests (16); total 295
- Build + unit tests on iPhone 16e

## Next (when explicitly approved)
- Create Yofai Pro subscription products in App Store Connect (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)
- Sandbox / TestFlight purchase smoke
- Screenshots/archive/submit per `RELEASE_CHECKLIST.md`
- Or verified Direct Upload foundation

## Do Not Do (unless newly / re-approved)
- Fake StoreKit purchase success
- Lock core Free local-export workflow behind Pro
- Direct marketplace upload without verified official API/OAuth + explicit phase approval
- Browser automation, unofficial APIs, marketplace password storage
- Ads / analytics SDKs / AI
- Lifetime SKU unless separately approved
