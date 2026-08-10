# StoreKit Sandbox / TestFlight Purchase Verification — Yofai

**Phase 54** — manual purchase verification plan.  
Do not claim sandbox/TestFlight purchase was verified until you run these steps on a device/simulator and check the boxes.

Related: `APP_STORE_CONNECT_SUBSCRIPTIONS.md`, `TESTFLIGHT_SMOKE.md`, `RELEASE_CHECKLIST.md`.

## Prerequisites
- [ ] Phase 53 StoreKit code on the build you test
- [ ] Product IDs unchanged:
  - `com.shawnwright.yofai.pro.monthly`
  - `com.shawnwright.yofai.pro.yearly`
- [ ] For TestFlight/live sandbox: Connect subscription products created (not claimed done by agents)
- [ ] Sandbox tester Apple ID created (for device/TestFlight)

## A. Local StoreKit Configuration (Xcode)
1. [ ] Open Yofai scheme → Run → Options → **StoreKit Configuration** → `Yofai.storekit`
2. [ ] Run on **iPhone 16e** simulator (or a device)
3. [ ] Settings → **Yofai Pro**
4. [ ] Confirm current plan **Free**
5. [ ] Open Upgrade / Manage paywall
6. [ ] Confirm monthly and yearly options load with StoreKit prices (not invented fake prices)
7. [ ] Confirm **Restore Purchases** visible
8. [ ] Confirm **Terms of Use** → Apple Standard EULA
9. [ ] Confirm **Privacy Statement** → https://ketchupdrool.github.io/Yofai/privacy-policy.html
10. [ ] Purchase **monthly** in the StoreKit test sheet
11. [ ] Confirm plan becomes **Pro** / unlimited create works
12. [ ] Tap **Restore Purchases** — still Pro
13. [ ] In Xcode StoreKit transaction manager (if available): expire/cancel subscription
14. [ ] Refresh / relaunch — confirm **Free** fallback
15. [ ] Confirm existing products were **not** deleted
16. [ ] Confirm Free can still export local JPEGs

### Local unavailable-path check
1. [ ] Temporarily clear StoreKit Configuration (or use a build without products)
2. [ ] Paywall shows **Purchases are not available right now.**
3. [ ] No fake dollar price buttons
4. [ ] Terms of Use + Privacy Statement still visible
5. [ ] Restore Purchases still visible
6. [ ] Free export still works

## B. Sandbox / TestFlight (after Connect products exist)
1. [ ] Create Connect products + sandbox tester (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)
2. [ ] Upload a build; install via TestFlight on a physical iPhone
3. [ ] Sign out of Media & Purchases / use sandbox account when prompted (do not use your personal Apple ID for sandbox)
4. [ ] Settings → Yofai Pro → Upgrade
5. [ ] Confirm monthly/yearly **StoreKit** prices load from Connect
6. [ ] Purchase monthly → confirm Pro
7. [ ] Restore Purchases → still Pro
8. [ ] Delete app → reinstall TestFlight build → Restore → Pro returns
9. [ ] On a Free account / without purchase: create product, Photo Check, edit, export, View Exported Files — all work
10. [ ] Over Free limit (12): create blocked; existing products still open

## C. Pass criteria
- [ ] No fake purchase success without StoreKit
- [ ] Free core local export never requires purchase
- [ ] Legal links present on paywall
- [ ] Restore works
- [ ] No Direct Upload / AI / backend required

## Sign-off
- Build / version: __________  
- Method: StoreKit config / TestFlight sandbox  
- Tester: __________  
- Date: __________  
- Result: Pass / Fail (notes: __________)
