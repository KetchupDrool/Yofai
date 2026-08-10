# Release Checklist — Yofai

Master tracker: **`APP_STORE_SUBMIT_GATES.md`**.  
Archive steps: **`APP_STORE_ARCHIVE_RUNBOOK.md`**.

Freemium Local Export Mode + StoreKit Pro. Do **not** archive/upload/submit in automation unless requested. Do **not** mark gates Passed without evidence.

## Required order
1. Local StoreKit smoke (`STOREKIT_SANDBOX_TESTING.md`) — recommended  
2. Connect IAP configured (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)  
3. Archive + upload (`APP_STORE_ARCHIVE_RUNBOOK.md`)  
4. TestFlight purchase verification (`TESTFLIGHT_PURCHASE_VERIFICATION.md`) → **Pass**  
5. Full app smoke (`TESTFLIGHT_SMOKE.md`)  
6. Screenshots + metadata (`APP_STORE_PREP.md`, `APP_STORE_METADATA.md`)  
7. Update `APP_STORE_SUBMIT_GATES.md` to Passed  
8. Submit for App Review  

## A. Repo / product gate
- [ ] `main` clean on intended commit
- [ ] Display name **Yofai**, bundle ID `com.shawnwright.yofai`
- [ ] Version/build checklist in `APP_STORE_ARCHIVE_RUNBOOK.md` (bump build before each upload)
- [ ] App icon + launch screen OK
- [ ] Camera + Photos Add usage strings accurate
- [ ] Settings → Yofai Pro + paywall legal links OK
- [ ] No AI / Direct Upload / publish claims in UI
- [ ] Support + Privacy URLs open

## A2. IAP / purchase gate
- [ ] Connect products created + cleared for review
- [ ] `TESTFLIGHT_PURCHASE_VERIFICATION.md` real **Pass** results
- [ ] Screenshots reviewed (Pro frame only if StoreKit prices real or unavailable shown honestly)

## B. Automated
- [ ] Full unit suite on **iPhone 16e**
- [ ] Build succeeds on iPhone 16e

## C–G. Manual submit path
Follow `APP_STORE_ARCHIVE_RUNBOOK.md` and sections in `APP_STORE_SUBMIT_GATES.md` (D–F).

## Do not ship if
- Connect IAP missing or TestFlight purchase still Not run / Fail
- Fake Pro pricing when products unavailable
- Upload/publish/compliance/AI claims in UI
- Gates in `APP_STORE_SUBMIT_GATES.md` not Passed

## Related
`APP_STORE_SUBMIT_GATES.md` · `APP_STORE_ARCHIVE_RUNBOOK.md` · `APP_STORE_PREP.md` · `APP_STORE_METADATA.md` · `APP_STORE_CONNECT_PRIVACY.md` · `APP_STORE_CONNECT_SUBSCRIPTIONS.md` · `STOREKIT_SANDBOX_TESTING.md` · `TESTFLIGHT_PURCHASE_VERIFICATION.md` · `TESTFLIGHT_SMOKE.md`
