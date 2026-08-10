# TestFlight Purchase Verification Report — Yofai

**Fill when you actually run purchases.** Agents leave all cases **Not run**.

Status values: **Not run** | **Pass** | **Fail** | **Blocked**

Master gates: `APP_STORE_SUBMIT_GATES.md`  
Archive/upload: `APP_STORE_ARCHIVE_RUNBOOK.md`

## Order (do not skip)
1. Local StoreKit smoke (`STOREKIT_SANDBOX_TESTING.md`) — recommended  
2. Connect products (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)  
3. Archive + upload build  
4. **This purchase report**  
5. Full app smoke (`TESTFLIGHT_SMOKE.md`)  
6. App Review submit only if overall result is **Pass**

| Meta | Value |
|---|---|
| Build / version | __________ |
| Commit / build number | __________ |
| Device | __________ |
| Sandbox Apple ID used | __________ (do not commit secrets) |
| Tester | __________ |
| Date | __________ |
| Overall result | **Not run** |

**Phase 65:** Still **Not run** until Shawn fills Pass/Fail with a real TestFlight/sandbox run. Agents must not mark Pass.

Prerequisites:
- [ ] Connect subscriptions created — still **Not done** in repo by default
- [ ] Build uploaded to TestFlight
- [ ] Sandbox tester created
- [ ] Legal URLs open: Terms of Use + Privacy Statement

Related: `STOREKIT_SANDBOX_TESTING.md`, `TESTFLIGHT_SMOKE.md`.

---

## A. Product loading
| Case | Status | Notes |
|---|---|---|
| Monthly product appears | **Not run** | |
| Yearly product appears | **Not run** | |
| Prices match App Store Connect (StoreKit displayPrice) | **Not run** | |
| Terms of Use visible | **Not run** | |
| Privacy Statement visible | **Not run** | |
| Restore Purchases visible | **Not run** | |

## B. Monthly purchase
| Case | Status | Notes |
|---|---|---|
| Purchase monthly succeeds | **Not run** | |
| Entitlement changes to Pro | **Not run** | |
| Unlimited product creation unlocks | **Not run** | |
| Free core workflow still works (export/Photo Check/edit) | **Not run** | |

## C. Yearly purchase
| Case | Status | Notes |
|---|---|---|
| Purchase yearly (if practical) | **Not run** | |
| Entitlement changes to Pro | **Not run** | |

## D. Restore
| Case | Status | Notes |
|---|---|---|
| Delete/reinstall if practical | **Not run** | |
| Restore Purchases | **Not run** | |
| Pro entitlement returns | **Not run** | |

## E. Expired / cancelled / no purchase
| Case | Status | Notes |
|---|---|---|
| No verified purchase → Free | **Not run** | |
| Existing products remain accessible | **Not run** | |
| Over-limit products not deleted | **Not run** | |

## F. Safety checks
| Case | Status | Notes |
|---|---|---|
| No Direct Upload button / claim | **Not run** | |
| No AI feature | **Not run** | |
| No backend/account required for Free | **Not run** | |
| No marketplace login required | **Not run** | |

---

## Blockers (if any)
- __________

## Sign-off
I confirm the statuses above reflect real device/TestFlight testing (not assumptions).

Signature / initials: __________  
Date: __________
