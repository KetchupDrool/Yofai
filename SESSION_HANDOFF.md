# Session Handoff

## Status
Phase 54 complete — Connect subscription checklist + sandbox verification plan + paywall legal links.  
**301 tests passed; build on iPhone 16e.** StoreKit 2 Pro foundation (Phase 53) remains. **Connect products not claimed created.**  
Do not submit until `APP_STORE_CONNECT_SUBSCRIPTIONS.md` and `STOREKIT_SANDBOX_TESTING.md` are manually completed.

## Legal links (verified in code)
- Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Privacy Statement: https://ketchupdrool.github.io/Yofai/privacy-policy.html

## Product IDs
- `com.shawnwright.yofai.pro.monthly` ($4.99 intended)
- `com.shawnwright.yofai.pro.yearly` ($39.99 intended)

## Last Completed
- Phase 54 readiness docs + paywall Terms/Privacy + Phase54 tests

## Next Recommended
1. Create Connect subscription group/products (manual)
2. Run `STOREKIT_SANDBOX_TESTING.md` (StoreKit config, then TestFlight sandbox)
3. Then `RELEASE_CHECKLIST.md` submit path

## Rules
- Freemium-first; no fake purchases; Free keeps core local export
- No AI / Direct Upload / backend unless approved
- Unit tests: iPhone 16e
