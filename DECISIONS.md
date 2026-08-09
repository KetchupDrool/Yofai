# Decisions

## Locked
- Final app name: Yofai
- Bundle ID: com.shawnwright.yofai
- Platform: iOS first
- UI framework: SwiftUI
- Local storage: SwiftData
- Build tool: Xcode
- Coding assistant: Cursor

## Product Pivot (2026-08-09) — Locked
- Primary purpose: local-first marketplace product photo preparation for online sellers
- Core functionality is local-first/on-device
- Seller jobs: photograph → organize photo sets → quality check → edit → resize/crop → listing-ready local exports
- Marketplace targets (export only, not integrations): Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar
- Active export direction: multi-marketplace **local** export presets (future work when approved; do not implement yet)
  - Etsy-sized presets already exist where verified (see Phase 20)
  - Future local preset targets: eBay, Facebook Marketplace, Poshmark, Mercari, similar
- Abandoned from the active roadmap (inactive unless explicitly re-approved later):
  - Paid/live AI APIs
  - OAuth marketplace publishing
  - Direct Etsy publishing
  - Direct publishing to any marketplace
- Future-capability / approved-direction (not immediate tasks; may be added later where they support the product):
  - Backend services
  - User accounts
  - Cloud sync
  - Subscriptions
  - Ads
- Core photo preparation remains local-first/on-device even if future capabilities are added later
- Old primary goal (“general photo editor MVP”) is superseded; App Store upload remains paused

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

## Phase 24 — Etsy connection foundation (locked; live path abandoned from active roadmap)
- Settings Etsy Shop section: Not connected / Connecting / Connected / Connection expired / Error
- `EtsyConnecting` protocol; `MockEtsyConnectionService` for tests/previews; `StubEtsyConnectionService` for app (no network)
- Tokens + connection payload in Keychain only; Disconnect deletes all Etsy Keychain items
- Development placeholder redirect: `yofai://etsy-oauth-callback` via URL Types; `isConfigurationComplete = false`
- No Associated Domains; no client secret on device; no live Etsy HTTP in this foundation
- Completed local stub/history preserved
- **Abandoned from the active roadmap:** live OAuth, upload, and marketplace publishing (including direct Etsy publishing). Inactive unless explicitly re-approved later.

## Phase 25 — Local Listing Queue (locked)
- `ListingQueueEntry` in SwiftData: sort order + local status
- Statuses: Needs Details, Ready, Processing, Failed, Completed
- Readiness: ≥1 existing photo file, nonblank title, valid nonnegative price, quantity ≥ 1, ≤13 tags
- Prepare Queue validates locally only; Ready may enter Processing then return to Ready/Failed
- Completed only when tests/previews set it explicitly — never faked by Prepare Queue
- Projects toolbar → Listing Queue; Review Draft opens Project Detail; delete project cascades queue entry
- Abandoned from the active roadmap: network upload, live Etsy publish

## Phase 26 — Batch listing image export (locked)
- Project Detail: Listing Export settings + Export Listing Images
- Export all project photos in sort order to Application Support/ExportBatches as `01.jpg`, `02.jpg`, …
- Per-photo saved `PhotoEditState` when available; else original + project preset/background/watermark
- Fit mode remains contain + pad; source project files never modified
- Share Export Batch shares real JPEG file URLs; Delete Batch removes only that batch folder
- Abandoned from the active roadmap: Etsy upload of batches

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
- Abandoned from the active roadmap: paid/live AI suggestions, Etsy API, OAuth, upload; also do not invent marketplace limits/IDs

## Phase 31 — AI Listing Assistant Foundation (locked; paid/live AI abandoned from active roadmap)
- Listing Workspace → AI Listing Assistant; status “AI is not connected yet”; no photos/listing data leave the device
- `AIPreparationRecord` in SwiftData: selected photo stable IDs, suggestion types, included/excluded context fields, editable suggestions, status, safe error message
- Statuses: Draft, Ready for AI, Awaiting Review, Applied, Failed
- Provider protocol: `DisconnectedAIListingProvider` (production), `MockAIListingProvider` (tests/previews only)
- Never invents fake AI copy in production; manual placeholders allowed; mock suggestions only via mock provider
- Apply only seller-approved suggestions to title/description/tags/category/materials/alt text; photo order needs explicit confirmation and preserves per-photo alt text
- Never changes price, quantity, shipping, processing, returns, variations, personalization, SKU, condition, item type, who/when made, export settings, or queue state
- Never auto-applies; no History/export/package/queue/Etsy completed side effects
- Cascade-delete with project; duplicate draft does not copy AI preparations; Seller Defaults store no AI data
- Listing Information Review and Phase 25 readiness unchanged
- Completed disconnected/local AI foundation history preserved
- **Abandoned from the active roadmap:** paid/live AI API use (networking, API keys, OpenAI/Etsy AI clients). Inactive unless explicitly re-approved later.

## Phase 32 — Product Intake + Guided Photo Capture (locked)
- Entry from Project Detail and Listing Workspace → Product Intake / Capture Photos
- Reuses existing project-photo storage/order/edit/alt-text/export/delete paths — no second photo library
- Editable local photo plan with optional starter goals; not Etsy requirements
- Goals: add/rename/reorder/delete/complete; attach at most one project photo; clear attachment without deleting photo
- Photo delete clears matching goal attachment; reorder keeps attachment + alt text on the photo
- System camera capture via UIImagePickerController; permission denial messaging; rear camera; flash when supported; confirm/retake; optional goal attach; append-only via `LocalEditStore.saveProjectImage`
- Simulator/unavailable camera fails safely; production never fakes capture; tests use `InjectedTestCaptureSource` only
- Photo Check reports measurable local facts only; seller review checkboxes never affect Phase 25 readiness
- Duplicate draft copies goal names/order only; cascade-delete goals with project; Seller Defaults store no photo-plan/camera/review data
- Abandoned from the active roadmap: paid/live AI, Etsy API/OAuth/upload; do not claim marketplace compliance

## Phase 33 — Seller Export Preset Clarity (locked)
- Seller-facing display metadata on `ListingExportPreset` only; stored `rawValue` and pixel sizes unchanged
- Display: Marketplace → “Square 1600”; groups Listing vs Other canvas; picker labels include W×H
- Facebook post subtitle clarifies social post canvas, not Marketplace product
- Local export disclaimer on Edit, Project Detail export, Seller Defaults
- Home + Projects empty copy aligned to marketplace product photo-prep north star
- Fit mode remains contain + pad; no new marketplace sizes invented
- Out of scope: cover/crop fit, eBay/Poshmark/Mercari/FB Marketplace sized presets, OAuth/AI/upload, nav merge

## Future capability (approved direction — not next work)
May be added later where they support the product; core photo preparation remains local-first/on-device:
- Backend services
- User accounts
- Cloud sync
- Subscriptions
- Ads

## Abandoned from the active roadmap
Inactive unless explicitly re-approved later:
- Paid/live AI APIs
- OAuth marketplace publishing
- Direct Etsy publishing
- Direct publishing to any marketplace

## Still out of scope unless newly approved
- Social sharing beyond the system Share sheet (local export/share remains the path)
- Inventing marketplace category trees, IDs, scopes, or hard compliance limits

## Naming
- Keep user-facing name as Yofai.
- Keep root folder as Yofai.
- Keep Xcode project as Yofai.xcodeproj.
