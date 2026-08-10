# Marketplace Upload Roadmap

Checked against the Yofai codebase and publicly available official developer documentation (2026-08-09).  
**Direct Upload Mode is not implemented.** Local Export Mode is current production behavior.

## Current behavior (verified in code)

Yofai today:

- Renders marketplace-sized JPEGs on-device (`ProjectBatchExporter`, `ImageEditing`)
- Saves batches under Application Support / ExportBatches
- Records local export history on `ProjectExportBatch` (“exported for”, never “published”)
- Keeps marketplace **target** separate from export **canvas**
- Supports optional local export notes (`sellerNote`)
- Shares files via the system Share sheet only (optional note may accompany as share text / Copy Export Note — not marketplace caption upload)
- Does **not** authenticate live marketplace accounts for upload
- Does **not** call marketplace upload APIs
- Does **not** upload images or publish listings
- Stub Etsy connection foundation exists (`StubEtsyConnectionService`, `isConfigurationComplete = false`) — Keychain placeholders only; live OAuth not enabled

## Mode A — Local Export Mode (current, permanent)

- Prepares marketplace-sized images locally
- Saves/shares local JPEGs
- Seller manually uploads photos in marketplace websites/apps
- Works without marketplace login
- Works offline
- Remains available even after Direct Upload Mode exists
- Default / only shipping behavior until a future upload phase is explicitly approved

## Mode B — Direct Upload Mode (future only)

Potential later behavior:

1. Seller prepares images locally (same on-device pipeline)
2. Yofai renders final JPEGs locally
3. Seller opts into Direct Upload Mode for a verified marketplace
4. Official OAuth/account auth is checked
5. Upload job uses that marketplace’s **official** API only
6. Result is recorded as upload-history metadata (separate from local export history)

Requirements before any implementation:

- Marketplace-specific official API/OAuth feasibility verified
- Explicit phase approval
- No browser automation, guessed endpoints, or marketplace password storage
- Local Export Mode remains the fallback

## Hard bans (Direct Upload Mode)

Yofai will **not** implement upload via:

- Web scraping
- Hidden browser login
- Automated website form filling
- Marketplace password storage
- Unofficial/private APIs
- Reverse-engineered endpoints

Only official APIs/OAuth are considered.

No AI API is required for Direct Upload Mode.

## Marketplace feasibility matrix

| Marketplace | Official public developer API | Direct listing/photo upload API | OAuth / account required | App review / business approval likely | Recommended first Direct Upload target | Verification source | Next action |
|---|---|---|---|---|---|---|---|
| **Etsy** | Yes | Yes — `uploadListingImage` (Open API v3 listings tutorial) | Yes — OAuth + API key | Yes — app registration / scopes | **Maybe** (strongest verified path today) | [Etsy Listings Tutorial](https://developer.etsy.com/documentation/tutorials/listings) | Manually verify current app registration, scopes (`listings_w`), rate limits, and Keychain/backend token plan before any upload phase |
| **eBay** | Yes — Sell APIs | Yes / needs confirmation of current Media path — Inventory uses HTTPS `imageUrls`; Media API historically supports hosted image upload | Yes — eBay OAuth | Yes — developer app + marketplace policies | Maybe (after Media/Inventory path confirmed) | eBay Sell Inventory / Media docs (developer.ebay.com) — full Media overview fetch returned 403 in this environment | Manually open current eBay Media + Inventory docs; confirm create-from-file vs URL-only for Yofai’s on-device JPEGs |
| **Poshmark** | No public developer API found | No official upload API found | Unknown (no public API) | Unknown | No | No official developer portal located; third-party automation is out of scope | Keep Local Export Mode only; re-check only if Poshmark publishes an official API |
| **Facebook Marketplace** | Partner/platform APIs exist | Partner Item API uses **image URLs** in catalog batch (not binary upload for consumer sellers) | Yes — Meta app / partnership | Yes — Marketplace partnership / Commerce Manager | No for typical individual sellers | [Marketplace Partner Item API](https://developers.facebook.com/docs/marketplace/partnerships/itemAPI/) | Do not treat partner catalog APIs as consumer “upload my photos from Yofai”; keep Local Export Mode |
| **Mercari** | Mercari Shops (JP) GraphQL exists; **Mercari US consumer** public seller API not found | Mercari Shops: create with **image URLs**, no direct binary image upload API (official FAQ). US C2C: unknown / not found | Shops: yes. US C2C: unknown | Likely yes where APIs exist | No until US consumer path is verified | [Mercari Shops API FAQ](https://api.mercari-shops.com/docs/index.html) | Keep Local Export Mode for US sellers; do not use browser automation workarounds |

**Safest first Direct Upload candidate (if later approved):** Etsy — only after manual verification of registration, scopes, token storage, and listing-image flow.  
**Not first:** Poshmark, Facebook Marketplace (consumer), Mercari US — no suitable verified individual-seller binary upload path documented here.

Fields marked unknown or “needs confirmation” must be re-checked against live official docs before coding.

## Future architecture (not implemented)

Likely components when a marketplace is approved:

- `MarketplaceUploadTarget` — which official marketplace
- `MarketplaceAuthState` — connected / expired / error (OAuth)
- `MarketplaceUploadService` protocol — per-marketplace implementations
- `UploadJob` / `UploadStatus` / `UploadError`
- `UploadHistory` — separate from local `ProjectExportBatch` export history
- Per-marketplace services added only when verified (e.g. `EtsyListingImageUploadService`)

Stay on-device forever:

- Original photos, edits, crop/reposition, Photo Check, watermark, preview, final JPEG rendering, Local Export Mode

## Backend requirement summary

Direct Upload Mode **likely needs backend** for:

- User account (optional product choice, but common for multi-device)
- Secure OAuth token handling and refresh (avoid shipping client secrets)
- Marketplace API app configuration
- Entitlement/subscription if charged later
- Lightweight upload-job tracking / sync of upload metadata

Keep local / on-device:

- Photos, edits, rendering, Photo Check, Local Export Mode, local export history/notes

**This phase does not add** Firebase, Supabase, AWS, VPS, paid image storage, OpenAI, or analytics SDKs.

## AI

No AI API is required for Local Export Mode or Direct Upload Mode.

## Phase status

Phase 45 documents this roadmap only. No Direct Upload Mode code, OAuth secrets, backend vendors, or browser automation were added.
