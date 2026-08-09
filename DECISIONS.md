# Decisions

## Locked
- Final app name: Yofai
- Bundle ID: com.shawnwright.yofai
- Platform: iOS first
- UI framework: SwiftUI
- Local storage: SwiftData
- Build tool: Xcode
- Coding assistant: Cursor

## Phase 20 — Listing export (locked)
- Product direction: listing / photo-prep for sellers (local-only)
- Fit mode: contain + pad
- Backgrounds: white, black, soft gray only (no transparent)
- Export presets (pixels):
  - Etsy square: 2000 × 2000
  - Etsy listing: 3000 × 2400
  - Instagram square: 1080 × 1080
  - Facebook post: 1200 × 630
  - Marketplace: 1600 × 1600
- Defaults: Etsy square + white
- Deferred: transparent export, border/shadow frames

## Phase 21 — Watermark (locked)
- Simple text watermark on listing exports only
- State: watermarkEnabled (default false), watermarkText (default "", max 32)
- Draw after contain + pad; bottom-trailing; font scales with canvas
- Text color follows background (light on black, dark on white/soft gray)
- History stores optional didWatermark Bool? (Yes/No); nil = older rows
- Share architecture unchanged (ShareFileItem + temp JPEG + .sheet(item:))
- Deferred: logo watermark, opacity/position pickers, multi-line

## Phase 22 — Item Projects (locked)
- Local Item Projects: name, multiple photos, created/modified dates
- Files under Application Support/ItemProjects
- Projects tab; open existing Edit from a project photo
- Delete project confirms and removes project files only
- List rows use thumbnails only; full image loads on Edit navigate

## Phase 23 — Local listing drafts (locked)
- Per-project listing fields: title, description, price text, quantity, category, tags (≤13), materials, shipping profile, processing time
- SwiftData on `ItemProject`; edit/save in Project Detail Listing Details section
- Validation on save: title required, price valid nonnegative, quantity ≥ 1, max 13 tags, blank tags removed
- Completeness summary from persisted values

## Phase 24 — Etsy connection foundation (locked)
- Settings Etsy Shop section: Not connected / Connecting / Connected / Connection expired / Error
- `EtsyConnecting` protocol; `MockEtsyConnectionService` for tests/previews; `StubEtsyConnectionService` for app (no network)
- Tokens + connection payload in Keychain only; Disconnect deletes all Etsy Keychain items
- Development placeholder redirect: `yofai://etsy-oauth-callback` via URL Types; `isConfigurationComplete = false`
- No Associated Domains; no client secret on device; no live Etsy HTTP; no backend yet
- Deferred: live OAuth, publishing, uploads, scopes/endpoints until credentials + backend exist

## Phase 25 — Local Listing Queue (locked)
- `ListingQueueEntry` in SwiftData: sort order + local status
- Statuses: Needs Details, Ready, Processing, Failed, Completed
- Readiness: ≥1 existing photo file, nonblank title, valid nonnegative price, quantity ≥ 1, ≤13 tags
- Prepare Queue validates locally only; Ready may enter Processing then return to Ready/Failed
- Completed only when tests/previews set it explicitly — never faked by Prepare Queue
- Projects toolbar → Listing Queue; Review Draft opens Project Detail; delete project cascades queue entry
- Deferred: network upload, live Etsy publish

## Phase 26 — Batch listing image export (locked)
- Project Detail: Listing Export settings + Export Listing Images
- Export all project photos in sort order to Application Support/ExportBatches as `01.jpg`, `02.jpg`, …
- Per-photo saved `PhotoEditState` when available; else original + project preset/background/watermark
- Fit mode remains contain + pad; source project files never modified
- Share Export Batch shares real JPEG file URLs; Delete Batch removes only that batch folder
- Deferred: Etsy upload of batches

## Phase 27 — Listing Workspace + bulk queue actions (locked)
- `ListingWorkspaceView` entry from Project Detail and Listing Queue
- Shows cover, title, completeness, missing info, queue status, photo order, latest export batch
- Reuses ItemProject / ListingQueueEntry / ProjectExportBatch — no second draft model
- Actions: edit details/photos via existing Project Detail, export/share batch, add/remove queue, validate readiness
- `prepareReadyListings`: validate all, process Ready only, skip Needs Details, summary counts; never Completed/upload
- Readiness remains Phase 25 rules only

## Phase 28 — Seller Defaults + Duplicate Listing Draft (locked)
- Settings Seller Defaults: category, materials, shipping, processing time, export preset/background, watermark text
- Stored in UserDefaults via `SellerDefaultsStore`; never Etsy credentials; clear requires confirmation
- Apply only when creating a new Item Project with Use Seller Defaults; Start Blank applies nothing
- Existing projects never overwritten by defaults changes
- Duplicate Listing Draft copies listing details + export settings only; requires new item name; no photos/files/edits/batches/queue/History/Originals; starts outside queue

## Phase 29 — Bulk Photo Editing + Listing Package (locked)
- Bulk Edit Photos: copy selectable edit recipe from one project photo to targets; never overwrite source image files; no History rows
- Exclude any setting before apply; fit mode is locked contain + pad
- Per-project undo restores previous edit settings for the most recent bulk op only
- Listing Package: local folder with `listing-details.txt` + ordered JPEGs from newest successful export batch
- Requires export batch first; packages separate from photos/Originals/History/export batches; share/delete package files only

## Phase 30 — Complete Local Listing Information (locked)
- Listing Workspace → Listing Information grouped editors; reuses Phase 23 core draft fields (no duplicate title/price/etc. editors)
- New local SwiftData fields: item type, condition, who/when made, SKU, personalization, variations, category attributes, return policy, per-photo alt text
- Optional fields support explicit Not Applicable
- Listing Information Review: filled / missing / N/A / needs review — local only; never labels a draft Etsy-ready
- Phase 25 queue readiness rules unchanged
- Validation: enabled variation name/options/SKU; personalization character limit positive when enabled; blank attributes/options/alt text removed on sanitize
- Alt text stored on `ItemProjectPhoto` so reorder/delete keep matching text
- Duplicate Listing Draft copies all new listing-information fields; still no photos/files/edits/batches/packages/queue/History/Originals
- Seller Defaults may prefill only item type, condition, who made, when made, return policy (plus prior defaults) on new-project create; never overwrite existing projects
- Deferred: AI suggestions, Etsy API, OAuth, upload, guessed marketplace limits/IDs

## Not Approved Yet
- Backend
- User accounts
- Cloud sync
- AI API calls
- Subscriptions
- Ads
- Social sharing (beyond system Share sheet)
- Live Etsy OAuth / Etsy API / uploading (local features only)

## Naming
- Keep user-facing name as Yofai.
- Keep root folder as Yofai.
- Keep Xcode project as Yofai.xcodeproj.
