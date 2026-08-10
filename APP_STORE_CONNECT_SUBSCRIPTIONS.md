# App Store Connect — Yofai Pro Subscriptions

**Phase 54** — step-by-step manual setup.  
**Status: NOT complete until you check every box in App Store Connect yourself.**  
This phase documents the path; it does not claim Connect products were created.

## Product IDs (must match app code)
| Reference name | Product ID | Intended price |
|---|---|---|
| Yofai Pro Monthly | `com.shawnwright.yofai.pro.monthly` | **$4.99**/month |
| Yofai Pro Yearly | `com.shawnwright.yofai.pro.yearly` | **$39.99**/year |

Subscription group: **Yofai Pro**

Local StoreKit config: `Yofai/Yofai.storekit`  
Scheme → Run → Options → StoreKit Configuration → select `Yofai.storekit`.

## Legal links (in app paywall)
| Label | URL |
|---|---|
| Terms of Use | https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ |
| Privacy Statement | https://ketchupdrool.github.io/Yofai/privacy-policy.html |

Confirm the Privacy Statement URL opens before submit. Hosted from `docs/privacy-policy.html`.

## Exact manual steps
1. [ ] Open [App Store Connect](https://appstoreconnect.apple.com)
2. [ ] Select the **Yofai** app (`com.shawnwright.yofai`)
3. [ ] Go to **Monetization → Subscriptions** (or In-App Purchases / Subscriptions)
4. [ ] Create subscription group: **Yofai Pro**
5. [ ] Create monthly auto-renewable subscription:
   - Product ID: `com.shawnwright.yofai.pro.monthly`
   - Reference name: **Yofai Pro Monthly**
   - Duration: 1 month
   - Price: tier ≈ **$4.99**/month
6. [ ] Create yearly auto-renewable subscription:
   - Product ID: `com.shawnwright.yofai.pro.yearly`
   - Reference name: **Yofai Pro Yearly**
   - Duration: 1 year
   - Price: tier ≈ **$39.99**/year
7. [ ] Add localization (en_US or primary):
   - Display name (e.g. Yofai Pro Monthly / Yofai Pro Yearly)
   - Description (unlimited products + additive Pro extras; Free keeps local export)
8. [ ] Add **subscription review information** (and paywall screenshot if Connect requires it)
9. [ ] Clear products for sale / for review with the app version you will submit
10. [ ] Create a **Sandbox Apple ID** tester (Users and Access → Sandbox)
11. [ ] Verify products load in:
    - Xcode + `Yofai.storekit`, and/or
    - TestFlight + sandbox account
12. [ ] Run purchase + Restore Purchases per `STOREKIT_SANDBOX_TESTING.md`

## Suggested localization copy
**Display name (monthly):** Yofai Pro Monthly  
**Display name (yearly):** Yofai Pro Yearly  

**Description:**  
Yofai Pro unlocks unlimited products and additive Pro extras. Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export. Direct Upload and cloud backup are not included.

## App behavior (already in code)
- Free keeps core local export without purchase
- Pro unlocks unlimited products after verified StoreKit entitlement
- UI prices come from StoreKit `displayPrice` when products load
- If products fail to load: “Purchases are not available right now.” — Free still works; legal links still visible
- Restore Purchases on Settings + paywall
- No fake purchase success
- Cloud backup / Direct Upload not implemented

## Privacy nutrition labels
When IAP goes live, update App Store Connect privacy answers for Purchases / Paid Apps as needed (`APP_STORE_CONNECT_PRIVACY.md`).
