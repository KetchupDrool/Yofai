# Yofai

## App
- Name: Yofai
- Bundle ID: com.shawnwright.yofai
- SKU: yofai-ios
- Type: Mosaic
- Platform: iPhone, SwiftUI, SwiftData

## Product purpose (locked 2026-08-09; modes clarified Phase 45)
Local-first marketplace product photo preparation for online sellers.

Core photo preparation is **local-first/on-device**.

### Local Export Mode (current)
- Prepare marketplace-sized images on-device
- Save/share local JPEGs
- Seller manually uploads in marketplace websites/apps
- Works offline and without marketplace login
- Remains available permanently as the fallback

### Direct Upload Mode (future only — not implemented)
- May later upload prepared images via **official** marketplace APIs/OAuth only
- Requires explicit phase approval and verified feasibility per marketplace
- Must not use browser automation, guessed endpoints, or marketplace passwords
- See `MARKETPLACE_UPLOAD_ROADMAP.md`

## What sellers do in Yofai today
- Photograph products
- Organize product photo sets
- Check photo quality
- Edit photos
- Resize/crop for marketplaces
- Prepare listing-ready **local** exports
- Export locally for Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar

Today those marketplaces are **local export targets** — Yofai does not upload or publish listings.

## Priority
Keep Local Export Mode solid. Do not start Direct Upload Mode coding until a marketplace-specific phase is approved after official API verification.

## Constraints (active)
- Core photo preparation remains local-first/on-device
- **Yofai does not use AI.** Photo Check, Export Readiness, and Prep Tips are deterministic/local. No OpenAI / AI APIs / AI listing assistant.
- Direct marketplace upload is **not implemented**; do not claim it exists
- No browser automation / unofficial APIs / marketplace password storage for upload

## Future capabilities (approved direction, not next work)
These may be added later where they support the product:
- Backend services (especially if Direct Upload Mode needs secure OAuth)
- User accounts
- Cloud sync
- Subscriptions / Yofai Pro via StoreKit (freemium-first; do not lock core Free workflow later)
- Ads
- Direct Upload Mode for verified marketplaces only

Core photo preparation stays local-first/on-device even if some of these arrive later.

**Not on the roadmap:** AI listing assistant, OpenAI integration, paid AI APIs, AI caption generation, AI photo evaluation, AI auto-crop.

## Primary workflow
Home → Start / Continue Product → Item Project → Capture & Check Photos → Prepare Listing & Export → local export.
Import, Originals, and History remain available as secondary tools.

## Status
- Phases 1–66 technical history complete (see `DECISIONS.md`, `APP_STORE_SUBMIT_GATES.md`, `SHAWN_NEXT_RELEASE_STEPS.md`)
- **Phase 66:** app-wide readability/navigation cleanup (DarkroomTheme contrast, form cards, tab clearance); no product-feature change; no Direct Upload
- **Phase 65:** App Store release gate prep (docs/verification); version **1.0** build **1** unchanged; Connect/TestFlight/screenshots/archive still manual
- **Phase 64:** Pro multi-market workflow polish; Free primary + local export stay available; no Direct Upload
- **Phase 63:** Pro per-marketplace templates/defaults; Free SellerDefaults preserved; no Direct Upload
- **Phase 62:** Pro draft-aware listing text copy/share; Free primary `ListingPackage` / export unchanged; no Direct Upload
- **Phase 61:** additive `MarketplaceListingDraft` (Pro multi-market); Free primary listing stays on `ItemProject`; no Direct Upload
- **APIs later:** marketplace APIs / Direct Upload wait until local prep is solid and a specific official API is approved (`DECISIONS.md` — Why marketplace APIs are not being done yet)
- **Phase 60:** docs-only marketplace workspace + freemium mapping lock (no app code). Free = one primary listing workflow per product; Pro multi-draft later via `advancedMultiMarketTools`. Manual listing packages only — no Direct Upload.
- **Phase 59:** first-launch welcome + guided walkthrough; Settings replay; rich SwiftUI mini-scenes per step; system launch screen unchanged
- **Phase 58:** owner Connect IAP + screenshot execution guide; manual gates still Needs user action / Not started
- **Phase 57:** local suite/build re-verified Passed; honest release gates
- **Phase 56:** screenshot packet, archive runbook, App Review notes, master submit gates
- Freemium-first: Free keeps core local export; Pro additive via StoreKit when Connect products exist. No Direct Upload.
- Marketplace target (destination) is separate from export size (pixel canvas)
- Local export history records what was **exported for** a marketplace — never publish/upload status
- Optional local seller notes on export batches are reminders only — not publish status; may optionally accompany share as text/reference or Copy Export Note
- Share/package labels use local JPEGs / manual upload wording (Phase 46)
- Export history supports viewing/re-sharing existing local JPEGs when files remain on disk; missing files show a safe message (Phase 47)
- Post-export next step offers View Exported Files on the just-created batch (Phase 48)
- Export history supports transient marketplace filters and metadata-only compare of the two newest exports (no pixel compare)
- Export Readiness checklist and Prep Tips are computed from local state (not persisted); tips never auto-change fit/crop/size; watermark is optional; no compliance claims
- Export fit modes: Contain + Pad (default) and Fill + Crop with optional per-photo reposition
- Verified local export canvases include Etsy sizes, eBay 1600×1600, Poshmark 1000×1000 (recommended; not compliance claims)
- Facebook Marketplace and Mercari intentionally have no named Yofai pixel presets until an exact first-party canvas is verified
- App Store upload remains paused
- Old framing (“general photo editor MVP within 6 days”) is no longer the main goal

## Rules
- Keep changes small. Do not refactor unrelated files.
- Inspect files before editing.
- Do not implement Direct Upload Mode unless explicitly re-approved.
- Do not add AI.
