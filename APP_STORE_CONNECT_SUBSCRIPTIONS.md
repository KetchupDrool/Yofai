# App Store Connect — Yofai Pro Subscriptions

**Phase 53** — manual setup required before live purchases work.  
This checklist is **not** complete until you verify each step in App Store Connect.

## Product IDs (in app)
| Product | ID | Intended price |
|---|---|---|
| Monthly | `com.shawnwright.yofai.pro.monthly` | **$4.99**/month |
| Yearly | `com.shawnwright.yofai.pro.yearly` | **$39.99**/year |

Subscription group name: **Yofai Pro**

Local StoreKit config for Xcode/simulator: `Yofai/Yofai.storekit`  
Attach it in the Yofai scheme → Run → Options → StoreKit Configuration.

## Manual Connect steps
- [ ] Create subscription group **Yofai Pro**
- [ ] Create auto-renewable monthly product with ID `com.shawnwright.yofai.pro.monthly`
- [ ] Set localization display name/description; price tier ≈ $4.99/month
- [ ] Create auto-renewable yearly product with ID `com.shawnwright.yofai.pro.yearly`
- [ ] Set localization; price tier ≈ $39.99/year
- [ ] Fill subscription review information / screenshot if required
- [ ] Confirm Restore Purchases works in sandbox (Settings + paywall)
- [ ] TestFlight sandbox purchase + restore before App Review
- [ ] Update App Store screenshots/metadata if Pro paywall is shown

## App behavior (already in code)
- Free keeps core local export without purchase
- Pro unlocks unlimited products (additive)
- Prices shown from StoreKit when products load
- If products fail to load: “Purchases are not available right now.” — Free still works
- No fake purchase success
- Cloud backup / Direct Upload remain not implemented

## Privacy / legal
- Privacy Policy + Support links on paywall
- “Manage or cancel subscriptions in App Store settings”
- Paid apps / IAP privacy nutrition labels may need Paid Apps / Purchases disclosure when products go live
