# App Store Metadata — Yofai

**Phase 52 — App Store submit-path package**  
(Builds on Phase 50 prep + Phase 51 no-AI cleanup.)

Do not claim Direct Upload, Pro purchases, AI features, compliance, or marketplace partnership.

## App Name
Yofai

## Subtitle options (≤30 characters)
1. **Marketplace photo prep** (recommended)
2. Local listing photo export
3. Seller photo prep, local

## Bundle ID
`com.shawnwright.yofai`

## SKU
`yofai-ios`

## Category
Photo & Video  
Secondary (optional): Shopping

## Promotional Text (≤170 characters, draft)
Prepare marketplace product photos on your iPhone. Export local JPEGs sized for sellers, then upload them yourself in the marketplace app or website.

## Short Description (one sentence)
Yofai helps online sellers prepare marketplace product photos as local JPEG exports for manual upload.

## Full Description (draft)

Yofai helps online sellers prepare product photos for marketplaces — on your iPhone, without an account.

**What Yofai does**
• Start a product and organize photo sets  
• Capture and check product photos  
• Edit, crop, and fit photos for export  
• Prepare for marketplace targets with verified export sizes  
• Export local JPEGs for manual upload  
• Keep export history and optional notes on device  
• View and share exported files from history  

**Seller workflow**
Capture → Organize → Photo Check → Edit → Prepare → Local Export

**Local Export Mode**
Yofai prepares listing-ready JPEGs on your device. You upload those files yourself in Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, or similar — using each marketplace’s own app or website.

**Free core workflow**
The Free plan keeps the core local export workflow. Yofai Pro is an optional subscription (monthly/yearly via Apple) for additive extras such as unlimited products. Purchases use StoreKit when products are available in App Store Connect.

**What Yofai does not do**
• Does not upload or publish listings to marketplaces  
• Does not claim marketplace compliance or official approval  
• Does not require an account or cloud sync for local export  
• Does not use AI — Photo Check and readiness tips are deterministic local tools  
• Does not require Pro for the core Capture → Edit → Local Export workflow  

**Privacy**
Photos, projects, edits, export history, and notes stay on your device. No ads. No tracking SDKs. No AI service receives your photos or listing data.

## Keywords (≤100 characters, draft)
marketplace,photo,seller,export,etsy,ebay,listing,jpeg,product,local,prep,crop

Character count check when pasting into App Store Connect (must be ≤100).

## Support URL checklist
- [ ] URL: https://ketchupdrool.github.io/Yofai/support.html
- [ ] Opens in Safari without login
- [ ] Mentions local export / support contact accurately
- [ ] Does not claim AI, Direct Upload, or live marketplace connection

## Privacy Policy URL checklist
- [ ] URL: https://ketchupdrool.github.io/Yofai/privacy-policy.html
- [ ] Opens in Safari without login
- [ ] Matches `PRIVACY_NOTES.md` / `APP_STORE_CONNECT_PRIVACY.md`
- [ ] States photos stay on device; no AI service; no marketplace upload

## EULA
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

## Copyright
© 2026 Shawn Wright

## Age Rating Notes
Utility for product photo prep. No public UGC feed, no social network, no ads. No unrestricted web browsing. Camera/Photos used only for seller product photo prep and optional Save Listing Copy.

## What’s New (1.0 release notes draft)
Yofai 1.0 helps sellers prepare marketplace product photos on device and export local JPEGs for manual upload. Free includes the core Capture → Edit → Local Export workflow. No account required.

## App Review Notes (paste into App Store Connect)

```text
Yofai does not require a login or account.

Purchases: Yofai Pro is an optional auto-renewable subscription (monthly and yearly) via StoreKit 2. Free users keep the full core local export workflow without purchasing. Restore Purchases is available in Settings → Yofai Pro and on the paywall. The paywall includes Terms of Use (Apple Standard EULA) and Privacy Statement (https://ketchupdrool.github.io/Yofai/privacy-policy.html).

Product IDs:
- com.shawnwright.yofai.pro.monthly
- com.shawnwright.yofai.pro.yearly

If subscription products are not yet available in this build’s environment, the paywall shows “Purchases are not available right now.” Legal links remain visible. Free remains fully usable.

What the app does: sellers capture/import product photos, check and edit them on device, then export local JPEG files for manual upload in marketplace apps/websites.

What the app does not do:
- Does not upload or publish to marketplaces
- Direct Upload Mode is not implemented
- No marketplace account connection is required
- Live Etsy OAuth/upload is disabled (Settings shows “Etsy connection not available”; no Connect button)
- No AI features are included
- Photos remain local on device

Demo path (Free): create a product → add a photo → Photo Check → Edit → Prepare Listing & Export → Export Photos → View Exported Files / Share.
Demo path (Pro): Settings → Yofai Pro → purchase or Restore Purchases (sandbox), then confirm unlimited product create.
```

## Subscriptions / IAP
See `APP_STORE_CONNECT_SUBSCRIPTIONS.md` + `STOREKIT_SANDBOX_TESTING.md`.  
Product IDs: `com.shawnwright.yofai.pro.monthly`, `com.shawnwright.yofai.pro.yearly`.  
Intended tiers: $4.99/month, $39.99/year (live price from StoreKit).  
Paywall legal links: **Terms of Use** (Apple Standard EULA) + **Privacy Statement** (https://ketchupdrool.github.io/Yofai/privacy-policy.html).  
Connect product creation and sandbox purchase verification are **manual** and not claimed complete by this repo alone.
## Build settings (current project)
- Display name: Yofai  
- Bundle ID: `com.shawnwright.yofai`  
- iPhone only (portrait)  
- Marketing version: **1.0**  
- Build: **1** — bump before each App Store Connect upload if needed  
- Camera usage: product photo capture into local Item Project  
- Photos add usage: optional Save Listing Copy only  

## Related docs
- `APP_STORE_PREP.md` — positioning + screenshot plan  
- `APP_STORE_CONNECT_PRIVACY.md` — App Store Connect privacy answers  
- `TESTFLIGHT_SMOKE.md` — manual smoke script  
- `RELEASE_CHECKLIST.md` — archive / upload / submit  
- `PRIVACY_NOTES.md` + hosted `docs/privacy-policy.html` / `docs/support.html`
