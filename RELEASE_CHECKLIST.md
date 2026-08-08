# Release Checklist — Yofai

Deadline: **2026-08-13**

## Confirmed in App
- [x] Display name: Yofai
- [x] Bundle ID: `com.shawnwright.yofai`
- [x] iPhone-only
- [x] Photos add string present and clear (Save Copy only)
- [x] No backend / login / payments / ads / tracking / AI API
- [x] AppIcon present: 1024×1024 PNG, RGB, no transparency (placeholder OK)

## App Store Connect Fields Still Needed
Fill these in ASC (copy from `APP_STORE_METADATA.md` where drafted):

| Field | Status |
| --- | --- |
| App Name | Ready: Yofai |
| Subtitle | Draft ready — paste |
| Promotional Text | Draft ready — paste |
| Description | Draft ready — paste |
| Keywords | Draft ready — paste |
| Support URL | **BLOCKER** — host real URL |
| Privacy Policy URL | **BLOCKER** — host real URL |
| Category | Photo & Video |
| Copyright | © 2026 Shawn Wright |
| Age Rating questionnaire | Complete in ASC |
| App Privacy nutrition labels | Declare: no tracking; Photos used only to save user-initiated copies; no data collected to server |
| Pricing | Free (unless you choose otherwise) |
| Screenshots | **BLOCKER** — capture below |
| Build | Archive + upload from Xcode |

## Icon Requirement
- Exactly **1024×1024** PNG
- **No transparency / no alpha**
- No rounded corners baked in (Apple applies mask)
- Current placeholder meets size/opacity; replace with final art if you want before upload

## Screenshot Plan

### Required sizes
| Display | Pixel size | Example simulators |
| --- | --- | --- |
| iPhone 6.7" | **1290 × 2796** | iPhone 15 Pro Max, 16 Plus |
| iPhone 6.1" | **1179 × 2556** | iPhone 15 Pro, 16 |

Capture portrait only.

### Shots to take (same set on both sizes)
1. **Edit** — filters + rotate controls visible (hero)
2. **Import** — photo selected
3. **Home** — empty or with recent prompt
4. **History** — at least one saved edit row

Optional: Settings with local-only privacy note.

### ASC order
1. Edit → 2. Import → 3. Home → 4. History

## Privacy Strings
- Required: `NSPhotoLibraryAddUsageDescription` ✓  
  “Yofai saves a copy of your edited photo to Photos only when you tap Save Copy.”
- Not needed: full library read, camera, tracking (`NSUserTrackingUsageDescription`), mic, contacts, location

## Final Blockers Before Archive/Upload
1. Host **Privacy Policy URL** (from `PRIVACY_NOTES.md`)
2. Host **Support URL**
3. Capture **screenshots** (6.7" + 6.1")
4. Optional: final AppIcon art
5. Xcode **Product → Archive** → Distribute to App Store Connect
