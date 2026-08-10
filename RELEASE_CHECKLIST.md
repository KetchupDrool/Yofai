# Release Checklist — Yofai

**App Store / TestFlight submit path** for freemium Local Export Mode + StoreKit Pro.

Do **not** archive/upload in automation unless explicitly requested. Check boxes as you perform steps.

## A. Repo / product gate
- [ ] `main` clean and matches intended release commit
- [ ] Display name **Yofai**, bundle ID `com.shawnwright.yofai`
- [ ] Version (`MARKETING_VERSION` / `CFBundleShortVersionString`): currently **1.0** — bump if Connect already has this build
- [ ] Build (`CURRENT_PROJECT_VERSION` / `CFBundleVersion`): currently **1** — bump every upload
- [ ] App icon present (`AppIcon`); launch screen OK
- [ ] Camera + Photos Add usage strings accurate (`Info.plist`)
- [ ] Settings → Privacy matches local-only behavior
- [ ] Settings → Yofai Pro: plan; Upgrade/Manage; Restore Purchases
- [ ] Paywall: StoreKit prices when loaded, or purchases-unavailable (Free still works)
- [ ] Paywall **Terms of Use** + **Privacy Statement** visible (including unavailable state)
- [ ] Settings → Etsy Shop: connection not available (no Connect button)
- [ ] No AI / Direct Upload / publish / compliance claims in active UI
- [ ] Support + Privacy Policy URLs open
- [ ] No fake purchase success path

## A2. StoreKit / IAP gate (required before submit)
**Do not submit until these are really done** (see sign-off docs; repo defaults remain Not done / Not run):

- [ ] App Store Connect subscription group **Yofai Pro** created (`APP_STORE_CONNECT_SUBSCRIPTIONS.md`)
- [ ] Monthly product `com.shawnwright.yofai.pro.monthly` live / cleared for review ($4.99 intended)
- [ ] Yearly product `com.shawnwright.yofai.pro.yearly` live / cleared for review ($39.99 intended)
- [ ] Subscription localizations + review info (+ paywall screenshot if required)
- [ ] Sandbox tester created
- [ ] Build uploaded to **TestFlight**
- [ ] `TESTFLIGHT_PURCHASE_VERIFICATION.md` filled with real **Pass** results for:
  - [ ] Product loading (monthly + yearly + prices)
  - [ ] Monthly purchase → Pro
  - [ ] Restore Purchases
  - [ ] Free fallback / no data deletion
  - [ ] Legal links open
- [ ] Local StoreKit config smoke optional but recommended (`STOREKIT_SANDBOX_TESTING.md`)
- [ ] App Store screenshots updated if paywall is shown in metadata

## B. Automated verification
- [ ] Full unit suite on **iPhone 16e**
- [ ] Debug (and Release if used) build succeeds on iPhone 16e

## C. Manual smoke
- [ ] Follow `TESTFLIGHT_SMOKE.md` (simulator for flow; **physical iPhone** for Camera/Photos/Share before submit)

## D. App Store Connect metadata
- [ ] Screenshots per `APP_STORE_PREP.md` plan
- [ ] Subtitle + promotional text + description + keywords from `APP_STORE_METADATA.md`
- [ ] What’s New / release notes pasted
- [ ] App Review notes pasted from `APP_STORE_METADATA.md`
- [ ] Privacy answers from `APP_STORE_CONNECT_PRIVACY.md` (include Purchases when IAP live)
- [ ] Support URL + Privacy Policy URL set
- [ ] Category + age rating completed
- [ ] Copyright / EULA set (Apple Standard EULA OK with Terms of Use link in-app)

## E. Archive & upload (manual in Xcode / Transporter)
- [ ] Archive Release build for **Any iOS Device (arm64)**
- [ ] Validate archive
- [ ] Upload to App Store Connect
- [ ] Wait for processing
- [ ] Attach build to version

## F. TestFlight
- [ ] Internal testing first (recommended)
- [ ] Complete `TESTFLIGHT_PURCHASE_VERIFICATION.md` before external/submit
- [ ] Re-run critical smoke on TestFlight build (`TESTFLIGHT_SMOKE.md`)

## G. Submit for App Review
- [ ] Final metadata + screenshots attached to the build
- [ ] Review notes confirm: no login required for Free; optional Pro via StoreKit; local JPEG export; no Direct Upload; no AI
- [ ] Submit for review
- [ ] Monitor Resolution Center

## Do not ship if
- Connect IAP products missing or not cleared for review
- TestFlight purchase verification still **Not run** / Fail
- Fake Pro purchase / pricing when products unavailable
- UI claims marketplace upload, publish, or compliance
- Live OAuth Connect offered while config incomplete
- AI presented as a product feature
- Privacy docs disagree with on-device-only Free workflow
- Preset raw values or dimensions changed without approval

## Related
- `APP_STORE_CONNECT_SUBSCRIPTIONS.md`
- `STOREKIT_SANDBOX_TESTING.md`
- `TESTFLIGHT_PURCHASE_VERIFICATION.md`
- `APP_STORE_PREP.md`, `APP_STORE_METADATA.md`, `APP_STORE_CONNECT_PRIVACY.md`, `TESTFLIGHT_SMOKE.md`
