# App Store Submit Gates — Yofai

**Phase 65** — release-gate prep after Phases 61–64 (local multi-market complete).  
**Agents must not mark Passed unless evidence exists.**

Owner sequence: **`SHAWN_NEXT_RELEASE_STEPS.md`**.

Status values:
- **Not started**
- **Needs user action**
- **Ready for manual check**
- **Passed**
- **Blocked**

Overall submit readiness: **Needs user action** (Connect IAP + screenshots + TestFlight purchase + archive still open).  
Local product code path through Phase 64 is complete; App Store Connect / device / screenshot work remains yours.

## Gate table

| Area | Item | Status |
|---|---|---|
| **Local verification** | Full unit suite on iPhone 16e | **Passed** (Phase 65: 354 tests, 2026-08-10) |
| Local | Debug build on iPhone 16e | **Passed** (Phase 65) |
| Local | Submission-path docs present & consistent | **Passed** (Phases 52–65 package) |
| Local | Owner Connect + screenshot execution guide | **Passed** (`SHAWN_NEXT_RELEASE_STEPS.md`; refreshed Phase 65) |
| Local | Multi-market local arc (Phases 61–64) | **Passed** (local-only drafts/templates/polish) |
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
| Product IDs unchanged | Passed (`com.shawnwright.yofai.pro.monthly` / `.yearly`; verified Phase 65) |
| Version/build not auto-bumped | Passed (still **1.0 (1)**; bump before archive — manual) |
| Local-only / manual upload positioning | Passed (Phases 45–64) |

## Required order before App Review
1. Local StoreKit smoke (`STOREKIT_SANDBOX_TESTING.md`) — recommended  
2. Connect products configured (`APP_STORE_CONNECT_SUBSCRIPTIONS.md` / guide §B)  
3. Screenshots (`APP_STORE_PREP.md` / guide §C)  
4. Archive + upload (`APP_STORE_ARCHIVE_RUNBOOK.md`) — **bump build number first** (§D–E)  
5. TestFlight sandbox purchase (`TESTFLIGHT_PURCHASE_VERIFICATION.md`) (§F)  
6. Full app smoke (`TESTFLIGHT_SMOKE.md`)  
7. Metadata + privacy + App Review notes  
8. Fill gates above to **Passed** with real evidence  
9. Submit for App Review  

Do **not** skip to F submit until A–E are Passed.

## What Shawn must do next
1. Follow **`SHAWN_NEXT_RELEASE_STEPS.md`** §A–B — create Connect **Yofai Pro** + exact product IDs ($4.99 / $39.99 intended)  
2. Capture 8 screenshots per §C / `APP_STORE_PREP.md`  
3. Optional: local StoreKit smoke with `Yofai.storekit`  
4. Approve/bump build (currently **1.0 (1)**), archive, upload  
5. TestFlight purchase → fill `TESTFLIGHT_PURCHASE_VERIFICATION.md` with Pass  
6. Paste metadata + App Review notes; verify Support/Privacy URLs  
7. Mark gates Passed only with evidence → Submit for App Review  

Cursor prepared the guides; Connect / device / screenshot / archive work is yours.  
Do **not** treat marketplace APIs / Direct Upload as next work unless explicitly approved.
