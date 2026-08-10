# Release Checklist — Yofai

**Phase 52 — App Store / TestFlight submit path** for freemium Local Export Mode.

Do **not** archive/upload in automation unless explicitly requested. Check boxes as you perform steps.

## A. Repo / product gate
- [ ] `main` clean and matches intended release commit
- [ ] Phase 50 App Store prep + Phase 51 no-AI cleanup already on `main`
- [ ] No unapproved feature work on the release branch
- [ ] Display name **Yofai**, bundle ID `com.shawnwright.yofai`
- [ ] Version (`MARKETING_VERSION` / `CFBundleShortVersionString`): currently **1.0** — bump if Connect already has this build
- [ ] Build (`CURRENT_PROJECT_VERSION` / `CFBundleVersion`): currently **1** — bump every upload
- [ ] App icon present (`AppIcon`)
- [ ] Launch screen shows correctly
- [ ] Camera + Photos Add usage strings accurate (`Info.plist`)
- [ ] Settings → Privacy matches local-only behavior
- [ ] Settings → Yofai Pro: plan shown; Upgrade/Manage + Restore Purchases
- [ ] Paywall: StoreKit prices when loaded, or purchases-unavailable copy (Free still works)
- [ ] App Store Connect subscription products created per `APP_STORE_CONNECT_SUBSCRIPTIONS.md` before relying on live purchase
- [ ] Settings → Etsy Shop: connection not available (no Connect button)
- [ ] No AI assistant / AI-powered claims in active UI
- [ ] No Direct Upload / publish / compliance claims in active UI
- [ ] Support + Privacy Policy URLs open (GitHub Pages)
- [ ] `APP_STORE_METADATA.md` claims still factual
- [ ] No fake purchase success path

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
- [ ] Privacy answers from `APP_STORE_CONNECT_PRIVACY.md` (no tracking)
- [ ] Support URL + Privacy Policy URL set
- [ ] Category + age rating completed
- [ ] Copyright / EULA set

## E. Archive & upload (manual in Xcode / Transporter)
- [ ] Archive Release build for **Any iOS Device (arm64)**
- [ ] Validate archive
- [ ] Upload to App Store Connect
- [ ] Wait for processing
- [ ] Attach build to version

## F. TestFlight
- [ ] Internal testing first (recommended)
- [ ] External testing only if needed ( steers App Review extras)
- [ ] Re-run critical smoke on TestFlight build (`TESTFLIGHT_SMOKE.md`)

## G. Submit for App Review
- [ ] Final metadata + screenshots attached to the build
- [ ] Review notes confirm: no login, no purchase charged, local JPEG export only, no Direct Upload, no AI
- [ ] Submit for review
- [ ] Monitor Resolution Center

## Do not ship if
- Fake Pro purchase / pricing / Restore Purchases appears
- UI claims marketplace upload, publish, or compliance
- Live OAuth Connect is offered while config incomplete
- AI / OpenAI / assistant is presented as a product feature
- Privacy docs disagree with on-device-only behavior
- Preset raw values or dimensions were changed without approval

## Related
- `APP_STORE_PREP.md`, `APP_STORE_METADATA.md`, `APP_STORE_CONNECT_PRIVACY.md`, `TESTFLIGHT_SMOKE.md`
