# StoreKit Sandbox / Local Verification — Yofai

**Phase 55** — local StoreKit config + pointer to TestFlight report.  
UI purchase checks are **manual**. Cursor unit tests do **not** count as purchase verification.

Status values for tables below: **Not run** | **Pass** | **Fail** | **Blocked**  
Repo default for all UI purchase rows: **Not run**

Related:
- `APP_STORE_SUBMIT_GATES.md` — master status
- `APP_STORE_CONNECT_SUBSCRIPTIONS.md` — Connect sign-off
- `TESTFLIGHT_PURCHASE_VERIFICATION.md` — TestFlight Pass/Fail report
- `APP_STORE_ARCHIVE_RUNBOOK.md` — archive/upload
- `RELEASE_CHECKLIST.md`

## Verification order (Phase 56)
1. This local StoreKit smoke  
2. Connect products configured  
3. Archive + upload  
4. TestFlight purchase report  
5. Full app smoke (`TESTFLIGHT_SMOKE.md`)  
6. Gates Passed → App Review  

## Prerequisites
- [ ] Phase 53+ StoreKit code on the build
- Product IDs:
  - `com.shawnwright.yofai.pro.monthly`
  - `com.shawnwright.yofai.pro.yearly`
- [ ] For TestFlight: Connect products created (sign-off still **Not done** unless you updated that doc)

## A. Local StoreKit Configuration (Xcode + iPhone 16e)

| Step | Status | Notes |
|---|---|---|
| Scheme → StoreKit Configuration → `Yofai.storekit` | **Not run** | Manual |
| Launch app; Settings → Yofai Pro | **Not run** | |
| Plan shows Free | **Not run** | |
| Open Upgrade paywall | **Not run** | |
| Monthly + yearly load with StoreKit prices | **Not run** | |
| Restore Purchases visible | **Not run** | |
| Terms of Use opens Apple EULA | **Not run** | |
| Privacy Statement opens GitHub Pages privacy URL | **Not run** | |
| Purchase monthly → Pro | **Not run** | |
| Restore still Pro | **Not run** | |
| Expire/cancel in StoreKit transactions → Free | **Not run** | |
| Existing products not deleted | **Not run** | |
| Free can still export local JPEGs | **Not run** | |

### Local unavailable-path check
| Step | Status | Notes |
|---|---|---|
| Clear StoreKit Configuration / no products | **Not run** | |
| Shows “Purchases are not available right now.” | **Not run** | |
| No fake dollar price buttons | **Not run** | |
| Terms + Privacy still visible | **Not run** | |
| Restore still visible | **Not run** | |
| Free export still works | **Not run** | |

**Local StoreKit overall (repo default):** **Not run** — requires manual UI on simulator/device.

## B. TestFlight / sandbox
Use `TESTFLIGHT_PURCHASE_VERIFICATION.md` for the scored report. Do not mark Pass here until that report is filled.

High-level gate before App Store submit:
1. Connect subscriptions created + cleared for review
2. Build on TestFlight
3. Sandbox tester ready
4. Monthly purchase **Pass**
5. Restore **Pass**
6. Free fallback **Pass**
7. Legal links opened **Pass**
8. Screenshots updated if paywall is in App Store metadata

## C. Automated (Cursor / CI)
| Check | Status |
|---|---|
| Full unit suite on iPhone 16e | Run on each phase closeout — not a purchase proof |
| Product ID / legal URL unit assertions | Covered by Phase 53–55 style tests |

## Sign-off
- Build / version: __________  
- Method: StoreKit config / TestFlight  
- Tester: __________  
- Date: __________  
- Result: **Not run** / Pass / Fail
