# Shawn — Next Manual Release Steps

**Phase 57** — concise owner checklist. Details live in linked docs.  
Nothing below is marked done by the agent.

## Already verified locally (2026-08-10)
- [x] 301 unit tests passed on iPhone 16e  
- [x] Debug build succeeded on iPhone 16e  
- [x] Working tree clean on `main` @ Phase 56/57 docs baseline  
- [x] StoreKit IDs, Terms/Privacy URLs, Free local export intact in code  

## Still your action

### 1. App Store Connect IAP
Doc: `APP_STORE_CONNECT_SUBSCRIPTIONS.md`  
- [ ] Group **Yofai Pro**  
- [ ] `com.shawnwright.yofai.pro.monthly` @ ~$4.99/mo  
- [ ] `com.shawnwright.yofai.pro.yearly` @ ~$39.99/yr  
- [ ] Localizations + review info  
- [ ] Clear for review with the build you submit  

### 2. Screenshots
Doc: `APP_STORE_PREP.md`  
- [ ] Capture 8 screens (no fake Pro/AI/Direct Upload)  
- [ ] Upload to App Store Connect  

### 3. Local StoreKit smoke (recommended)
Doc: `STOREKIT_SANDBOX_TESTING.md`  
- [ ] Scheme → `Yofai.storekit`  
- [ ] Buy monthly → Pro; restore; Free fallback  

### 4. Archive / upload
Doc: `APP_STORE_ARCHIVE_RUNBOOK.md`  
- [ ] Confirm version **1.0**; **increment build** from **1** before upload  
- [ ] Archive Any iOS Device → Upload  

### 5. TestFlight purchase
Doc: `TESTFLIGHT_PURCHASE_VERIFICATION.md`  
- [ ] Products load; monthly purchase; restore; Free export without purchase  
- [ ] Fill report with Pass only if true  

### 6. Metadata + submit
Docs: `APP_STORE_METADATA.md`, `APP_STORE_CONNECT_PRIVACY.md`, `APP_STORE_SUBMIT_GATES.md`  
- [ ] Paste metadata + App Review notes  
- [ ] Verify https://ketchupdrool.github.io/Yofai/support.html and privacy-policy.html  
- [ ] Submit for App Review only when gates A–E are Passed  

## Do not
- Claim Connect/TestFlight/archive done without doing them  
- Show fake StoreKit prices or Pro success in screenshots  
- Lock Free core local export  
- Add Direct Upload / AI / backend for launch  
