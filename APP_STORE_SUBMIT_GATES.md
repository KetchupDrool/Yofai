# App Store Submit Gates — Yofai

**Phase 56** — single release-gate tracker.  
**Agents must not mark Passed unless evidence exists.** Defaults below reflect repo state after Phase 55–56 docs only.

Status values:
- **Not started**
- **Needs user action**
- **Ready for manual check**
- **Passed**
- **Blocked**

Overall submit readiness: **Needs user action** (Connect IAP + TestFlight purchase + screenshots + archive still open).

## Gate table

| Area | Item | Status |
|---|---|---|
| **A. Connect subscriptions** | Yofai Pro group created | **Needs user action** |
| A | Monthly product `com.shawnwright.yofai.pro.monthly` created | **Needs user action** |
| A | Yearly product `com.shawnwright.yofai.pro.yearly` created | **Needs user action** |
| A | Localizations added | **Needs user action** |
| A | Review info (+ paywall screenshot if required) | **Needs user action** |
| A | Products ready / cleared for review with app version | **Needs user action** |
| **B. Local StoreKit smoke** | Monthly loads (`Yofai.storekit`) | **Ready for manual check** |
| B | Yearly loads | **Ready for manual check** |
| B | Monthly purchase unlocks Pro | **Ready for manual check** |
| B | Restore works | **Ready for manual check** |
| B | Free fallback works | **Ready for manual check** |
| **C. TestFlight sandbox** | Build uploaded | **Needs user action** |
| C | Products load from Connect | **Needs user action** |
| C | Monthly purchase → Pro | **Needs user action** |
| C | Restore works | **Needs user action** |
| C | Reinstall + restore | **Needs user action** |
| C | Free fallback / no data deletion | **Needs user action** |
| **D. Screenshots** | Captured per `APP_STORE_PREP.md` | **Needs user action** |
| D | Reviewed (no AI / Direct Upload / fake Pro) | **Needs user action** |
| D | Uploaded to App Store Connect | **Needs user action** |
| **E. Metadata / privacy** | Metadata pasted from `APP_STORE_METADATA.md` | **Needs user action** |
| E | Privacy answers (`APP_STORE_CONNECT_PRIVACY.md`) | **Needs user action** |
| E | App Review notes pasted | **Needs user action** |
| E | Support + Privacy URLs verified live | **Needs user action** |
| **F. Final submit** | Archive created | **Not started** |
| F | Build uploaded to Connect | **Not started** |
| F | App Review submitted | **Not started** |

## In-app gates already ready (code)
| Item | Status |
|---|---|
| StoreKit 2 Pro foundation | Passed (Phase 53) |
| Paywall Terms of Use + Privacy Statement | Passed (Phase 54) |
| Free core local export without purchase | Passed (regression suite) |
| No Direct Upload / no AI product UI | Passed (Phase 51+) |
| Unit tests on iPhone 16e | Re-run each closeout |

## Required order before App Review
1. Local StoreKit smoke (`STOREKIT_SANDBOX_TESTING.md`) — optional but recommended  
2. Connect products configured (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)  
3. Archive + upload (`APP_STORE_ARCHIVE_RUNBOOK.md`)  
4. TestFlight sandbox purchase (`TESTFLIGHT_PURCHASE_VERIFICATION.md`)  
5. Full app smoke (`TESTFLIGHT_SMOKE.md`)  
6. Screenshots + metadata  
7. Fill gates above to **Passed** with real evidence  
8. Submit for App Review  

Do **not** skip to F until A–E are Passed.
