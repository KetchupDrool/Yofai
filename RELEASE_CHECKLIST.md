# Release Checklist — Yofai

Master tracker: **`APP_STORE_SUBMIT_GATES.md`**. Owner guide: **`SHAWN_NEXT_RELEASE_STEPS.md`**.  
Archive steps: **`APP_STORE_ARCHIVE_RUNBOOK.md`**. Screenshots: **`APP_STORE_PREP.md`**. Connect IAP: **`APP_STORE_CONNECT_SUBSCRIPTIONS.md`**.

Freemium Local Export Mode + StoreKit Pro. Do **not** archive/upload/submit in automation unless requested. Do **not** mark gates Passed without evidence.

## Local verification (automated)
- [x] Full unit suite on iPhone 16e — **Passed** (Phase 65: 354 tests)
- [x] Build on iPhone 16e — **Passed** (Phase 65)
- [x] Owner Connect + screenshot execution guide — **Passed** (docs; refreshed Phase 65)
- [x] Local multi-market arc Phases 61–64 — **Passed** (product code; Local Export only)

## Still open (Shawn / manual)
- [ ] App Store Connect Yofai Pro products (`…pro.monthly` / `…pro.yearly`, $4.99 / $39.99 intended)
- [ ] Screenshots captured + uploaded (`APP_STORE_PREP.md`)
- [ ] Build bumped from **1** before archive
- [ ] Archive + upload (after approval)
- [ ] TestFlight purchase verification filled with Pass
- [ ] Metadata / privacy / App Review notes pasted
- [ ] App Review submit (only after gates Pass)

## Required order (Shawn)
1. Before you start — §A in `SHAWN_NEXT_RELEASE_STEPS.md`  
2. Connect IAP — §B / `APP_STORE_CONNECT_SUBSCRIPTIONS.md`  
3. Screenshots — §C / `APP_STORE_PREP.md`  
4. Local StoreKit smoke — `STOREKIT_SANDBOX_TESTING.md` (recommended)  
5. Bump build → archive/upload — §D–E / `APP_STORE_ARCHIVE_RUNBOOK.md`  
6. TestFlight purchase — §F / `TESTFLIGHT_PURCHASE_VERIFICATION.md` → **Pass**  
7. Full app smoke — `TESTFLIGHT_SMOKE.md`  
8. Metadata + privacy — `APP_STORE_METADATA.md`, `APP_STORE_CONNECT_PRIVACY.md`  
9. Update `APP_STORE_SUBMIT_GATES.md` to Passed with evidence  
10. Submit for App Review  

## Do not ship if
- Connect IAP missing or TestFlight purchase still Not run / Fail
- Fake Pro pricing when products unavailable
- Upload/publish/compliance/AI claims in UI
- Gates in `APP_STORE_SUBMIT_GATES.md` not Passed

## Related
`APP_STORE_SUBMIT_GATES.md` · `SHAWN_NEXT_RELEASE_STEPS.md` · `APP_STORE_ARCHIVE_RUNBOOK.md` · `APP_STORE_PREP.md` · `APP_STORE_METADATA.md` · `APP_STORE_CONNECT_PRIVACY.md` · `APP_STORE_CONNECT_SUBSCRIPTIONS.md` · `STOREKIT_SANDBOX_TESTING.md` · `TESTFLIGHT_PURCHASE_VERIFICATION.md` · `TESTFLIGHT_SMOKE.md`
