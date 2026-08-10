# Session Handoff

## Status
Phase 53 complete — StoreKit 2 / Yofai Pro payments foundation.  
**295 tests passed; build on iPhone 16e.** Freemium-first; Free keeps core local export.  
App Store Connect subscription products are **not** claimed created — see `APP_STORE_CONNECT_SUBSCRIPTIONS.md`.  
No Direct Upload. No AI. No backend. Do not submit until Connect IAP + checklist are done.

## Product purpose
Marketplace product photo prep → local JPEG export for manual upload.  
Pro via StoreKit monthly/yearly (additive). Free limit 12 products (over-limit stay usable).

## StoreKit facts
- IDs: `com.shawnwright.yofai.pro.monthly`, `com.shawnwright.yofai.pro.yearly`
- Intended prices (docs): $4.99/mo, $39.99/yr — UI uses StoreKit display prices
- Files: `StoreKitSupport.swift`, paywall in `YofaiProPlaceholderView.swift`, `Yofai.storekit`
- Unavailable products → “Purchases are not available right now.” Free still works

## Last Completed
- Phase 53 StoreKit Pro + Phase53StoreKitProPaymentsTests (16)

## Next Recommended
1. Create Connect subscription group/products (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)
2. Attach `Yofai.storekit` in scheme for local testing
3. Sandbox purchase + restore smoke
4. Then `RELEASE_CHECKLIST.md` screenshots/archive/submit

## Rules
- Freemium-first; never fake purchases; never delete data for Free limits
- No AI; Local Export Mode only; one simulator for unit tests: iPhone 16e
