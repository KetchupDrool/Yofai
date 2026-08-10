# App Store Connect Privacy Answers — Yofai

**Phase 52 — paste-ready answers for App Store Connect privacy nutrition labels / questionnaire.**  
Aligned with `PRIVACY_NOTES.md` and hosted `docs/privacy-policy.html`.

**Last verified:** 2026-08-10

## Product facts
- Local-first marketplace product photo prep
- Local JPEG export for **manual** upload
- No account system
- No backend sync
- No analytics SDK
- No ads
- No AI service
- No marketplace login
- No Direct Upload / marketplace publish
- No tracking

## Data collection summary (current build)
Yofai does **not** collect data off-device for analytics, advertising, or developer servers in this version.

| Topic | Answer |
|---|---|
| Account / login | Not required; no account system |
| Contact info collected by app | No |
| Health / fitness | No |
| Financial info / purchases | Optional Yofai Pro subscriptions via Apple (StoreKit). Free workflow needs no purchase. |
| Location | No |
| Sensitive info | No |
| Contacts | No |
| User content uploaded to Yofai servers | No — photos stay on device |
| Browsing history | No |
| Search history | No |
| Identifiers for tracking | No |
| Usage data / analytics SDK | No |
| Diagnostics to developer | No third-party crash/analytics SDK |
| Advertising data | No ads |
| Other data linked to identity | No |

## On-device data (not “collected” off-device)
Stored locally in the app sandbox / SwiftData / local files:
- Product projects and photos
- Edits and listing drafts
- Export batch JPEG folders
- Export history metadata
- Optional export notes
- Seller defaults

Optional Keychain placeholders for a future Etsy connection exist in code; **live OAuth is not enabled** and is not part of this release.

## Photos & Camera — App Store Connect reasons
| Permission | Why |
|---|---|
| **Camera** | Capture product photos into a local Item Project for on-device prep and local JPEG export |
| **Photo Library Add** | Save a listing-ready copy only when the seller chooses **Save Listing Copy** |
| **System photo picker** | Import existing photos for products/edits (picker; no blanket library read claim) |

Do **not** claim:
- Cloud backup of photos
- Marketplace upload of photos
- AI processing of photos

## Privacy Policy / Support URLs
- Privacy: https://ketchupdrool.github.io/Yofai/privacy-policy.html  
- Support: https://ketchupdrool.github.io/Yofai/support.html  

## Tracking
App Tracking Transparency: **not used**. No tracking for cross-app advertising.

## Third-party SDKs
None for ads, analytics, AI, or backend auth in this release.
