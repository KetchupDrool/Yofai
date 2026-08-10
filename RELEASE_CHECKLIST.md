# Release Checklist — Yofai

Short checklist for App Store / TestFlight upload of freemium Local Export Mode.

## Before archive
- [ ] Version / build (`CFBundleShortVersionString` / `CFBundleVersion`) bumped if needed
- [ ] Display name **Yofai**, bundle ID `com.shawnwright.yofai`
- [ ] App icon present; launch screen shows correctly
- [ ] Camera + Photos Add usage strings accurate (seller photo prep / Save Listing Copy)
- [ ] Settings → Privacy matches local-only behavior
- [ ] Settings → Yofai Pro: Free plan; Pro not available; no purchase charged
- [ ] Settings → Etsy Shop: connection not available (no Connect button)
- [ ] Listing Assistant labeled Not Available / offline
- [ ] Support + Privacy Policy URLs open (GitHub Pages)
- [ ] `APP_STORE_METADATA.md` claims still factual
- [ ] No StoreKit buy/restore UI
- [ ] No Direct Upload / publish / compliance claims in active UI

## Tests
- [ ] Full unit suite on **iPhone 16e**
- [ ] Release/Debug build succeeds
- [ ] Manual smoke: create product → photo check → edit → export → View Exported Files → share

## App Store Connect
- [ ] Screenshots per `APP_STORE_PREP.md` plan
- [ ] Subtitle + description + keywords pasted from `APP_STORE_METADATA.md`
- [ ] Privacy nutrition labels match local-only behavior (no tracking)
- [ ] Support URL + Privacy Policy URL set
- [ ] Age rating completed

## Upload
- [ ] Archive in Xcode
- [ ] Upload to App Store Connect
- [ ] TestFlight smoke on a physical iPhone
- [ ] Submit for review when ready

## Do not ship if
- Fake Pro purchase / pricing appears
- UI claims marketplace upload or compliance
- Live OAuth Connect is offered while config incomplete
- Privacy docs still describe old “simple photo editor only” product
