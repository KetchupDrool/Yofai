# Release Checklist — Yofai

Master tracker: **`APP_STORE_SUBMIT_GATES.md`**. Owner checklist: **`SHAWN_NEXT_RELEASE_STEPS.md`**.  
Archive steps: **`APP_STORE_ARCHIVE_RUNBOOK.md`**.

Freemium Local Export Mode + StoreKit Pro. Do **not** archive/upload/submit in automation unless requested. Do **not** mark gates Passed without evidence.

## Phase 57 local verification (automated)
- [x] Full unit suite on iPhone 16e — **Passed** (301)
- [x] Build on iPhone 16e — **Passed**

## Required order
1. Local StoreKit smoke (`STOREKIT_SANDBOX_TESTING.md`) — recommended  
2. Connect IAP configured (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)  
3. Archive + upload (`APP_STORE_ARCHIVE_RUNBOOK.md`) — **bump build from 1 first**  
4. TestFlight purchase verification (`TESTFLIGHT_PURCHASE_VERIFICATION.md`) → **Pass**  
5. Full app smoke (`TESTFLIGHT_SMOKE.md`)  
6. Screenshots + metadata (`APP_STORE_PREP.md`, `APP_STORE_METADATA.md`)  
7. Update `APP_STORE_SUBMIT_GATES.md` to Passed with evidence  
8. Submit for App Review  

## Do not ship if
- Connect IAP missing or TestFlight purchase still Not run / Fail
- Fake Pro pricing when products unavailable
- Upload/publish/compliance/AI claims in UI
- Gates in `APP_STORE_SUBMIT_GATES.md` not Passed

## Related
`APP_STORE_SUBMIT_GATES.md` · `SHAWN_NEXT_RELEASE_STEPS.md` · `APP_STORE_ARCHIVE_RUNBOOK.md` · `APP_STORE_PREP.md` · `APP_STORE_METADATA.md` · `APP_STORE_CONNECT_PRIVACY.md` · `APP_STORE_CONNECT_SUBSCRIPTIONS.md` · `STOREKIT_SANDBOX_TESTING.md` · `TESTFLIGHT_PURCHASE_VERIFICATION.md` · `TESTFLIGHT_SMOKE.md`
