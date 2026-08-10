# App Store Submit Gates — Yofai

**Phase 57** — release-gate tracker.  
**Agents must not mark Passed unless evidence exists.**

Status values:
- **Not started**
- **Needs user action**
- **Ready for manual check**
- **Passed**
- **Blocked**

Overall submit readiness: **Needs user action** (Connect IAP + screenshots + TestFlight purchase + archive still open).

## Gate table

| Area | Item | Status |
|---|---|---|
| **Local verification** | Full unit suite on iPhone 16e | **Passed** (Phase 57: 301 tests, 2026-08-10) |
| Local | Debug build on iPhone 16e | **Passed** (Phase 57) |
| Local | Submission-path docs present & consistent | **Passed** (Phases 52–56 package verified Phase 57) |
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
| **D. Screenshots** | Captured per `APP_STORE_PREP.md` | **Needs user action** (manual; not captured in Phase 57) |
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
| Product IDs unchanged | Passed (`monthly` / `yearly` IDs verified Phase 57) |
| Version/build not auto-bumped | Passed (still 1.0 (1); bump before archive — manual) |

## Required order before App Review
1. Local StoreKit smoke (`STOREKIT_SANDBOX_TESTING.md`) — recommended  
2. Connect products configured (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)  
3. Archive + upload (`APP_STORE_ARCHIVE_RUNBOOK.md`) — **bump build number first**  
4. TestFlight sandbox purchase (`TESTFLIGHT_PURCHASE_VERIFICATION.md`)  
5. Full app smoke (`TESTFLIGHT_SMOKE.md`)  
6. Screenshots + metadata  
7. Fill gates above to **Passed** with real evidence  
8. Submit for App Review  

Do **not** skip to F until A–E are Passed.

## What Shawn must do next
1. Create Connect subscription group **Yofai Pro** + monthly/yearly products (exact IDs; $4.99 / $39.99 intended)  
2. Attach `Yofai.storekit` and run local StoreKit smoke (optional but recommended)  
3. Capture 8 App Store screenshots per `APP_STORE_PREP.md`  
4. Approve/bump build (currently **1.0 (1)**), archive, upload (`APP_STORE_ARCHIVE_RUNBOOK.md`)  
5. TestFlight purchase → fill `TESTFLIGHT_PURCHASE_VERIFICATION.md` with Pass  
6. Paste metadata + App Review notes; verify Support/Privacy URLs  
7. Mark gates Passed only with evidence → Submit for App Review  

Cursor cannot complete steps 1–7 without your App Store Connect / device / screenshot work.
